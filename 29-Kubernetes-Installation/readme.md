# ☸️ Kubernetes Kurulum Yöntemleri — Vagrant, kubeadm, MicroK8s, minikube, Kubespray

28. fazda Kubernetes'in temel kavramlarını (GitOps, küme mimarisi, kubectl) işledim. Bu fazda k8s-tr roadmap'inin önerdiği beş kurulum yöntemini (Vagrant, Kubespray, MicroK8s, kubeadm, minikube) sırayla, gerçekten kurup test ederek karşılaştırdım.

---

## Önce Bir Netleştirme — Ne Öğreniyoruz

Beş farklı Kubernetes öğrenmiyorum — Kubernetes'in kendisi (Pod, Service, kube-apiserver, etcd, kubectl komutları) hepsinde aynı kalıyor, o zaten 28. fazda öğrenildi. Burada öğrendiğim, **aynı Kubernetes'i kurmak için kullanılabilen farklı yöntemler** — arabayla, otobüsle, yürüyerek aynı eve gitmek gibi: vardığın ev (Kubernetes'in kendisi) aynı, sadece yol (kurulum yöntemi) farklı.

Gerçek dünyada da hiç kimse bunların hepsini aynı anda denemiyor — bir şirket ihtiyacına göre **birini seçip onunla kalıyor**: bulutta genelde yönetilen servisler (EKS, GKE, AKS), kendi sunucularında (bare metal) Kubespray/kubeadm, edge/IoT'de MicroK8s gibi hafif dağıtımlar, geliştiricinin kendi bilgisayarında minikube. Aralarındaki gerçek farkı görmek için hepsini kendim denedim.

---

## 1. Vagrant — Neden Denemedim

Faz 02'de (stajın en başında) Vagrant'ı kendi bilgisayarımda (VMware provider ile) kurmuş, iki gerçek sorunla karşılaşmıştım ("no usable providers" ve yanlış box adı hatası) — o deneyim zaten belgeliydi.

Ama bu VPS'te Vagrant'ı denemeden önce, sunucunun buna teknik olarak izin verip vermediğini kontrol ettim:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

```
0
```

Sonuç `0` — bu VPS'te **nested virtualization tamamen kapalı**. Bu, VirtualBox/VMware'in bu sunucuda hiçbir şekilde bir sanal makine başlatamayacağı anlamına geliyor, sadece Vagrant değil, KVM tabanlı hiçbir sanallaştırma çalışmaz. Deneme bile gerekmedi, teknik olarak imkansız olduğu kanıtlandı.

---

## 2. kubeadm — En Uzun, En Öğretici Yolculuk

### Ön Hazırlık

Swap'ı kapattım (`swapoff -a`), kernel modüllerini (`overlay`, `br_netfilter`) yükledim, gerekli sysctl ayarlarını (`ip_forward=1` gibi) yaptım.

### CRI-O Kurulumu — İlk Güncel Olmama Sorunu

k8s-tr sayfasındaki CRI-O repo adresi (`devel:kubic:libcontainers`) **artık çalışmıyordu** — bu repo yapısı kaldırılmış. Güncel yöntemi (`isv:/cri-o:/stable`) araştırıp kullandım.

### kubeadm/kubelet/kubectl Kurulumu — İkinci Güncel Olmama Sorunu

Aynı sorun tekrar çıktı — k8s-tr'nin `apt.kubernetes.io` adresi **2023'ten beri kullanımdan kalkmış**. Güncel `pkgs.k8s.io` adresini kullandım.

### İlk `kubeadm init` — Swap Geri Geldi

İlk deneme başarısız oldu. Kubelet loglarına baktım: swap yeniden açılmıştı. Sebep: `swapoff -a` geçiciydi, `/etc/fstab`'daki kayıt reboot'ta swap'ı otomatik geri açıyordu. `/etc/fstab`'daki swap satırının başına `#` koyarak kalıcı olarak kapattım.

### İkinci `kubeadm init` — Başarılı, Ama Sonra Karışıklık

Swap kalıcı kapanınca `kubeadm init` başarıyla tamamlandı. Ama sonra ben bir `kubeadm reset` çalıştırıp, ardından `sudo` unutarak ve doğru parametreleri yazmadan tekrar `init` denedim — hata aldım. Doğru komutu tekrar çalıştırınca, temiz bir şekilde başarıyla kuruldu.

### Node "Ready" Ama CNI Yok — Varsayımda Bulunmadan Test Ettim

`kubectl get nodes` node'u `Ready` gösterdi ama henüz Calico kurmamıştım — bu şüpheliydi. Gerçek bir nginx pod'u çalıştırıp test ettim:

**Engel 1 — Taint:** Pod hiçbir node'a atanamadı. kubeadm, control-plane node'una otomatik olarak `NoSchedule` taint'i koyuyor (normalde worker node'lar ayrı olur). Tek node'um olduğu için elle kaldırdım:

