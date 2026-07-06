# 🔐 OpenResty — Token Authentication, PostgreSQL, MySQL, Redis

Bu fazda OpenResty ile token korumalı bir API kurdum. PostgreSQL, MySQL ve Redis'i birlikte kullandım. Tüm servisler Docker ile ayağa kaldırıldı.

---

## Neden OpenResty

Nginx sadece yönlendirme yapabiliyor — "bu path'e gel, şu backend'e git." Kendi başına iş yapamıyor.

OpenResty ise Nginx'in üzerine kurulu ama içine Lua interpreter gömülmüş. Yani hem yönlendiriyor hem de içinde kod çalıştırabiliyor — token kontrol edebiliyor, veritabanına bağlanabiliyor, cevabı kendisi oluşturabiliyor.

**Benzetme:** Nginx danışma görevlisi gibi — seni doğru kapıya yönlendiriyor ama içeri girip işi kendisi yapmıyor. OpenResty ise çalışanların geçtiği güvenlik turnikesi gibi — kart okutuyorlar, yetkisi varsa içeri giriyor, işini yapıyor.

---

## Mimari

```
İstek geldi
  → Token doğru mu? (auth.lua)
    → Hayır → 401 Unauthorized
    → Evet → Hangi path?
              /users    → PostgreSQL'den kullanıcılar
              /products → MySQL'den ürünler
              /cache    → Redis'ten cache
```

---

## Servisler

### OpenResty
Token kontrolü ve istek yönetimi. Lua kodu burada çalışıyor.

### PostgreSQL
Kalıcı veritabanı — kullanıcı verileri burada tutuluyor.

### MySQL
Kalıcı veritabanı — ürün verileri burada tutuluyor.

### Redis
Cache — sık kullanılan verileri geçici olarak bellekte tutuyor. Her seferinde veritabanına gitmek yerine buradan hızlıca alınıyor. TTL (Time To Live) ile belirlenen süre dolunca veri siliniyor — veri değişirse eski cache kullanılmaz, TTL dolunca veritabanından taze veri çekilir.

**Depo benzetmesi:**
- PostgreSQL/MySQL → deponun derinleri, kalıcı ama ulaşmak zaman alır
- Redis → yakındaki raf, hızlı erişim ama geçici

---

## Klasör Yapısı

```
openresty-demo/
├── docker-compose.yml   → 4 servisi tanımlar
├── Dockerfile           → OpenResty'ye pgmoon ekler
├── nginx.conf           → OpenResty'ye nasıl davranacağını söyler
├── lua/
│   ├── auth.lua         → token kontrol
│   ├── users.lua        → PostgreSQL'den veri çek
│   ├── products.lua     → MySQL'den veri çek
│   └── cache.lua        → Redis'ten veri çek
└── init/
    ├── postgres/init.sql → users tablosunu oluştur
    └── mysql/init.sql    → products tablosunu oluştur
```

---

## Yapılandırma

### docker-compose.yml

4 servisi tek dosyada tanımladık. `docker compose up` komutuyla hepsi birden ayağa kalktı — tek tek kurmak yerine, sürümleri, şifreleri, bağımlılıkları ve dosya konumlarını bu dosyaya yazdık, Docker halletti.

```yaml
services:
  openresty:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf
      - ./lua:/usr/local/openresty/nginx/lua
    depends_on:
      - postgres
      - mysql
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: demo
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: secret
    volumes:
      - ./init/postgres:/docker-entrypoint-initdb.d

  mysql:
    image: mysql:8
    environment:
      MYSQL_DATABASE: demo
      MYSQL_USER: admin
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - ./init/mysql:/docker-entrypoint-initdb.d

  redis:
    image: redis:7
```

### Dockerfile

OpenResty'nin hazır image'ında `pgmoon` kütüphanesi yoktu. `pgmoon`, Lua'nın PostgreSQL ile konuşmasını sağlıyor. Paket yöneticileri Alpine'da çalışmadı (`luarocks` bulunamadı, `opm` perl istedi) — en son direkt GitHub'dan çektik:

```dockerfile
FROM openresty/openresty:alpine

RUN apk add --no-cache git && \
    git clone https://github.com/leafo/pgmoon.git /usr/local/openresty/lualib/pgmoon_repo && \
    cp -r /usr/local/openresty/lualib/pgmoon_repo/pgmoon /usr/local/openresty/lualib/pgmoon
```

### nginx.conf

```nginx
events {}

http {
    server {
        listen 80;
        resolver 127.0.0.11 valid=30s;

        access_by_lua_file /usr/local/openresty/nginx/lua/auth.lua;

        location /users {
            content_by_lua_file /usr/local/openresty/nginx/lua/users.lua;
        }

        location /products {
            content_by_lua_file /usr/local/openresty/nginx/lua/products.lua;
        }

        location /cache {
            content_by_lua_file /usr/local/openresty/nginx/lua/cache.lua;
        }
    }
}
```

