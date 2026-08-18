# ☸️ Kubernetes Temel Kavramlar — GitOps, Neden Konteynerlar, Docker, Küme Mimarisi

27. fazda Docker'ın alternatiflerini (Podman, containerd, CRI-O, Buildah) araştırdım. Bu fazda Kubernetes'e geçtim — k8s-tr.github.io roadmap'ini takip ederek Temel Kavramlar bölümünü (GitOps, Neden Konteynerlar, Docker, Küme Mimarisi) baştan sona işledim.

**Baştan akılda tutulması gereken bir çerçeve:** Kubernetes, sunucular üzerinde çalışan all-in-one bir datacenter gibi düşünülebilir — network, storage, CPU, RAM hepsi mantıksal olarak yönetiliyor.

---

## 1. GitOps

Altyapı ve uygulama dağıtımlarını, bir Git deposundaki belgeler/config dosyaları üzerinden yönetip otomatikleştirme yaklaşımı olduğunu öğrendim.

Geleneksel yöntemde cluster'a direkt komut çalıştırılıyor (`kubectl apply` gibi) — bu değişiklik sadece terminal geçmişinde kalıyor, kimin ne zaman ne yaptığı izlenemiyor. GitOps'ta mantık tersine dönüyor: cluster'a doğrudan dokunulmuyor, bunun yerine "olması gereken hal" (desired state) bir Git repo'suna YAML olarak yazılıyor. Bir araç (ArgoCD gibi) bu repo'yu sürekli izleyip, repo ile cluster'ın gerçek hali arasındaki farkı otomatik kapatıyor.

Bunu kendi GitHub repomda yaptığım "her şeyi belgeleyip push et" alışkanlığının, gerçek çalışan altyapıya uygulanmış hali gibi anladım — Git geçmişi değişiklik kaydı oluyor, `git revert` ile geri alma kolaylaşıyor, kimse cluster'a doğrudan erişim almadan sadece Git'e push ederek çalışabiliyor.

