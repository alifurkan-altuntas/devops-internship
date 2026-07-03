# 🚦 Nginx — Rate Limiting ve Load Balancing

Nginx derinleşme fazından sonra iki şeyi daha ekledim: istek sayısını sınırlamak ve trafiği birden fazla backend arasında dağıtmak.

---

## 1. Rate Limiting

Bir IP'nin belirli bir sürede kaç istek atabileceğini sınırlar. Gerçek dünyada brute force koruması, DDoS hafifletme ve API koruması için kullanılır.

**Örnek:** Danışmaya dakikada en fazla 5 kişi alınıyor — fazlası geri gönderiliyor.

### Nasıl Çalışır

İki parçası var: zone tanımı ve uygulamak.

**Zone tanımı** — `nginx.conf`'taki `http` bloğuna eklendi:

```nginx
limit_req_zone $binary_remote_addr zone=genel:10m rate=5r/s;
```

- **`$binary_remote_addr`** — kimin istek attığını IP bazında takip et
- **`zone=genel:10m`** — "genel" adında bir hafıza bölgesi, 10MB (yaklaşık 160.000 IP tutabilir)
- **`rate=5r/s`** — her IP için saniyede maksimum 5 istek

**Location'a uygulamak** — `/`, `/users/`, `/computers/` bloklarına eklendi:

```nginx
limit_req zone=genel burst=10 nodelay;
```

- **`burst=10`** — ani yoğunluğa tolerans: biri aniden 10 istek atarsa hepsini kabul et, sonrasını engelle
- **`nodelay`** — burst kapsamındaki istekleri sıraya alma, hemen işle

**`burst` ve `nodelay` olmadan ne olurdu?**

Sadece `limit_req zone=genel;` yazsaydık — her saniyede 5'ten fazla istek anında 503 alırdı, hiç tolerans yok. `nodelay` olmadan ise burst istekleri sıraya alınır ve yavaş yavaş işlenir — kullanıcı bekler. İkisi birlikte "anında kabul et ama limitin üstüne çıkma" demek.

### Test

20 istek art arda attım:

```bash
for i in {1..20}; do curl -s -o /dev/null -w "%{http_code}\n" http://localhost/; done
```

```
200 200 200 200 200 200 200 200 200 200 200 200
503 503 503 503
200
503 503 503
```

İlk 12 istek geçti, sonra 503 gelmeye başladı. Bir süre sonra tekrar 200 — Nginx zaman penceresini sıfırladı. Beklediğim gibi geldi.

`/admin` path'ine rate limiting eklemedim — zaten `allow`/`deny` ile kısıtlı, 20 istek de 20 kere 403 döndü.

---

## 2. Load Balancing

Aynı işi yapan birden fazla backend çalıştırıp Nginx'in trafiği aralarında dağıtması. Bir instance çökerse diğeri devam eder, kullanıcı hiçbir şey fark etmez.

**Örnek:** Danışmada 1 değil 2-3 kişi çalışıyor — gelen herkes boş olan danışmana yönlendiriliyor. Ya da yolda 1 şerit yerine 4-5 şerit — trafik dağılıyor, kimse tıkanmıyor.

**Failover için:** Kavşağa giden bir yol ve çıkan 2 yol var — yollardan biri kapatılınca trafik otomatik olarak diğerine gidiyor.

### Yapılandırma

`nginx.conf`'a upstream bloğu eklendi:

```nginx
upstream users_backend {
    server localhost:3000;
    server localhost:3001;
}
```

`/users/` location'ı güncellendi:

```nginx
location /users/ {
    limit_req zone=genel burst=10 nodelay;
    proxy_pass http://users_backend/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

İkinci instance oluşturuldu:

```bash
mkdir -p /tmp/users2
echo "<h1>Users Servisi — Instance 2</h1>" > /tmp/users2/index.html
cd /tmp/users2 && python3 -m http.server 3001 &
```

### Diğer Load Balancing Yöntemleri

Bu fazda round-robin kullandım — backend'ler basit ve istekler eşit sürüyor. Ama production'da iki yöntem daha var, bunları bilmek önemli:

**`least_conn`** — en az aktif bağlantısı olan backend'e gönder. Bazı istekler uzun sürüyorsa (örn. dosya yükleme), round-robin adaletsiz olabilir — biri meşgulken diğerine yeni iş gelir. `least_conn` bunu çözer.

**Örnek:** Navigasyon gibi — yol tarifi alırken en kısa ve en az trafikli yolu seçer. Sağ yol tıkalıysa seni sol yola yönlendirir.

```nginx
upstream users_backend {
    least_conn;
    server localhost:3000;
    server localhost:3001;
}
```

**`ip_hash`** — aynı IP her zaman aynı backend'e gider. Uygulama session bilgisini backend'de tutuyorsa gerekli. Round-robin ile kullanıcı Instance 1'de giriş yaptı, sonraki istekte Instance 2'ye gidebilir — session kaybolur. `ip_hash` bunu önler.

**Örnek:** Sürekli aynı berbere gitmek gibi — başka berbere gitmiyorsun, çünkü o seni tanıyor, saçını nasıl istediğini biliyor. Başka berbere gidersen her şeyi baştan anlatmak zorunda kalırsın. `ip_hash` de böyle — kullanıcı hep aynı backend'e gider, o backend kullanıcının oturumunu biliyor.

```nginx
upstream users_backend {
    ip_hash;
    server localhost:3000;
    server localhost:3001;
}
```

Bu fazda ikisini de kullanmadım — Python backend'leri stateless ve istekler homojen. Ama hangisini ne zaman seçmek gerektiğini bilmek, gerçek bir deployment'ta fark yaratır.

### Round-Robin

```bash
for i in {1..6}; do curl -s http://localhost/users/; echo; done
```

```
Users servisi
Users servisi
Users servisi
Users Servisi — Instance 2
Users servisi
Users Servisi — Instance 2
```

Nginx trafiği iki instance arasında dağıttı.

### Failover

Instance 1'i kapattım:

```bash
kill $(lsof -t -i:3000)
for i in {1..4}; do curl -s http://localhost/users/; echo; done
```

```
Users Servisi — Instance 2
Users Servisi — Instance 2
Users Servisi — Instance 2
Users Servisi — Instance 2
```

Instance 1 çöktü, Nginx otomatik olarak Instance 2'ye geçti — hiç kesinti olmadı. Instance 1'i geri açınca round-robin'e döndü.

Dışarıdan (Windows) da test ettim, aynı davranış:

```
Users servisi
Users Servisi — Instance 2
Users servisi
Users Servisi — Instance 2
Users servisi
Users Servisi — Instance 2
```

---

## 📊 Hızlı Referans

| Direktif                          | Görevi                                          |
| --------------------------------- | ----------------------------------------------- |
| `limit_req_zone`                  | Rate limiting zone'u tanımlar (`nginx.conf`'ta) |
| `limit_req`                       | Zone'u bir location'a uygular                   |
| `burst`                           | Ani yoğunluğa tolerans                          |
| `nodelay`                         | Burst isteklerini sıraya alma, hemen işle       |
| `upstream`                        | Backend havuzu tanımlar                         |
| `proxy_pass http://upstream_adi/` | Trafiği upstream havuzuna yönlendir             |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VDS üzerinde yapılmıştır._
