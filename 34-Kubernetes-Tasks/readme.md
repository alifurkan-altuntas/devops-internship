# ☸️ Kubernetes Görevler — Güvenlik, İç Yük Dengeleme, Günlük Kayıtları, İyi Pratikler, CKA Konuları

33. fazda Ek Araçlar bölümünü tamamlamıştım. Bu fazda roadmap'in Görevler bölümünü işledim — beş konu, hepsi gerçek testlerle kanıtlandı.

---

## 1. Güvenlik — JVM Bellek Yönetimi

**Yazılım örneği:** Bir kiracının, ev sahibinin verdiği toplam elektrik kotasının **sadece bir kısmını** kullanmayı seçmesi gibi — ev sahibi (Kubernetes) 800MB verirken, kiracı (JVM) kendiliğinden sadece 200MB kullanmaya karar veriyor, geri kalanı israf ediyor.

**Gerçek işlevi:** Java 10+ JVM'ler "container-aware" — konteynerin bellek limitini görebiliyorlar. Ama varsayılan davranışları **çok muhafazakar**: 512MB üstü konteynerlerde limitin sadece **%25**'ini heap'e ayırıyorlar, 256MB altı konteynerlerde ise **%50**'sini.

**Çapraz referans:** Bu, Faz 31'deki `requests`/`limits` bilgime **JVM-özel bir katman** ekliyor — Kubernetes'in bellek limiti koyması yeterli değil, içindeki uygulamanın (JVM gibi) o limiti **doğru yorumlaması** da gerekiyor.

Gerçek testle kanıtladım: `200Mi` limitli (küçük kategori) bir JVM'in `%50`'sini (100MB), `800Mi` limitli (büyük kategori) bir JVM'in `%25`'ini (200MB) heap'e ayırdığını; `MaxRAMPercentage=75.0` ile bu oranın **elle kontrol edilebilir** olduğunu (600MB'a çıktığını) kanıtladım.

**YAML:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: jvm-tuned
spec:
  containers:
    - name: app
      image: eclipse-temurin:21-jdk
      resources:
        limits:
          memory: "800Mi"
      env:
        - name: JAVA_TOOL_OPTIONS
          value: "-XX:MaxRAMPercentage=75.0"
```

---

## 2. İç Yük Dengeleme

**Yazılım örneği:** Bir ofis santralinin, gelen telefon çağrılarını **şirket dışındaki** farklı şubelere yönlendirmesi gibi — santral (nginx), aramanın içeriğine değil, sadece **numaraya (IP:port)** bakarak yönlendiriyor.

**Gerçek işlevi:** nginx'in `stream` bloğu, **ham TCP trafiğini**, ConfigMap içinde **elle tanımlanan** herhangi bir hedefe (IP/hostname) yük dengeliyor — bu hedefler **Kubernetes'in bildiği bir Service olmak zorunda değil**, cluster dışındaki gerçek sunucular bile olabilir.

**Çapraz referans:** Bu, Faz 31'deki Ingress (L7, path/host okuyan) ve Service'ten (L4, ama sadece pod seçici) **temelde farklı** bir üçüncü yöntem — Kubernetes'in kendi seçici mekanizmasını hiç kullanmıyor. `subPath` alanı, bir ConfigMap'in **tek bir dosyasını**, dizinin geri kalanını bozmadan monte etmeyi sağlıyor.

Gerçek testle kanıtladım: iki backend arasında **tam round-robin** (`BACKEND-1, BACKEND-2, BACKEND-1...`) dağılımı gerçekleşti.

**YAML:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-lb-conf
data:
  nginx.conf: |
    stream {
        upstream myservis_lb {
        server backend1.lbtest.svc.cluster.local:5678;
        server backend2.lbtest.svc.cluster.local:5678;
      }
          server {
            listen     9200;
            proxy_pass myservis_lb;
        }
    }
```

---

## 3. Günlük Kayıtları

**Yazılım örneği:** Tek bir kişiyle telefonda konuşmak (`kubectl logs`) yerine, bir konferans görüşmesinde **birden fazla kişiyi aynı anda** dinlemek (`stern`) gibi.

**Gerçek işlevi:** `kubectl logs`, **tek bir pod adı** ister — birden fazla pod'un loglarını görmek için ayrı ayrı komut gerekir. `stern`, bir **regex** ile eşleşen **tüm pod'ları aynı anda**, tek komutla, renklendirilmiş şekilde takip ediyor.

**Çapraz referans:** Sayfadaki `wercker/stern` reposunun terk edildiğini, güncel bakımlı fork'un `stern/stern` olduğunu araştırıp kullandım.

