# 🏗️ Linux Servis & Log Yönetimi (`systemd` Mimarisi)

Bu belge, systemd servis yönetimi, journalctl ve önemli Linux dağıtımlarındaki varsayılan davranışları kapsar.

---

## 1. Servis Yaşam Döngüsü & Log Denetimi

Uygulamalar, web sunucuları ve veritabanları genellikle `systemd` (PID 1) altında arka plan servisi olarak çalışır. Bu bölümde Nginx kurulumu ve servis durumları ele alınır.

### 🛠️ Adımlar

1. **Nginx Kurulumu (Farklı Paket Yöneticileri):**
   - **RHEL / Rocky Linux (DNF):**
     ```bash
     sudo dnf install nginx -y
     ```
   - **Debian / Ubuntu (APT):**
     ```bash
     sudo apt install nginx -y
     ```

2. **Başlangıç Durumu Kontrolü:**

   ```bash
   systemctl status nginx
   ```

   - **RHEL/Rocky Linux çıktısı:** Varsayılan olarak devre dışı. `Loaded: ...; disabled; ...` ve `Active: inactive (dead)` olarak görünür.
   - **Ubuntu çıktısı:** Kurulumdan hemen sonra otomatik olarak etkinleştirilir ve başlatılır.

3. **Servisi Etkinleştirme ve Başlatma:**

   ```bash
   sudo systemctl enable nginx
   sudo systemctl start nginx
   ```

   Doğrulama: `systemctl status nginx` artık `Active: active (running)` ve `Enabled` gösterir.

4. **Durdurma, Yeniden Başlatma, Yeniden Yükleme:**

   ```bash
   sudo systemctl stop nginx       # servisi durdur
   sudo systemctl restart nginx    # durdur ve yeniden başlat (kısa kesinti)
   sudo systemctl reload nginx     # aktif bağlantıları kesmeden yapılandırmayı yeniden yükle (sıfır kesinti)
   ```

---

## 2. `journalctl` ile Log Görüntüleme

Loglar, düz metin dosyaları yerine `journalctl` ile görüntülenir. İki flag, bunu gerçek anlamda kullanışlı hale getirir: **`-p`** (öncelik/ciddiyet) ve **`--since`** (zaman aralığı).

### Temel Kullanım

```bash
journalctl -u nginx          # servis için tam log geçmişi
journalctl -u nginx -f       # yeni log girişlerini canlı takip et
```

### Ciddiyet Seviyesine Göre Filtreleme (`-p`)

Systemd loglarının ciddiyet seviyeleri, en kritikten en az kritike doğru:

| Seviye    | Anlamı                |
| --------- | --------------------- |
| `emerg`   | Sistem kullanılamaz   |
| `alert`   | Acil müdahale gerekli |
| `crit`    | Kritik durum          |
| `err`     | Hata                  |
| `warning` | Uyarı                 |
| `notice`  | Normal ama önemli     |
| `info`    | Bilgilendirici        |
| `debug`   | Debug detayı          |

`-p` belirtilen seviyeyi **ve daha ciddi olanları** filtreler. Yani:

```bash
journalctl -u nginx -p err
```

`err`, `crit`, `alert` ve `emerg` girişlerini gösterir — `warning` veya altını değil. Rutin gürültüyü keser, yalnızca gerçekten önemli olanları gösterir.

### Zamana Göre Filtreleme (`--since`, `--until`)

```bash
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx --since "2026-06-22 14:00:00" --until "2026-06-22 15:00:00"
```

`--since` hem göreli ("1 hour ago", "yesterday") hem de mutlak zaman damgaları kabul eder.

### İkisini Birlikte Kullanma — Gerçek Bir Troubleshooting Senaryosu

Nginx'in sorunlu olduğu raporlanıyor ve hedef "son bir saatte ne yanlış gitti":

```bash
journalctl -u nginx -p err --since "1 hour ago"
```

Bu: _"Son bir saat içinde Nginx için yalnızca hata seviyesindeki veya daha ciddi logları göster"_ anlamına gelir — alakasız log geçmişini kaydırarak önemli satırı bulmak yerine, doğrudan sonuca gidilir.

---

## 📊 Komut Referansı

| Komut                    | Amacı                                                | Örnek                             | Notlar                                                             |
| ------------------------ | ---------------------------------------------------- | --------------------------------- | ------------------------------------------------------------------ |
| **`systemctl start`**    | Servisi şimdi başlatır.                              | `sudo systemctl start nginx`      | Yeniden başlatmada kalıcı değildir.                                |
| **`systemctl enable`**   | Servisi önyüklemede başlatacak şekilde ayarlar.      | `sudo systemctl enable nginx`     | `start`'tan ayrı bir kalıcılık ayarı.                              |
| **`systemctl stop`**     | Çalışan servisi durdurur.                            | `sudo systemctl stop nginx`       |                                                                    |
| **`systemctl restart`**  | Servisi durdurur ve yeniden başlatır (kısa kesinti). | `sudo systemctl restart nginx`    |                                                                    |
| **`systemctl reload`**   | Kesinti olmadan yapılandırmayı yeniden yükler.       | `sudo systemctl reload nginx`     | Tüm servisler bunu desteklemez.                                    |
| **`journalctl -u`**      | Belirli bir birim için logları gösterir.             | `journalctl -u nginx`             |                                                                    |
| **`journalctl -p`**      | Logları ciddiyet seviyesine göre filtreler.          | `journalctl -u nginx -p err`      | Seviyeleri: emerg, alert, crit, err, warning, notice, info, debug. |
| **`journalctl --since`** | Logları zaman aralığına göre filtreler.              | `journalctl --since "1 hour ago"` | Göreli veya mutlak zaman damgası kabul eder.                       |
| **`journalctl -f`**      | Yeni log girişlerini canlı takip eder.               | `journalctl -u nginx -f`          |                                                                    |

---

ℹ️ _Tüm komutlar yerel ortamda test edilmiştir._
