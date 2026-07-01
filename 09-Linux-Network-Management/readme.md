# 🌐 Linux Ağ & Port Yönetimi

Bu belge, DNS sorguları, dinleme portlarını kontrol etme ve TLS sertifikalarını doğrulamayı kapsar.

---

## 1. DNS Çözümlemesi ve Sorun Giderme

### Temel Sorgu

```bash
dig google.com
```

Sistemin yapılandırılmış (yerel) DNS resolver'ını kullanır.

### Yerel Resolver'ı Atlama

```bash
dig @8.8.8.8 google.com
```

Sorguyu doğrudan Google'ın public DNS sunucusuna gönderir, yerel önbelleği ve resolver'ı atlar.

### Gerçek Sorun Giderme Akışı

DNS çözümlemesi başarısız olduğunda, sorunun **nerede** olduğunu bulmak gerekir:

1. **Önce varsayılan resolver'ı, sonra public olanı dene:**

   ```bash
   dig google.com
   dig @8.8.8.8 google.com
   ```

   - İkisi de başarısız → genel ağ/bağlantı sorunu veya domain'in kendisi bozuk.
   - Yalnızca yerel olan başarısız → yerel resolver/DNS yapılandırması sorunlu.

2. **Yerel görünüyorsa, resolver yapılandırmasını kontrol et:**

   ```bash
   cat /etc/resolv.conf
   ```

   Bu dosya, sistemin gerçekten kullandığı `nameserver` girişlerini listeler. Yanlış, güncel olmayan veya erişilemeyen bir IP burada yaygın ve kolayca bulunabilen bir sebeptir.

3. **Saf bağlantı sorununu dışla:**
   ```bash
   ping 8.8.8.8
   ```
   Ham IP de erişilemiyorsa, sorun DNS'e özgü değildir — ağ bağlantısının kendisidir. IP çalışıyor ama domain adları çözümlenemiyorsa, bu DNS katmanına özgü bir sorun olduğunu doğrular.

> 💡 DNS'in derinlemesine işlenmesi (resolver zinciri, kayıt tipleri, TTL, debug araçları) için bkz. [18-Linux-Networking-Fundamentals](../18-Linux-Networking-Fundamentals/).

---

## 2. Dinleme Portlarını Kontrol Etme

```bash
sudo ss -lntp | grep :80
```

### `-l` vs `-a`

| Flag     | Gösterdiği                                                                                                            |
| -------- | --------------------------------------------------------------------------------------------------------------------- |
| **`-l`** | Yalnızca **dinleyen** soketler — bir porta gelen bağlantıları bekleyenler.                                            |
| **`-a`** | Hem dinleyenler **hem de** kurulu bağlantılar — `-l`'nin gösterdiği her şeyi içerir, üstüne aktif bağlantıları ekler. |

"Port X'te ne dinliyor" sorusu için `-l` doğrudan ve yeterli cevaptır:

```bash
sudo ss -lntp | grep :80
```

Çıktı:

```text
LISTEN 0   511   0.0.0.0:80   0.0.0.0:* users:(("nginx",pid=32381,fd=6))
LISTEN 0   511      [::]:80      [::]:* users:(("nginx",pid=32381,fd=7))
```

Nginx (PID 32381)'in hem IPv4 (`0.0.0.0`) hem IPv6 (`[::]`) üzerinde 80 portunu dinlediğini doğrular.

---

## 3. TLS Sertifikası Kontrolü

```bash
openssl s_client -connect example.com:443 -showcerts
```

`Verification: OK` döndürür ve kullanılan TLS versiyonu/şifrelemeyi doğrular (örn. `TLS_AES_256_GCM_SHA384` ile `TLSv1.3`).

### Sertifika Güven Zincirini Anlama

- **`depth=4` (Root CA):** İşletim sistemi tarafından varsayılan olarak güvenilir.
- **`depth=3` / `depth=2` (Ara):** Root'u son sertifikaya bağlar.
- **`depth=1` (Yayımlayan CA):** Bu domain için sertifikayı yayımlar.
- **`depth=0` (Son varlık):** Asıl site.

### Sertifika Geçerliliği

```text
NotBefore: May 31 21:39:12 2026 GMT; NotAfter: Aug 29 21:41:26 2026 GMT
```

Son kullanma tarihinden önce yenilenmezse, ziyaretçiler tarayıcıda sertifika uyarısı görür.

---

## 📊 Komut Referansı

| Araç                       | Protokol Katmanı | Örnek                                | Amacı                                                                                                         |
| -------------------------- | ---------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| **`dig`**                  | UDP / 53         | `dig @8.8.8.8 google.com`            | DNS kayıtlarını sorgular; yerel ve uzak DNS sorunlarını ayırt etmek için belirli bir resolver hedefleyebilir. |
| **`cat /etc/resolv.conf`** | —                | `cat /etc/resolv.conf`               | Sistemin gerçekte hangi DNS sunucularını kullandığını gösterir.                                               |
| **`ss`**                   | TCP/UDP          | `sudo ss -lntp`                      | `-l` yalnızca dinleyen soketleri; `-a` dinleyenler + kurulu bağlantıları gösterir.                            |
| **`openssl s_client`**     | TCP / 443        | `openssl s_client -connect site:443` | TLS sertifikasının geçerliliğini, yayımcısını ve güven zincirini inceler.                                     |
| **`ip`**                   | Katman 3         | `ip a` / `ip route`                  | Arayüzleri, adresleri ve yönlendirme bilgilerini gösterir.                                                    |
| **`ping`**                 | ICMP             | `ping -c 4 8.8.8.8`                  | Ham erişilebilirliği kontrol eder — DNS sorununu bağlantı sorundan ayırt etmek için yararlı.                  |

---

ℹ️ _Tüm komutlar yerel ortamda test edilmiştir._