Gerçek testle kanıtladım: `stern my-deployment` komutu, 3 farklı pod'un başlangıç loglarını **tek ekranda, iç içe geçmiş şekilde**, her satırda hangi pod'dan geldiği etiketlenerek gösterdi.

---

## 4. İyi Pratikler

**Yazılım örneği:** Bir binaya giriş için hem **güvenlik kontrolünden geçme zorunluluğu** (Pod Security Admission) hem **kaç kişinin aynı anda içeride olabileceği sınırı** (ResourceQuota) olması gibi — ikisi de farklı şeyleri sınırlıyor.

**Gerçek işlevi:** Kontrol listesindeki iki maddeyi derinlemesine test ettim — **Pod Security Admission** (bir namespace'e güvenlik standardı etiketi koyup, uymayan pod'ları admission aşamasında reddetme) ve **ResourceQuota** (bir namespace'in **toplam** kaynak kullanımına — pod sayısı, CPU — üst sınır koyma).

**Çapraz referans:** Kontrol listesindeki `PodSecurityPolicy` maddesinin **artık var olmadığını** (Kubernetes v1.25'te tamamen kaldırıldığını) araştırıp buldum — listenin bazı maddeleri güncel değil. Bu, ResourceQuota'nın Faz 31'deki **pod seviyesi** `requests`/`limits`'in üstüne eklenen **namespace seviyesi** bir katman olduğunu gösterdi.

Gerçek testle kanıtladım: `restricted` etiketli bir namespace'te ayrıcalıklı (`privileged: true`) bir pod'un **admission aşamasında reddedildiğini** (beş ayrı güvenlik kuralı listeleyen bir hata mesajıyla); `pods: "2"` kotalı bir namespace'te **3. pod'un** `exceeded quota` hatasıyla reddedildiğini.

**YAML:**

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
spec:
  hard:
    pods: "2"
    requests.cpu: "500m"
```

---

## 5. CKA Konuları

**Yazılım örneği:** Bir üniversite müfredatının, öğrencinin zaten aldığı derslerin bir **özetini** çıkarması gibi — bu sayfa yeni bir şey öğretmiyor, staj boyunca öğrenilenlerin **CKA sertifikasının kategorilerine göre** haritasını çıkarıyor.

**Gerçek işlevi:** CKA'nın dokuz kategorisinin (Küme Mimarisi, Konteynerler, İş Yükleri, Servisler/Ağ, Depolama, Güvenlik, İlkeler, Planlama/Tahliye, Küme Yönetimi) **hemen hepsinin**, Faz 28'den bugüne kadar zaten gerçek testlerle kapsandığını fark ettim.

**Çapraz referans:** "Planlama ve Tahliye" kategorisindeki **"tahliye" (eviction)** kavramının, Faz 33'teki Istio testinde **gerçekten karşılaştığım** `disk-pressure` taint'iyle (Kubernetes'in node kaynak sıkıntısı yaşayınca **otomatik olarak** pod'ları koruma altına alması) birebir örtüştüğünü kanıtladım.

---

## 📊 Özet

| Konu             | Ne Öğrendim                                                                                                |
| ---------------- | ---------------------------------------------------------------------------------------------------------- |
| Güvenlik (JVM)   | JVM, konteyner limitinin sadece %25-50'sini varsayılan olarak kullanır, MaxRAMPercentage ile ayarlanabilir |
| İç Yük Dengeleme | nginx stream bloğu, Kubernetes seçicisi olmadan, elle tanımlı hedeflere TCP yük dengeler                   |
| Günlük Kayıtları | stern, kubectl logs'un yapamadığı çoklu pod takibini tek komutla yapar                                     |
| İyi Pratikler    | Pod Security Admission (namespace seviyesi güvenlik), ResourceQuota (namespace seviyesi kota)              |
| CKA Konuları     | Staj boyunca öğrenilenler, CKA'nın neredeyse tüm kategorilerini zaten kapsıyor                             |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde (Kubespray cluster'ında) yapılmıştır — her konu yazılım ekosisteminden bir örnekle, gerçek işleviyle, ilgili fazlara çapraz referansla, ve gerçek YAML/kubectl testleriyle kanıtlanmıştır. Süreç boyunca eski/kaldırılmış kaynaklar (stern'in terk edilmiş orijinal reposu, PodSecurityPolicy'nin v1.25'te tamamen kaldırılmış olması) tespit edilip güncel karşılıklarıyla değiştirilmiştir._
