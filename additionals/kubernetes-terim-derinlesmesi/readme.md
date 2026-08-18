# 🔍 Kubernetes Terim Derinleşmesi — etcd, Raft, CNI/kube-proxy (devam edecek)

Edib Bey'in verdiği geri bildirim üzerine, Faz 28'deki Küme Mimarisi belgesinde yüzeysel kalan bazı konuları kendim araştırıp derinleştirdim. Bu belge, o araştırmaların kaydı — zamanla yeni bölümler (kubernetes.io ve microservices.io okumaları) eklenerek büyüyecek.

---

## etcd — Genel Çalışma Mantığı

etcd'yi Faz 28'de Kubernetes'e özel bir parça gibi görmüştüm, ama aslında Kubernetes'ten bağımsız, genel bir dağıtık sistem aracı. Bunu araştırırken şu noktalara vardım:

- **Bir "yönetim kurulu" gibi çalışıyor** — birden fazla kopya (tek sayı üye), hepsinde aynı bilgi, kimse tek başına karar veremiyor, çoğunluk onayı şart. Bu, iki farklı düğümün aynı anda "lider benim" deyip birbirini yalanlaması (**split-brain**) durumunu önlüyor.
- **Değerin asıl gücü, geçmişi saklaması değil** — her değişikliğe bir sıra numarası (**revision**) veriliyor, tıpkı GitHub commit sırası gibi. Biri eski bilgiyle üzerine yazmaya çalışırsa işlem reddediliyor (bir ATM'den aynı anda iki para çekme isteğinin çakışmasını önlemekle aynı mantık).
- **Watch mekanizması** — ilgilenen taraflar sürekli "değişti mi?" diye sormak (polling) yerine, değişiklik olduğunda otomatik haber alıyor (bir YouTube kanalına abone olmak gibi). Bağlantı koparsa, kaldığı revision'dan itibaren "benden sonra ne değişti" diye sorup (`git pull` gibi) kaldığı yerden devam edebiliyor.
- **Alternatifleri var** — Zookeeper (Hadoop ekosisteminde, daha eski), Consul (servis keşfi ve sağlık kontrolüne daha fazla odaklı). etcd'nin öne çıktığı yer, Kubernetes'in kontrol düzlemine gömülü olması ve saf key-value performansının yüksek olması.

---

## Raft — etcd'nin Kullandığı Konsensüs Protokolü

Raft, etcd'nin (yönetim kurulu benzetmemizdeki) bir nevi yardımcı mekanizması — eğer yönetim kurulu masasındaki başkan artık aktif olamazsa, yeni başkan seçilmesini, aktif olamama durumunun doğrulanmasını ve karar verilmesi süreçlerini tetikliyor.

**Nasıl işliyor:** Başkan (lider), düzenli aralıklarla (**heartbeat**, ~100ms'de bir) diğer üyelere "hâlâ buradayım" sinyali gönderiyor. Her üyenin kendi içinde bir sayaç var (**election timeout**, 150-300ms arası) — bu süre içinde heartbeat gelmezse, üye kendiliğinden "başkan yok, ben adayım" diyor ve kendine oy veriyor.

Sistem sayesinde karışıklık çıkmıyor çünkü herkesin bekleme süresi farklı (**rastgele**) oluyor, ve bu da oy verme durumlarını etkiliyor — genelde biri diğerlerinden önce aday oluyor, henüz kendi süresi dolmamış diğer üyeler ona oy veriyor, çoğunluk hızlıca oluşuyor. Olası bir 2. seçime gidilme durumunda (iki üye çok yakın sürelerde aday olup oylar bölünürse, buna **split vote** deniyor) ise yine rastgelelik sayesinde, genelde 3. bir seçime gerek kalmadan sorun çözülüyor.

**Term (dönem) numarası** da ayrı bir güvenlik katmanı sağlıyor — her seçim turunun bir numarası var, düşük numaralı bir dönem asla yüksek numaralı bir döneme üstün gelemiyor. Böylece, ağ sorunu yüzünden uzun süre kopup eski bilgiyle geri dönen bir üye ("ben hâlâ dönem 3'ün lideriyim" diye), güncel dönemi (mesela 5) öğrenip kendini otomatik güncelliyor ve karışıklık çıkarmadan sıradan bir takipçi olarak kurula geri katılıyor.

---

## CNI / kube-proxy — Pod'lar Arası ve Service Üzerinden İletişim

Edib Bey'in "burası daha kritik" dediği network konusunu, bir apartman/kargo senaryosu üzerinden işledim.

### Asıl Problem — Farklı Node'lardaki Pod'ların Birbirini Bulması

Farklı node'lardaki pod'ların birbiriyle iletişim kurmasını sağlamak için apartman/daire mantığı kullanılabilir — fiziksel ağ (postane) sadece apartmanların (node'ların) adresini biliyor, dairelerin (pod'ların) değil. Bunu çözmek için iki yöntem var:

1. **Postanenin gelen kargoları, aynı apartmana gidenleri komple bir zarfa koyup o apartmana gidip güvenliğe teslim etmesi, güvenliğin de zarfı açıp içindeki zarfları dairelere teslim etmesi** — bu yöntem, postanenin apartmana müdahale edemeyeceği durumlarda mantıklı (VDS gibi, kiralık bir sunucuda altındaki fiziksel ağa erişimin olmadığı durumlar). Bu, **overlay/VXLAN** yöntemine karşılık geliyor.
2. **Postane benim olduğu için gelen zarfları direkt olarak apartmanların dairelerine göndermek, çünkü postaneye öğretebilirim** — kendi fiziksel altyapına tam erişimin olduğu durumlarda tercih edilebilir. Bu, **BGP** yöntemine karşılık geliyor.

Kendi VPS'imde (kiralık sunucu, VXLAN kullanılıyor) gerçek kanıt aradım — `vxlan.calico` adında bir network arayüzü bulup (`ip link show`), Calico'nun `VXLANMODE: Always` ayarıyla çalıştığını (`calicoctl get ippool`) doğruladım.

### Pod'lar Arası İletişimde Değişen IP Sorunu — Service

Pod'lar birbiriyle konuşuyor, ama pod'ların IP'leri değişebilir, bu da sıkıntı çıkarır. Kargo örneğine devam edersek: bir apartmanda sürekli değişen kiracılar var (pod'lar gelip gidiyor, her birinin dairesi/IP'si farklı), ama apartmanın girişinde sabit bir "kargo kabul numarası" var — kargocu hep aynı numarayı arıyor, numara hangi daireye yönlendirmesi gerektiğini biliyor, kim otursa otursun. Gönderen kişi hiçbir zaman "şu anki kiracının hangi dairede olduğunu" bilmek zorunda değil, sadece sabit kargo kabul numarasını biliyor. Bu sabit numara, Kubernetes'teki **Service** kaynağına karşılık geliyor — pod'lar değişen daire/kiracı, Service ise sabit kargo kabul numarası.

### kube-proxy — Dağıtık Yönlendirme

Service'in IP'sine gelen trafiği gerçek pod'a çeviren iş, merkezi bir yerde değil, **her node'un kendi üzerinde** yapılıyor (DaemonSet). Bunun iki faydası var:

- **Dayanıklılık:** Çökme durumunda her sistem gitmez, sadece o node gider — node'un kendi trafiğini çevirmesi bir nevi bölge yöneticisi gibi olmasını sağlar, bu da yönetimde "bu pod bu node'da, o zaman bu node'dan düzenleyebilirim" gibi kolay bir yönetim sağlıyor.
- **Hız:** Bir devlet dairesindeki gişe sırası gibi — farklı işler olsa da herkesi tek gişeden almaya kalkarsak sıra yavaş ilerler, ama herkesi kendi kategorisinde farklı gişelerde alırsak sıra da azalır, hız da artar. Merkezi bir yöntemde 2 node'a aynı anda trafik gelse önce biri işlenip sonra diğeri işlenir, trafik arttıkça gecikme süresi artar — node'lar kendi trafiğini yönetince paralel, hızlı işlenebiliyor.

**iptables vs IPVS:** kube-proxy'nin Service→pod çevirisini yapma yöntemi ikiye ayrılıyor. `iptables`, sırayla (yukarıdan aşağıya) kural taraması yapıyor — Service sayısı azken mantıklı, ama sayı arttıkça (10.000 gibi) taranacak liste uzadığı için gecikme artar. `IPVS` ise alfabetik/indexli bir arama gibi çalışıp, Service sayısı ne kadar artarsa artsın arama süresini neredeyse sabit tutuyor.

---

ℹ️ _Bu bölümler tamamen araştırma ve karşılıklı soru-cevap yoluyla oluşturuldu — teknik terim kullanılmadan önce kavramsal olarak (yönetim kurulu, apartman/kargo, gişe sırası benzetmeleriyle) anlaşılıp sonra gerçek terimlerle (heartbeat, election timeout, term, VXLAN, BGP, Service, kube-proxy, iptables/IPVS) eşleştirildi._
