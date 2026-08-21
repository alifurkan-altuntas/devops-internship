# ☸️ Kubernetes Temel Kaynaklar — Pod, ReplicaSet, Deployment, Service, ConfigMaps, Secrets, Kanarya Deployment

29. fazda beş kurulum yöntemini karşılaştırmıştım. Bu fazda roadmap'in Temel Kaynaklar bölümünü işledim — her konuyu, önce gerçek hayattan bir benzetmeyle, hemen ardından teknik açıklamayla, ve mümkün olduğunca gerçek testlerle kanıtlayarak.

---

## 1. Pod, ReplicaSet, Deployment

Tek başına bir Pod silindiğinde geri gelmiyor — kendi kendini iyileştirme özelliği yok. Bu özellik **ReplicaSet**'te ortaya çıkıyor: ReplicaSet, "kaç pod var" diye sürekli sayıyor (etiket bazlı `selector` ile), eksikse **yeni bir pod** yaratıyor — silinen pod'un aynısı değil, tamamen yeni bir isim/IP ile. Bunu, kube-controller-manager'ın (Faz 28'deki "her şey yolunda mı kontrolcüsü") içindeki bir döngü olarak öğrendim.

ReplicaSet'in `template` alanı değişince (image dahil olmak üzere **herhangi bir şey**, ortam değişkeni bile), Deployment bunu "yeni versiyon" sayıp otomatik bir **rolling update** tetikliyor. Bunu gerçek bir testle kanıtladım: `kubectl set image` ile v1'den v2'ye geçtim, `-w` ile canlı izledim — önce yeni pod `Running` oldu, **ancak ondan sonra** eski pod `Terminating`'e geçti, hiç sıfır pod anı olmadı. Geçici bir `Error` durumu gördüm, bunun container kapanma anının normal görüntüsü olduğunu (`describe`/`get pods` ile) doğruladım.

---

## 2. Service

### Temel Mekanizma — Selector, Endpoints, DNS

Bir apartmanda sürekli değişen kiracılar var (pod'lar gelip gidiyor, her birinin IP'si farklı), ama apartmanın girişinde sabit bir "kargo kabul numarası" var — kargocu hep aynı numarayı arıyor, kim otursa otursun.

**Teknik olarak:** Bu sabit numara **Service**. Pod ayağa kalkar, bir IP alır, üzerinde bir etiketi vardır. Service'in de aynı etiketi arayan bir `selector`'ı vardır. Asıl işi yapan **DNS** (coreDNS) — Service oluşunca otomatik bir isim kaydı oluşuyor, o an etikete uyan pod'ların IP'lerine çözümleniyor. Bunu **Label Yetenekleri** testiyle kanıtladım: hiçbir pod'un başta sahip olmadığı bir etiketi (`inservice: mypods`) arayan bir Service kurdum, `endpoints` boş çıktı; pod'lara elle etiketi ekleyip çıkarınca `endpoints` **anında** (Service'i hiç yeniden başlatmadan) güncellendi — hatta iki tamamen farklı Deployment'tan gelen pod'ları aynı Service'te birleştirebildim.

### NodePort ve LoadBalancer

LoadBalancer aslında NodePort'un üstüne kurulu — kendi VDS'imde (bulut sağlayıcı entegrasyonu olmadan) `EXTERNAL-IP`'nin sonsuza kadar `<pending>` kaldığını, ama otomatik atanan NodePort'un gerçek IP üzerinden çalıştığını kanıtladım.

Bir bilmece de çözdüm: `curl localhost:31720` başarısız oldu ama `curl 91.151.88.38:31720` çalıştı. Sebebi, `127.0.0.1`'in **göreceli bir anlamı** olması — isteği gönderen için "sunucunun kendisi", ama pod'un bakış açısından "pod'un kendisi" demek. NAT sırasında bu göreceli anlam düzeltilmezse (masquerade eksikse), pod'un cevabı yanlış yere gidiyor — buna **hairpin NAT** deniyor. `ss -tlnp | grep 31720`'nin boş dönmesiyle, NodePort'un gerçek bir "dinleme" değil, iptables/DNAT tabanlı bir yönlendirme olduğunu da kanıtladım.

### ExternalName

Diğer Service türlerinin (`selector`/`endpoints`) hiçbirini içermeyen özel bir tür — sadece bir DNS **CNAME** kaydı oluşturuyor, hiçbir trafiği kendisi taşımıyor. `google.com`'a yönlendiren bir ExternalName Service kurup, bir test pod'u içinden DNS sorgusu attım — gerçek Google IP'leri döndü, `kube-proxy`/`iptables` bu sürece hiç dahil olmadı. `CLUSTER-IP: <none>` ve `endpoints` objesinin hiç oluşmaması, bunun tamamen "içerde değil dışarda" çalıştığının kanıtı.

---

## 3. ConfigMaps

Merkezi, herkese açık, birden fazla Deployment'ın referans verebildiği, güncellenince yürürlüğe giren bir kaynak — buna **resmi gazete** gibi düşünülebilir: tek bir yayın, birden fazla "kurumu" (Deployment'ı) etkileyebiliyor, gizli değil.

**Kritik bir asimetri buldum ve kanıtladım:**

- **Ortam değişkeni olarak** kullanılan ConfigMap → statik, sadece container başlarken bir kere okunuyor, değişse bile pod yeniden başlamadan güncellenmiyor
- **Dosya (volume) olarak** bağlanan ConfigMap → dinamik, kubelet arka planda periyodik olarak (~60 saniyede bir) kontrol edip **canlı günceller**, pod'un yeniden başlamasına hiç gerek yok

