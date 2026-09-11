---
layout: page
---

# ☸️ OpenShift — Nedir, Karşılaştırma, Management, Build & Push, OC Client

Faz 37'de Güvenlik bölümünü, ve onunla birlikte **tüm Kubernetes roadmap'ini** tamamlamıştım. Bu, roadmap'in **eklenti niteliğindeki son bölümü** — OpenShift, Kubernetes'in bir özelliği değil, Red Hat'in **Kubernetes üzerine inşa ettiği ayrı, kurumsal bir platform.**

---

## 1. OpenShift Nedir, Karşılaştırma

**Yazılım örneği:** Kubernetes'i "çıplak" bir motor (sadece parçalar) gibi düşünürsen, OpenShift bu motorun üzerine **hazır kaporta, koltuk, klima** eklenmiş, anahtarını çevirip sürebileceğin **tam bir araba (PaaS — Platform as a Service).**

**Gerçek işlevi:** OpenShift, Kubernetes'i **temel alıp**, bu staj boyunca **ayrı ayrı öğrenip kurduğumuz** araçların bir kısmını **hazır, entegre** olarak sunuyor.

**Çapraz referans:** Sayfadaki karşılaştırma listesini, bu staj boyunca **ayrı ayrı kurduğumuz** araçlarla eşleştirdim:

- _"CI/CD hizmeti sağlar"_ → Faz 33'te ayrı ayrı kurduğumuz **ARGO-CD**'nin OpenShift'te hazır gelmesi
- _"Yerleşik container registry"_ → Faz 33'te Docker Hub kullandığımız yerde, OpenShift'in **kendi dahili** registry'si olması
- _"Gömülü DevSecOps katmanı"_ → Faz 35'te ayrı ayrı kurduğumuz **Kyverno/NeuVector**'ün OpenShift'te entegre gelmesi
- _"Web console"_ → Faz 33'teki **Dashboard**'a benzer ama form tabanlı, daha kapsamlı

**Dürüst bulgu — gerçek bir dış engel:** OpenShift'i gerçekten test etmek için **CodeReady Containers (CRC)** kurmaya çalıştım — bunun için **Red Hat'in web sitesinden ücretsiz bir hesap açıp "pull secret" indirmek** gerekiyordu. Hesap açma sürecinde **gerçek bir sorunla** karşılaşıldı (dış bir engel, kod/yapılandırma hatası değil), bu yüzden OpenShift'i **gerçek testle değil, kavramsal olarak** işledim — NeuVector'daki VPS kaynak kısıtına benzer şekilde, dürüstçe kabul edilmesi gereken bir sınır.

---

## 2. Management — Build

**Yazılım örneği:** Faz 19-27'de öğrendiğimiz `docker build` komutunu, **Kubernetes'in içinde otomatik tetiklenen** bir sürece dönüştürmek gibi.

**Gerçek işlevi:** `BuildConfig`, düz Kubernetes'te **hiç bulunmayan**, sadece OpenShift'in tanıdığı bir kaynak (`build.openshift.io/v1`) — Git reponu doğrudan container image'ine dönüştürüyor.

**Çapraz referans:** `triggers` alanındaki `GitHub`/`GitLab`/`ImageChange` (push olunca ya da temel image güncellenince otomatik yeniden build), Faz 33'teki **ARGO-CD'nin webhook tabanlı otomasyonuna** çok benziyor — farkı, ARGO-CD sadece **dağıtımı** otomatikleştiriyordu, `BuildConfig` **build aşamasını da** otomatikleştiriyor.

**YAML:**

```yaml
apiVersion: build.openshift.io/v1
kind: BuildConfig
metadata:
  name: myapp-build
spec:
  source:
    type: Git
    git:
      uri: https://github.com/edib/oc-example.git
      ref: master
  strategy:
    type: Docker
    dockerStrategy: {}
  output:
    to:
      kind: ImageStreamTag
      name: "merhaba-bash:latest"
  triggers:
    - type: ConfigChange
    - type: ImageChange
```

---

## 3. Build & Push (oc-build)

**Yazılım örneği:** `docker push` komutunun, OpenShift'in **kendi, dahili** registry'sine yönlendirilmiş hali.

**Gerçek işlevi:** `oc whoami -t`, geçerli oturumun token'ını veriyor; bu token, `podman login`/`docker login` ile **OpenShift'in kendi registry'sine** (`default-route-openshift-image-registry.apps-crc.testing`) giriş yapmak için kullanılıyor — harici bir registry'ye (Docker Hub, Harbor) hiç ihtiyaç duymadan.

**Çapraz referans:** Sayfanın bahsettiği **"Developer Sandbox"**, Red Hat'in **ücretsiz, web üzerinden barındırılan** bir deneme OpenShift ortamı — CRC/pull-secret engelini aşmanın alternatif bir yolu olarak, backlog'a **gelecekte denenebilecek** bir seçenek olarak not düştüm.

**Komut:**

```bash
oc login --token=<token> --server=<server-hostname>
oc whoami
podman login -u kubeadmin -p $(oc whoami -t) default-route-openshift-image-registry.apps-crc.testing --tls-verify=false
oc new-project demo
podman push default-route-openshift-image-registry.apps-crc.testing/demo/alpine:latest --tls-verify=false
```

---

## 4. OC Client

**Yazılım örneği:** `kubectl`'in OpenShift'e özel karşılığı — çoğu komut tanıdık, ama bazıları OpenShift'e özel kısayollar sunuyor.

**Gerçek işlevi:** `oc get route` — **`Route`**, OpenShift'in **kendi, yerleşik Ingress alternatifi.**

**Çapraz referans:** Faz 31'de Ingress kurarken, **ayrı bir controller** (nginx-ingress) kurmak zorunda kalmıştık — OpenShift'te `Route`, **hiçbir ekstra kurulum gerektirmeden** hazır geliyor. `oc expose deploy` komutu, Faz 30'daki `kubectl expose deployment`'ın (Service oluşturma) **bir adım ötesi** — hem Service'i hem dışarıya açık bir `Route`'u tek komutla oluşturuyor.

**Komut:**

```bash
oc create deployment myapp --image=quay.io/rhdevelopers/quarkus-demo:v1
oc expose deploy myapp
oc expose service myapp
oc get route
```

---

## 📊 Özet

| Konu                 | Ne Öğrendim                                                                                            |
| -------------------- | ------------------------------------------------------------------------------------------------------ |
| Nedir, Karşılaştırma | OpenShift = Kubernetes + hazır entegre araçlar (CI/CD, registry, DevSecOps, web console)               |
| Management (Build)   | `BuildConfig`, Git reponu otomatik image'e dönüştüren OpenShift'e özel kaynak                          |
| Build & Push         | Dahili registry'ye `oc whoami -t` token'ıyla giriş; Developer Sandbox alternatif bir test yolu         |
| OC Client            | `Route`, Ingress'in kurulumsuz OpenShift alternatifi; `oc expose` Service+Route'u birlikte oluşturuyor |

---

ℹ️ _Bu konu, gerçek bir dış engel (Red Hat hesap açma sürecinde yaşanan sorun) nedeniyle gerçek testle değil, kavramsal olarak ve staj boyunca kurulan araçlarla çapraz referanslarla işlenmiştir. Bu, roadmap'in tamamının (Temel Kavramlar'dan Güvenlik'e, ve şimdi bu ek OpenShift bölümüne kadar) kapsandığı son belgedir._
