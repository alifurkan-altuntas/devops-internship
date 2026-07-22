# 🔄 Docker Alternatifleri — Podman, containerd, CRI-O, Buildah

26. fazda IaC scanning ile Docker'ın kendi kod tabanını taramayı öğrendim. Bu fazda bir adım geri çekilip Docker'ın kendisine bakan alternatif container motorlarını araştırdım — neden var oldukları, Docker'dan farkları, ve Docker'ın hâlâ en çok kullanılan olmasının sebebi.

---

## 1. Podman

Red Hat'in geliştirdiği, Docker komutlarını neredeyse birebir taklit eden bir container motoru (`podman run`, `podman build`, `podman ps`). Docker'ın mimarisinde sürekli arka planda çalışan bir daemon (`dockerd`) var — her komut bu daemon'a gidiyor, daemon root yetkisiyle çalışıyor. Podman bu daemon'ı tamamen kaldırdı: her container kendi başına, normal bir process gibi çalışıyor, root gerekmiyor (**rootless**, **daemonless**).

Faz 24-25'te non-root container, seccomp, AppArmor gibi şeylerle Docker'ı sonradan güvenli hale getirmeye çalıştık — Podman bu sorunun bir kısmını mimari olarak zaten çözmüş geliyor.

**Kanıtladık:** Aynı container'ı ikisinde de çalıştırıp host'ta `ps aux` ile bakınca, Docker'da process `root`, Podman'da normal kullanıcı (`altun`) olarak görünüyor. Daemonless iddiası da doğrulandı — `podman.service` sadece bir istek geldiğinde kısa süre çalışıp duruyor (socket-activated), Docker'ınki ise sürekli aktif (`active (running)`, 3 haftadır çalışıyor).

**Artı:** Docker'a çok yakın komut seti, rootless, daemonless, systemd entegrasyonu, RHEL'de resmi destek.
**Eksi:** Docker Desktop kadar olgun bir GUI yok, Docker Swarm gibi bazı özellikler eksik, ekosistem daha küçük. Build hızında pratikte ciddi bir fark bulunmadı (~%8, ölçüm gürültüsü sınırında).

---

## 2. containerd

Aslında Docker'ın içinde zaten var olan, image çekme/çalıştırma gibi düşük seviye işleri yapan bileşen — Docker bunun üzerine kullanıcı dostu bir katman (CLI, network, volume yönetimi) inşa etmiş. containerd tek başına da kullanılabiliyor.

Kubernetes artık Docker'ı değil, doğrudan containerd'i kullanıyor (Kubernetes 1.24'te `dockershim` kaldırıldı) — Kubernetes cluster'larının %95'i containerd çalıştırıyor.

**Artı:** Çok hafif, hızlı, Kubernetes'in resmi/varsayılan runtime'ı.
**Eksi:** Tek başına kullanıcı dostu değil, günlük development için pratik değil.

---

## 3. CRI-O

containerd'den de minimal, sadece Kubernetes için tasarlanmış. Tek amacı Kubernetes'in "container çalıştır" komutlarını (CRI) yerine getirmek.

**Artı:** En minimal, en az saldırı yüzeyi, Red Hat OpenShift'te varsayılan.
**Eksi:** Kubernetes dışında neredeyse hiç işe yaramıyor.

---

## 4. Buildah

Podman'ın kardeşi — ama sadece build yapıyor, container çalıştırmıyor. Faz 25'te öğrendiğimiz Kaniko/Jib ile aynı mantık: build ve run birbirinden ayrılmış. Dockerfile olmadan da doğrudan shell komutlarıyla image inşa edebiliyor.

---

## 5. Rancher Desktop / Podman Desktop

Birer runtime değil, masaüstü GUI araçları — lisans ücretli hale gelen Docker Desktop'ın yerine geçiyorlar. Rancher Desktop içinde containerd veya Docker seçilebiliyor, tek tıkla yerel Kubernetes (K3s) kuruyor. İkisi de ücretsiz.

---

## 📊 Karşılaştırma

|                     | Docker                       | Podman                                 | containerd                              |
| ------------------- | ---------------------------- | -------------------------------------- | --------------------------------------- |
| Mimari              | Daemon (root)                | Daemonless, rootless                   | Minimal runtime                         |
| Kubernetes'te       | Kaldırıldı (dockershim)      | Destekleniyor ama asıl güç orada değil | Varsayılan runtime, cluster'ların %95'i |
| En güçlü olduğu yer | Local development, ekosistem | Güvenlik odaklı ortamlar, RHEL         | Production Kubernetes                   |

---

## 🤔 Neden Docker Hâlâ En Çok Kullanılan

Hiçbir alternatif Docker'ı "yerinden etmiyor" — her biri belirli bir nişte daha iyi:

1. **Ekosistem ve alışkanlık** — Docker Hub, Docker Compose, on yıllık dokümantasyon, hepsi Docker etrafında.
2. **Developer experience** — Docker Desktop hâlâ en cilalı deneyimi sunuyor.
3. **Günlük işte fark yaratmıyor** — Podman'ın rootless/daemonless avantajı gerçek ama çoğu geliştirici için önemi düşük; asıl önemi güvenlik hassasiyeti yüksek ortamlarda (RHEL, regulated industries) ortaya çıkıyor.
4. **OCI standardı geçişi kolaylaştırıyor ama zorunlu kılmıyor** — image formatı standart olduğu için istenildiğinde geçilebiliyor, bu da acil değiştirme baskısını azaltıyor.

**Özet:** Docker = development rahatlığı ve ekosistem. Podman = güvenlik önceliği/RHEL. containerd/CRI-O = production Kubernetes. Buildah/Kaniko = CI/CD'de sadece build. Hepsi OCI standardına uyduğu için birbirinin yerini kısmen alabiliyor, ama kullanım senaryosuna göre seçiliyor.

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır. Adım adım komutlar ve çıktılar için `practice.md`'ye bakınız._