```bash
kubectl taint nodes ubuntu node-role.kubernetes.io/control-plane:NoSchedule-
```

**Engel 2 — Gerçek Bir Ağ Yok:** Taint kalkınca pod `ContainerCreating`'de takıldı, IP alamadı. `/etc/cni/net.d/` klasörüne baktım — geçerli bir Kubernetes CNI config'i hiç yoktu, sadece CRI-O'nun kapalı bıraktığı bir dosya ve **Faz 27'den (Docker Alternatifleri, Podman denemesi) kalma bir Podman ağ config'i** vardı.

Calico'yu kurdum:

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml
```

**Son Sürpriz — Yanlış CNI Kullanılıyordu:** Calico pod'ları `Running` oldu ama test pod'u `10.88.0.4` gibi bir IP aldı — bizim istediğimiz `192.168.x.x` değil, **Podman'ın varsayılan ağ aralığı**. Eski `87-podman-bridge.conflist` dosyası hâlâ Calico'nun önüne geçiyordu. Dosyayı kaldırınca (`/root`'a taşıyarak), pod gerçekten `192.168.243.193` gibi doğru aralıktan bir IP aldı.

---

## 3. MicroK8s — Neredeyse Sıfır Sürtünme

```bash
sudo snap install microk8s --classic
```

Tek komutla kuruldu. İzin sorunu (`sudo usermod -a -G microk8s altun`) dışında hiçbir manuel adım gerekmedi — CNI, DNS hepsi hazır geldi.

**Bir kafa karıştırıcı an:** `alias kubectl="microk8s kubectl"` tanımlamıştım — bu, daha sonra minikube'i test ederken **yanlışlıkla hâlâ MicroK8s'i test ettiğimi** fark etmeme sebep oldu (`type kubectl` ile "aliased to microk8s kubectl" görünce anladım). Alias'ı kaldırdım, gerçek `kubectl` binary'sini kullanmaya geçtim.

**Durdurma da beklenenden zor çıktı:** `microk8s stop` komutu **gerçekte durdurmuyordu** — `kubelite` process'i arka planda çalışmaya devam ediyordu. Gerçek çözüm `sudo snap stop microk8s` oldu, snap seviyesinde tüm servisleri durdurdu.

Test: pod anında `Running` oldu, gerçek IP aldı, hiç ek adım gerekmedi.

---

## 4. minikube — Docker Driver ile Hızlı

```bash
minikube start --driver=docker
```

Sunucuda zaten Docker kurulu olduğu için, ek sanallaştırmaya gerek kalmadan direkt başladı.

**Aynı alias sorunu tekrarlandı:** İlk testte `kubectl get nodes` **`v1.35.6`** (MicroK8s'in sürümü) gösterdi, minikube'in kendisi **`v1.35.1`** demişti — tutarsızlık, eski alias'ın hâlâ etkili olduğunu gösterdi. `unalias kubectl` ile düzelttim, `kubectl config current-context` ile gerçekten `minikube`'e bağlı olduğumu doğruladım.

Test: pod `Running` oldu, `10.244.0.4` gibi minikube'in kendi standart ağından bir IP aldı — CNI yine hazır geldi.

---

## 5. Kubespray — En Uzun Ama En Otomatik

### İlk Engel — Script Kaldırılmış

k8s-tr sayfasının önerdiği `contrib/inventory_builder/inventory.py` script'i, kullandığım `release-2.28` sürümünde **kalıcı olarak kaldırılmıştı** (v2.27.0'da, GitHub'da bunu doğrulayan bir tartışma buldum). Envanteri (`inventory.ini`) elle düzenledim — tek sunucumu hem `kube_control_plane`, hem `etcd:children`, hem `kube_node` grubuna yazdım.

### İkinci Engel — SSH Kendine Bağlanamıyor

Ansible, sunucunun **kendi kendine** SSH ile bağlanmasını gerektiriyor (senin bilgisayarındaki key sunucuda yok). Sunucuda yeni bir SSH key oluşturup kendi `authorized_keys`'ine ekledim, kendi kendine bağlanabildiğini test ettim.

### Üçüncü Engel — sudo Parolası

`--ask-become-pass` bayrağını ekleyip Ansible'ın sudo parolasını sorabilmesini sağladım.

### Dördüncü Engel — Eski kubeadm etcd'si Port Çakışması

Kurulum 17 dakika ilerledikten sonra etcd başlatılamadı: `bind: address already in use`, port `2380`. Kubeadm'den kalma eski `etcd` process'i hâlâ çalışıyordu. Öldürdüm, ama bu sefer **Kubespray'in kendi etcd'si** (auto-restart döngüsündeydi) hemen devreye girip başarıyla başladı.

### Beşinci Engel — En Köklü Sorun: Eski `/etc/kubernetes/` Kalıntısı

Bir sonraki adımda control-plane kurulumu **sertifika dosyası bulunamadı** hatasıyla durdu (`/etc/kubernetes/ssl/apiserver.crt not found`). Sebep: kubeadm'den kalma `/etc/kubernetes/pki/` klasörü hâlâ duruyordu, Kubespray ise farklı bir klasör yapısı (`/etc/kubernetes/ssl/`) bekliyordu — ikisi çakışmıştı.

Tam bir temizlik yaptım:

```bash
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/pki /etc/kubernetes/ssl /etc/kubernetes/manifests
sudo rm -f /etc/kubernetes/*.conf /etc/kubernetes/*.yaml /etc/kubernetes/*.env /etc/kubernetes/*.old
sudo rm -rf /etc/cni/net.d/*
rm -f ~/.kube/config
```

Bu tam temizlikten sonra, Ansible playbook'unu sıfırdan çalıştırdım — bu sefer **`failed=0`**, tamamen sorunsuz tamamlandı (~20 dakika). Calico da otomatik olarak kuruldu, hiç elle taint kaldırmaya ya da CNI config'i temizlemeye gerek kalmadı.

Test: node `Ready`, pod `Running`, gerçek IP (`10.233.102.132`, Kubespray'in kendi Calico CIDR'ından).

---

## 📊 Karşılaştırma

| Araç      | CNI Hazır mı                 | Manuel Adım                                                           | Temiz Kurulum Süresi\* |
| --------- | ---------------------------- | --------------------------------------------------------------------- | ---------------------- |
| Vagrant   | —                            | İmkansız (nested virtualization yok)                                  | —                      |
| kubeadm   | ❌ Elle kuruldu              | Çok (swap/fstab, güncel olmayan repolar, taint, eski Podman config'i) | ~15 dk                 |
| MicroK8s  | ✅ Hazır                     | Neredeyse hiç (sadece grup izni)                                      | ~2 dk                  |
| minikube  | ✅ Hazır                     | Hiç                                                                   | ~3 dk                  |
| Kubespray | ✅ Otomatik (Ansible içinde) | SSH key kurulumu + eski kalıntı temizliği                             | ~20 dk                 |

\* Bu süreler sadece **sorunsuz geçen tek bir kurulum komutunun** (`kubeadm init`, `ansible-playbook` vb.) çalışma süresi — karşılaştırma amaçlı. **Gerçek toplam süre çok daha uzundu:** bu beş yöntemi denemek, sorunları bulup çözmek dahil toplamda **3 gün** (15, 17 ve 18 Ağustos) sürdü — özellikle kubeadm ve Kubespray'de karşılaşılan port çakışmaları, eski kalıntı dosyalar ve config karışıklıkları yüzünden.

---

## 📝 Genel Ders

Kurulumları kaldırırken gerçekten kaldırıldığından emin olmak gerekliydi — yoksa bu çakışmalara sebep oluyor ve bir sonraki kurulumda hataya sebebiyet verip fazlasıyla zaman kaybı yaratıyor. "Durdurdum" sanmak yetmiyor, gerçekten `ss`/`ps` ile doğrulamak gerekiyor — MicroK8s'te `stop` komutunun bile gerçekte durdurmadığını gördük. Ayrıca kullanılacak aracın seçiminin ihtiyaca göre yapılması da çok önemli — beşi de aynı işi yapıyor ama hangi ortamda (bulut, bare metal, edge, geliştirici bilgisayarı) kullanılacağına göre doğru araç değişiyor.

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde, 15-18 Ağustos 2026 tarihleri arasında (3 gün süren, birçok gerçek hata ve düzeltme içeren) bir çalışmayla yapılmıştır._