Bunu gerçek testle kanıtladım: bir ConfigMap'i volume olarak bağlayan pod açtım, ConfigMap'i değiştirdim, pod'u hiç yeniden başlatmadan dosyanın içeriğinin değiştiğini gördüm (`RESTARTS: 0`, `AGE` kesintisiz arttı).

Ayrıca `--from-env-file` ile bir `.properties` dosyasından **toplu** ConfigMap oluşturmayı, ve bir shell script'i ConfigMap'e koyup **çalıştırılabilir dosya** olarak container'a bağlamayı da test ettim — ikisi de gerçek çıktıyla doğrulandı.

---

## 4. Secrets

### Base64 Şifreleme Değil

Sayfada bir çelişki fark ettim — bir yerde "otomatik şifreleniyor" diyordu, başka bir yerde "şifrelenmiyor, sadece base64 kodlanıyor" diyordu. Bunu gerçek testle çözdüm: `kubectl get secret -o yaml` çıktısındaki değeri `base64 --decode` ile **hiçbir anahtar/şifre girmeden** çözdüm, gerçek şifre çıktı.

Bunu bir dil benzetmesiyle özetledim: kapının anahtarına (kubectl/etcd erişimine) sahip olanlar, içeridekilerin dilini (base64'ü) zaten biliyor — çünkü bu **herkesin bildiği, evrensel bir standart** (RFC 4648), Kubernetes'e özel bir "gizli dil" değil.

**etcd'ye doğrudan bakarak da kanıtladım:** `etcdctl get /registry/secrets/...` ile Secret'ın etcd'deki ham halinin **düz metin** olduğunu gördüm — kubectl'e bile gerek kalmadan.

### Gerçek Şifreleme — EncryptionConfiguration

Bunu kurup, öncesi/sonrası karşılaştırmalı test ettim:

1. `EncryptionConfiguration` dosyası oluşturup rastgele bir AES anahtarı tanımladım
2. `kube-apiserver`'ın static pod manifest'ine `--encryption-provider-config` parametresini ve gerekli volume mount'u ekledim
3. **Eski Secret** (şifreleme öncesi yazılmış) etcd'de hâlâ düz metin kaldı — şifreleme **geriye dönük çalışmıyor**
4. **Yeni Secret** (şifreleme sonrası yazılmış) etcd'de `k8s:enc:aescbc:v1:key1:` ön ekiyle, tamamen anlamsız kriptografik veri olarak göründü — artık `base64 --decode` ile bile çözülemiyor

Bu, gerçek dünyada firmaların neden ek olarak `EncryptionConfiguration`, HashiCorp Vault, ya da External Secrets Operator kullandığını somut olarak gösterdi — varsayılan Secret koruması, ismin çağrıştırdığı kadar güçlü değil.

Volume-mount Secret'ların da ConfigMap'teki gibi **canlı güncellendiğini** ayrıca test edip kanıtladım.

---

## 5. Kanarya Deployment

Madencilerin gaz tespiti için kanarya kuşu kullanmasından geliyor — kanarya, tehlikeyi **küçük bir grup** üzerinden erken tespit ediyor, herkes zarar görmeden.

**Teknik karşılığı:** Aynı etikete sahip iki Deployment (biri çok kopyalı, eski/stabil versiyon; diğeri az kopyalı, yeni/test versiyon) aynı Service'in havuzunda **kalıcı olarak yan yana** duruyor. Rolling update'ten farkı — rolling update'te eski tamamen yeniyle değişiyor, kanaryada ikisi **birlikte** çalışmaya devam ediyor, trafik aralarında (kopya sayısı oranında) dağılıyor.

Gerçek testle kanıtladım: 3 kopya `v1` + 1 kopya `v3`, aynı Service'e bağlı. 10 isteğin 8'i `v1`'e ("Aloha" cevabı), 2'si `v3`'e ("Jambo" cevabı) gitti — yaklaşık 3:1 oranı, kopya sayısıyla örtüşüyor. Sorun varsa, `v3`'ün kopya sayısını sıfıra indirerek **anında** geri çekilebilir, geri kalan kullanıcılar hiç etkilenmeden.

---

## 📊 Özet

| Konu                      | Ne Öğrendim                                                                                    |
| ------------------------- | ---------------------------------------------------------------------------------------------- |
| ReplicaSet                | Silinen pod diriltilmiyor, yenisi yaratılıyor — kube-controller-manager'ın bir döngüsü         |
| Rolling update            | Önce yeni pod ayakta, sonra eski kapanıyor — hiç kesinti yok                                   |
| Service/DNS               | Asıl işi coreDNS yapıyor, selector→endpoints canlı güncelleniyor                               |
| NodePort/LoadBalancer     | LoadBalancer, NodePort'un üstünde; hairpin NAT, 127.0.0.1'in göreceli anlamından kaynaklanıyor |
| ExternalName              | selector/endpoints yok, sadece DNS CNAME — trafiği hiç taşımıyor                               |
| ConfigMap env vs volume   | Ortam değişkeni statik (pod restart gerekir), volume dinamik (canlı güncellenir)               |
| Secret base64             | Şifreleme değil, evrensel bir kodlama — herkes çözebilir                                       |
| Secret encryption at rest | Varsayılan kapalı, EncryptionConfiguration ile açılıyor, geriye dönük çalışmıyor               |
| Kanarya Deployment        | Aynı etiketli iki Deployment kalıcı yan yana, trafik kopya oranında dağılıyor                  |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde (Kubespray cluster'ında) yapılmıştır — her konu önce bir benzetmeyle kavramsal olarak anlaşılıp, sonra teknik terimlerle ve gerçek `kubectl`/`etcdctl` testleriyle kanıtlanmıştır._