- **`access_by_lua_file`** → her isteğe önce bu dosyayı çalıştır (token kontrol)
- **`content_by_lua_file`** → token geçerliyse cevabı bu dosya oluştursun
- **`resolver 127.0.0.11`** → Docker'ın iç DNS sunucusu. Nginx, `"postgres"` gibi container isimlerini IP'ye çeviremez — Docker'ın DNS'i biliyor. Bu satır olmadan `no resolver defined to resolve "postgres"` hatası geliyor.

---

## Lua Dosyaları

### auth.lua — Token Kontrol

```lua
local token = ngx.req.get_headers()["Authorization"]

if token ~= "secret-token-123" then
    ngx.status = 401
    ngx.say("Unauthorized: Token geçersiz veya eksik")
    ngx.exit(401)
end
```

Gelen isteğin `Authorization` header'ından token'ı alıyor. Yanlışsa veya yoksa 401 döndürüp duruyor. Doğruysa devam ediyor — banka kapısındaki güvenlik gibi, kartın yoksa içeri giremiyorsun.

### users.lua — PostgreSQL

```lua
local pgmoon = require "pgmoon"

local pg = pgmoon.new({
    host = "postgres",
    port = "5432",
    database = "demo",
    user = "admin",
    password = "secret"
})

local ok, err = pg:connect()
if not ok then
    ngx.status = 500
    ngx.say("Veritabanına bağlanılamadı: " .. err)
    return
end

local res, err = pg:query("SELECT * FROM users")
if not res then
    ngx.status = 500
    ngx.say("Sorgu hatası: " .. err)
    return
end

ngx.header["Content-Type"] = "application/json"
ngx.say(require("cjson").encode(res))
```

PostgreSQL'e bağlanıyor, `SELECT * FROM users` sorgusunu çalıştırıyor, sonucu JSON olarak döndürüyor. Her adımda hata kontrolü var.

### products.lua — MySQL

Aynı mantık, MySQL için. İki fark:
- Kütüphane farklı: `resty.mysql` (OpenResty'de yerleşik geliyor)
- Bağlantı şekli farklı: `mysql:new()` sonra `db:connect({...})` — kütüphanenin yazım şekli böyle

```lua
local mysql = require "resty.mysql"

local db, err = mysql:new()
if not db then
    ngx.status = 500
    ngx.say("MySQL oluşturulamadı: " .. err)
    return
end

local ok, err, errcode = db:connect({
    host = "mysql",
    port = 3306,
    database = "demo",
    user = "admin",
    password = "secret"
})

if not ok then
    ngx.status = 500
    ngx.say("MySQL bağlantı hatası: " .. err)
    return
end

local res, err = db:query("SELECT * FROM products")
if not res then
    ngx.status = 500
    ngx.say("Sorgu hatası: " .. err)
    return
end

ngx.header["Content-Type"] = "application/json"
ngx.say(require("cjson").encode(res))
```

### cache.lua — Redis

```lua
local val, err = red:get("demo_key")

if val == ngx.null then
    red:set("demo_key", "Bu veri Redis cache'den geldi!")
    red:expire("demo_key", 30)
    val = "Bu veri Redis cache'den geldi! (yeni oluşturuldu)"
end
```

Önce Redis'te var mı bakıyor. Yoksa (`ngx.null`) oluşturuyor, 30 saniyelik TTL ile kaydediyor. Varsa direkt döndürüyor — veritabanına gitmiyor.

İlk istekte `(yeni oluşturuldu)` yazısı geliyor, ikinci istekte gelmiyor — veri Redis'ten geliyor.

---

## init.sql Dosyaları

Container ilk başladığında `docker-entrypoint-initdb.d` klasöründeki SQL dosyalarını otomatik çalıştırıyor. Olmasa tablolar oluşmazdı, sorgular hata verirdi.

**postgres/init.sql:**
```sql
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100)
);

INSERT INTO users (name, email) VALUES
    ('Harun', 'harun@mail.com'),
    ('Ali', 'ali@mail.com'),
    ('Ayşe', 'ayse@mail.com');
```

**mysql/init.sql:**
```sql
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    price DECIMAL(10,2)
);

INSERT INTO products (name, price) VALUES
    ('Laptop', 15000.00),
    ('Mouse', 250.00),
    ('Klavye', 500.00);
```

---

## Test Sonuçları

**Token olmadan:**
```bash
curl http://localhost:8080/users
# Unauthorized: Token geçersiz veya eksik
```

**Token ile — PostgreSQL:**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/users
# [{"name":"Harun","email":"harun@mail.com","id":1},...]
```

**Token ile — MySQL:**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/products
# [{"name":"Laptop","price":15000,"id":1},...]
```

**Token ile — Redis (ilk istek):**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/cache
# {"source":"redis","value":"Bu veri Redis cache'den geldi! (yeni oluşturuldu)"}
```

**Redis (ikinci istek — cache'den geliyor):**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/cache
# {"source":"redis","value":"Bu veri Redis cache'den geldi!"}
```

Dışarıdan da test edildi (`91.151.88.38:8080`) — aynı sonuçlar.

---

## Servisler Nasıl Başlatılır

```bash
cd ~/openresty-demo
docker compose up -d
```

Kapatmak için:
```bash
docker compose down
```

---

ℹ️ _Tüm testler gerçek bir Ubuntu VDS üzerinde yapılmıştır._