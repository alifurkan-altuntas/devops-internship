# 🔐 OpenResty — Token Authentication, PostgreSQL, MySQL, Redis

In this phase I built a token-protected API with OpenResty, connecting to PostgreSQL, MySQL, and Redis. All services were brought up with Docker.

---

## Why OpenResty

Nginx can only route — "come to this path, go to that backend." It can't do work on its own.

OpenResty is built on top of Nginx but with a Lua interpreter embedded inside. So it can both route and run code — check tokens, connect to databases, build responses itself.

**Example:** Nginx is like a receptionist — directing you to the right door but not going inside to do the work. OpenResty is like the security turnstile employees pass through — they swipe their card, if authorized they go in and do their job.

---

## Architecture

```
Request arrives
  → Is the token valid? (auth.lua)
    → No  → 401 Unauthorized
    → Yes → Which path?
              /users    → users from PostgreSQL
              /products → products from MySQL
              /cache    → data from Redis cache
```

---

## Services

### OpenResty
Token control and request handling. Lua code runs here.

### PostgreSQL
Persistent database — user data stored here.

### MySQL
Persistent database — product data stored here.

### Redis
Cache — frequently accessed data stored temporarily in memory. Instead of hitting the database every time, data is retrieved from here quickly. TTL (Time To Live) sets how long data stays — when it expires, the next request fetches fresh data from the database.

**Warehouse analogy:**
- PostgreSQL/MySQL → the back of the warehouse, permanent but takes time to reach
- Redis → the nearby shelf, fast access but temporary

---

## Folder Structure

```
openresty-demo/
├── docker-compose.yml   → defines all 4 services
├── Dockerfile           → adds pgmoon to OpenResty
├── nginx.conf           → tells OpenResty how to behave
├── lua/
│   ├── auth.lua         → token check
│   ├── users.lua        → fetch from PostgreSQL
│   ├── products.lua     → fetch from MySQL
│   └── cache.lua        → fetch from Redis
└── init/
    ├── postgres/init.sql → create users table
    └── mysql/init.sql    → create products table
```

---

## Configuration

### docker-compose.yml

All 4 services defined in one file. `docker compose up` brought them all up at once — instead of installing each one separately, versions, passwords, dependencies, and file locations were all written here and Docker handled the rest.

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

The official OpenResty image didn't include `pgmoon` — the library that lets Lua talk to PostgreSQL. Package managers didn't work on Alpine (`luarocks` couldn't be found, `opm` required perl which wasn't installed). In the end, pulled it directly from GitHub:

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

- **`access_by_lua_file`** → run this file before every request (token check)
- **`content_by_lua_file`** → if token is valid, this file builds the response
- **`resolver 127.0.0.11`** → Docker's internal DNS server. Nginx can't resolve container names like `"postgres"` to IPs on its own — Docker's DNS knows them. Without this line: `no resolver defined to resolve "postgres"`.

---

## Lua Files

### auth.lua — Token Check

```lua
local token = ngx.req.get_headers()["Authorization"]

if token ~= "secret-token-123" then
    ngx.status = 401
    ngx.say("Unauthorized: Token geçersiz veya eksik")
    ngx.exit(401)
end
```

Reads the token from the `Authorization` header of the incoming request. If it's wrong or missing, returns 401 and stops. If correct, continues — like a security guard at a bank door, no card means no entry.

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

Connects to PostgreSQL, runs `SELECT * FROM users`, returns the result as JSON. Error handling at every step.

### products.lua — MySQL

Same logic, for MySQL. Two differences:
- Different library: `resty.mysql` (built into OpenResty)
- Different connection style: `mysql:new()` then `db:connect({...})` — that's just how this library's API is written

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

Checks if `demo_key` exists in Redis. If not (`ngx.null`), creates it with a 30-second TTL. If it exists, returns it directly — no database call.

First request returns `(yeni oluşturuldu)`, second request doesn't — the data came from Redis cache.

---

## init.sql Files

Docker automatically runs SQL files in `docker-entrypoint-initdb.d` when the container first starts. Without these, tables wouldn't exist and queries would fail.

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

## Test Results

**Without token:**
```bash
curl http://localhost:8080/users
# Unauthorized: Token geçersiz veya eksik
```

**With token — PostgreSQL:**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/users
# [{"name":"Harun","email":"harun@mail.com","id":1},...]
```

**With token — MySQL:**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/products
# [{"name":"Laptop","price":15000,"id":1},...]
```

**With token — Redis (first request):**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/cache
# {"source":"redis","value":"Bu veri Redis cache'den geldi! (yeni oluşturuldu)"}
```

**Redis (second request — served from cache):**
```bash
curl -H "Authorization: secret-token-123" http://localhost:8080/cache
# {"source":"redis","value":"Bu veri Redis cache'den geldi!"}
```

Also tested from outside (`91.151.88.38:8080`) — same results.

---

## Starting the Services

```bash
cd ~/openresty-demo
docker compose up -d
```

To stop:
```bash
docker compose down
```

---

ℹ️ _All tests performed on a real Ubuntu VDS._