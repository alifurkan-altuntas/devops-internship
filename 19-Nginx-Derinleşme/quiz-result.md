# 📊 Faz 19 & 20 Quiz Sonuçları — Nginx Derinleşme, Rate Limiting & Load Balancing

**Tarih:** 6 Temmuz 2026
**Skor:** 15/15 ✅

---

**1. Reverse proxy nedir, ne işe yarar?**

**Cevap:** Dışardan gelen isteklerin içeriyi bilmeden cevaplanmasını sağlar — kullanıcı backend'in varlığından, porttan, yapıdan hiç haberdar olmaz. ✅

---

**2. `proxy_pass http://localhost:3000` ile `proxy_pass http://localhost:3000/` arasındaki fark nedir?**

**Cevap:** `/` olup olmaması dosyanın içine girilip girilmeyeceğini belirler. Slash olmadan path olduğu gibi iletilir, slash ile path prefix'i soyulur. ✅

---

**3. `proxy_set_header X-Real-IP $remote_addr` neden kullanılır, olmasa ne olur?**

**Cevap:** Dışarıdan gelenin IP'sinin tutulmasını ve içeriye giden bilgiyle gönderilmesini sağlar. Olmasa backend her isteğin Nginx'ten (`127.0.0.1`) geldiğini sanır, kimin istediği bilinemez. ✅

---

**4. `access_by_lua_file` ile `content_by_lua_file` farkı nedir?**

**Cevap:** `access_by_lua_file` erişmek için bu dosyadaki komutu çalıştır ve kontrolü yap der. `content_by_lua_file` ise erişim yetkisi varsa cevabı bu dosya ile üret der. ✅

---

**5. `deny all` ile `return 403` birlikte kullanınca ne oldu, neden?**

**Cevap:** `deny all` local dışında herkesi engelliyordu, ama `return 403` de eklenince local de 403 gelmeye başladı. Çünkü `deny all` zaten 403 döndürür, ikisi birlikte çakışıyor. `return 403` kaldırılınca düzeldi. ✅

---

**6. Forward proxy ile reverse proxy arasındaki fark nedir?**

**Cevap:** Forward proxy client tarafında olur ve client'ı gizler. Reverse proxy ise sunucunun önünde olur ve onu gizler. ✅

---

**7. Squid ile forward proxy test ederken Windows'ta ne gördün?**

**Cevap:** Proxy ile bağlandığım sunucunun IP'sini gördüm — kendi gerçek IP'm değil, Squid'in IP'si göründü. ✅

---

**8. `allow 127.0.0.1` yazmasına rağmen neden localhost'tan 403 geldi?**

**Cevap:** Ubuntu IPv6 protokolü kullandı, IPv4 değil. `localhost` yazınca `::1` olarak çözümlüyor, `127.0.0.1` olarak değil. Nginx bunları ayrı adres olarak görüyor, bu yüzden `allow ::1` de eklemek gerekti. ✅

---

**9. 301 Moved Permanently ne zaman geliyor, neden?**

**Cevap:** `/` yazılmadığı zaman geliyor, içeri girilmediği için. `location /users/` tanımlı olduğunda, trailing slash olmadan `/users` yazılınca Nginx otomatik yönlendiriyor. ✅

---

**10. `resolver 127.0.0.11` neden gerekli?**

**Cevap:** Docker'lar arasında IP çözümü ile iletişim için gerekli. Nginx container isimlerini IP'ye çeviremez, bu satır olmadan `no resolver defined to resolve "postgres"` hatası geliyor. ✅

---

**11. 502 Bad Gateway ne zaman gelir?**

**Cevap:** Port kapalı olduğu zaman — daha geniş ifadeyle, Nginx çalışıyor ama arkasındaki backend'e ulaşamıyor. ✅

---

**12. Rate limiting'de `burst` ve `nodelay` ne işe yarıyor?**

**Cevap:** `burst` art arda gelen istekleri tolere edebilmek için, `nodelay` ise o isteklerin hemen işleme alınması için. ✅

---

**13. Load balancing'de round-robin nasıl çalışır?**

**Cevap:** Yükü dağıtmak için yönlendirme yapar — istekleri sırayla dağıtır, ilk istek 3000'e, ikinci 3001'e, üçüncü 3000'e. ✅

---

**14. Failover testinde Instance 1'i kapattığında ne oldu?**

**Cevap:** Her şey Instance 2'ye yöneldi — Nginx otomatik olarak çalışan instance'a geçti, hiç kesinti olmadı. ✅

---

**15. `least_conn` ve `ip_hash` ne zaman kullanılır?**

**Cevap:** `least_conn` round-robin'in adaletsiz olduğu yerlerde kullanılır. `ip_hash` ise aynı IP'nin sürekli aynı sunucuya yönlendirilmesini sağlar — session bilgisi backend'de tutulan uygulamalarda gerekli. ✅

---

ℹ️ _Tüm cevaplar geri dönüp düzeltme yapılmadan verilmiştir._