Bir inşaat ustasına sözlü talimat vermek yerine planı (blueprint'i) güncellemek gibi düşünülebilir — usta düzenli olarak plana bakıp binayı ona uydurmaya devam ediyor.

---

## 2. Neden Konteynerlar?

### Konteyner Tarihi

Konteyner fikrinin **1979'a (chroot)** kadar gittiğini öğrendim — bu kadar eski olmasını beklemiyordum. Herkes Docker'ı (2013) konteynerin başlangıcı sanıyor ama fikir ondan 34 yıl önceye dayanıyor:

```
chroot (Unix)     → 1979
FreeBSD Jails     → 2000
LXC (Linux)       → 2008
Docker            → 2013
Kubernetes        → 2014
Openshift         → 2011, 2015
```

### Neden Konteynerlere İhtiyaç Duyarız

Sekiz maddeyi işledim — çevik uygulama dağıtımı, CI/CD, değişmezlik (immutability, "benim makinemde çalışıyordu" sorununu ortadan kaldırıyor), gözlemlenebilirlik, uygulama merkezli yönetim, mikroservisler, kaynak yalıtımı, kaynak kullanım verimliliği.

### Neden Kubernetes Kullanırız

Yedi ana başlığı gördüm: servis keşfi ve yük dengeleme, depolama yönetimi, otomatik dağıtım/geri alma (GitOps'un temeli), otomatik yerleştirme (scheduling), kendi kendine iyileştirme (self-healing), gizli bilgi yönetimi, genişletilebilirlik.

**Self-healing** kısmı özellikle dikkatimi çekti — Kubernetes'in başarısız container'ları yeniden başlattığını, sağlık kontrolüne yanıt vermeyenleri öldürdüğünü, hazır olana kadar trafiğe hiç açmadığını öğrendim. Bunu, Faz 26'da (IaC Scanning) test ettiğimiz HEALTHCHECK'in `healthy`/`unhealthy` durumuyla bağlantılandırdım — health check ile container'ın durumu tespit edilir ve durumuna göre müdahale yapılabilir; biz sadece `docker ps`'te durumu görmüştük, Kubernetes bu bilgiye göre otomatik aksiyon alıyor.

---

## 3. Docker (k8s-tr Bakış Açısı)

Bu sayfada büyük kısmını zaten bildiğimiz komutlar vardı (`docker run`, `docker ps`, `docker build`, `docker tag`, `docker push`). Yeni öğrendiğim tek teknik **`envsubst`** oldu:

```dockerfile
FROM nginx
ENV APP_LOCATION google
ENV NGINX_PORT 8080
COPY config/orig.conf /etc/nginx/conf.d/orig.conf
RUN envsubst < /etc/nginx/conf.d/orig.conf > /etc/nginx/conf.d/default.conf
RUN rm /etc/nginx/conf.d/orig.conf
```

Config dosyasında `${NGINX_PORT}` gibi değişkenler kullanılıyor, `envsubst` bu yer tutucuları `ENV` ile tanımlanan gerçek değerlerle dolduruyor. Bunu kod yazarken kullanılan değişken tanımlamaya benzettim — sonra Dockerfile'da değişkenlerin yerine gelecek gerçek veriler (google, 8080 gibi) yazılıyor. Aynı Dockerfile'ı farklı `ENV` değerleriyle build edip, aynı image yapısını farklı ortamlar (dev/test/prod) için kullanabiliyorsun — bunun, Kubernetes'teki ConfigMap'lerin (roadmap'te Temel Kaynaklar'da göreceğim) basitleştirilmiş bir öncülü olduğunu düşünüyorum.

---

## 4. Küme Mimarisi

Bu bölümü bir **otel** üzerinden kurdum — üç düzlem ayrımından başlayıp her bileşeni aynı kurguya oturttum:

- **Veri düzlemi** = otele gelen müşteriler ve onlara verilen gerçek hizmet
- **Kontrol düzlemi** = resepsiyon ve otel yönetimi
- **Yönetim düzlemi** = muhasebe/ödemeler — kontrol düzleminin bir alt parçası

### Kontrol Düzlemi Bileşenleri

**kube-apiserver = Resepsiyon.** Otele gelen herkes önce resepsiyona uğruyor, kayıt/rezervasyon kontrol ediliyor. Hiç kimse resepsiyonu atlayıp direkt bir odaya dalamıyor. Cluster'a gelen tüm REST isteklerinin kabul edilip doğrulandığı, etcd'ye tek bağlantı noktası olan bileşen. Static pod olarak kurulur: `/etc/kubernetes/manifests/kube-apiserver.yaml`.

**etcd = Otelin Müşteri Kayıt Defteri — Ama Birden Fazla Yedekli Nüshası Var.** Tek bir defter değil, birbirinin **aynısı, tek sayıda** (3, 5 gibi) kopyası bulunuyor. Şu an hangi odada kim kaldığı hepsi bu defterlerde, hepsi birbiriyle senkronize. Bir misafir çıkıp yenisi girdiğinde eski kaydın üzeri çizilmiyor, deftere yeni bir satır ekleniyor. Ama **bu, kayıtların sonsuza kadar tutulduğu anlamına gelmiyor** — eski sürümler kısa süreliğine geçmiş olarak kalıyor, düzenli aralıklarla **compact** işlemiyle temizleniyor, **defrag** ile de disk üzerindeki boşluk toparlanıyor.

Defter tek sayıda kopya halinde tutuluyor çünkü çift sayıların zaafiyeti olan 2'ye bölünme ve eşitlik (2-2 gibi berabere kalma) durumu tek sayılarda ortadan kalkıyor; her zaman net bir çoğunluk çıkıyor (Raft algoritmasıyla lider seçimi). Bu, aslında bir **yönetim kurulu** gibi çalışıyor — kurul üyelerinin hepsinde aynı bilgi var, kimse tek başına "ben kararı verdim" diyemiyor, çoğunluk onayı şart. Bu sayede iki farklı masanın aynı anda "lider benim" deyip birbirini yalanlaması (**split-brain** denen tehlikeli durum) engelleniyor.

**Defterin asıl değeri sadece "geçmişi saklaması" değil.** Her kayda bir **sıra numarası** (revision) veriliyor — tıpkı GitHub'daki commit sırası gibi. Biri bir odayı güncellemeye çalışırken, elindeki bilgi güncel değilse (arada biri değiştirmişse), işlem **reddediliyor** — böylece iki kişinin aynı anda çakışan işlem yapması (bir ATM'den aynı anda iki para çekme isteği gibi) engelleniyor. Ayrıca defter, kayıtlar güncellendiğinde **ilgilenen herkese otomatik haber veriyor** (bir YouTube kanalına abone olup bildirim almak gibi) — kimse sürekli "değişti mi, değişti mi?" diye sormak zorunda kalmıyor. Bağlantı koparsa, kaldığı revision numarasından itibaren "benden sonra ne değişti" diye sorup (bir `git pull` gibi) kaldığı yerden devam edebiliyor.

Defterdeki kayıtlar alfabetik/sıralı bir düzende (sözlük gibi) tutuluyor, düz bir sayfa düzeninde (ikili anahtar düzlemi) saklanıyor. Bu defter hizmeti, otelin diğer personelinden (static pod) farklı olarak **ayrı, bağımsız bir dış sistem** gibi çalışıyor (bağımsız Docker container). Kendi ayarlarına dışarıdan özel bir pencereden (`/config`, HTTP üzerinden) bakılabiliyor. Kaynak ihtiyacı olarak çok fazla CPU gerektirmiyor ama canlı sistemlerde 8GB bellek ve ortalama bir disk yeterli oluyor.

**Kritik bir uyarı da öğrendim:** Bu kayıt defteri sistemi kararsız hale gelirse (yetersiz kaynak, ağ sorunu gibi nedenlerle), masalar arasında **hiçbir zaman net bir çoğunluk/lider seçilemiyor**. Böyle bir durumda otel, mevcut durumunda **hiçbir değişiklik yapamıyor** — yeni bir misafir kabul edilemiyor, yeni bir oda bile açılamıyor. Ve burada gerçek dünyadan bir fark var: fiziksel bir kayıt defteri yok olsa bile insanlar bir şeyleri hafızalarından hatırlayabilir — ama bu defter (etcd) çökerse, sistemde **hiçbir şey** o durumu hatırlamıyor, çünkü tüm otelin "hafızası" tamamen bu deftere bağlı. Bu yüzden etcd'nin özenle, izole/kararlı bir ortamda çalıştırılması öneriliyor.

**kube-controller-manager = "Her Şey Yolunda mı" Kontrolcüsü.** İstenen durum ile gerçek durum arasındaki farkı sürekli kontrol edip düzeltmeye çalışıyor — GitOps'ta konuştuğumuz termostat mantığının aynısı.

**kube-scheduler = Oda Yerleştirme Görevlisi.** Resepsiyon misafiri kabul ettikten sonra, hangi fiziksel odaya (node'a) yerleştirileceğine karar veriyor — kaynak ihtiyacı, affinity/antiaffinity, taints/tolerations, data locality gibi kriterlere bakarak. **Pod'un içindeki uygulamanın hangi dilde yazıldığı önemli değil** — sadece çalışması için gerekli kaynaklar var mı diye bakıyor.

### Düğüm (Node) Bileşenleri

**kubelet = Kat Sorumlusu.** Her katta bir kat sorumlusu var. İlk işi merkez ofise "ben buradayım" diye bildirmek (node'u API Server'a kaydettirmek). Görevleri:

1. Resepsiyondan özel erişim kodları alıyor (pod secret'larını indirme)
2. Odaya ekstra depolama bağlıyor (volume mount)
3. Oda servisi ekibine talimat veriyor (container çalıştırma)
4. Merkeze düzenli durum raporu veriyor (node/pod durumu raporlama)
5. Kapı/ışık kontrolü yapıyor (liveness probe)

**coredns = Otel İç Telefon Rehberi.** "302 numaralı oda" dediğinde otomatik doğru yere bağlanıyor — bilgisayarlardaki hosts dosyası gibi, cluster içi DNS çözümlemesini sağlıyor. `kube-system` namespace'inde deployment olarak çalışıyor.

**kube-proxy = Dahili Santral Yönlendirmesi.** Service/Endpoint'lerin erişilebilirliğini, node network kurallarını, Service/Pod'lara virtual IP atamasını sağlıyor. DaemonSet olarak (her node'da bir kopya) çalışıyor.

**container-runtime = Oda Servisi/Bakım Ekibi.** Kat sorumlusunun talimatını fiilen yerine getiren katman — sistem servisi olarak kurulur.

**CNI (Calico) = Otelin Koridor/Geçiş Sistemi.** Cluster'ın network altyapısını, pod'lar arası bağlantıyı sağlıyor. `calico-kube-controllers` deployment, `calico-node` daemonset olarak kuruluyor. Alternatifleri: Cilium, Weave.

---

## 📊 Özet

| Konu                | Ne Öğrendim                                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------------------------------ |
| GitOps              | Cluster'a elle dokunmak yerine Git'e yazılan hedefi bir aracın otomatik uygulaması                           |
| Konteyner tarihi    | 1979'a (chroot) kadar gidiyor, Docker'dan 34 yıl önce                                                        |
| envsubst            | Config'teki değişkenleri Dockerfile'daki ENV değerleriyle dolduran teknik                                    |
| Küme mimarisi       | Otel benzetmesiyle — resepsiyon (apiserver), kayıt defteri (etcd), kat sorumlusu (kubelet), vb.              |
| etcd tek sayı üye   | Çift sayıda oylama berabere kalabilir, tek sayıda her zaman net çoğunluk çıkar — split-brain önleniyor       |
| etcd revision/watch | Her değişiklik numaralanıyor (çakışma önleme), değişince ilgilenene otomatik haber veriliyor (polling değil) |
| self-healing        | Health check durumuna göre otomatik müdahale — HEALTHCHECK'in cluster seviyesindeki hali                     |

---

ℹ️ _Bu faz tamamen kavramsal işlendi — k8s-tr.github.io roadmap'i takip edilerek gerçek bir cluster kurulmadan önce temel terminoloji ve mimari pekiştirildi. Uygulamalı kurulum sonraki fazda._
