# ⚙️ Linux Süreç Yönetimi & Sinyaller

Bu belge, test ortamında süreç izleme, kaynak kullanımı ve sinyal uygulamalarını kapsar.

---

## 1. Kontrolden Çıkan Bir Süreci Simüle Etme ve Sonlandırma

Süreçler bazen aşırı CPU tüketebilir veya kilitlenebilir. Bu laboratuvar, yalnızca yerel araçları kullanarak kaçak bir CPU'ya yüklenmiş süreci yakalayıp sonlandırmayı simüle eder.

### 🛠️ Adımlar

1. **Arka Planda Yüksek Yük Oluşturan Süreç Başlatıldı:**
   Sürekli olarak `/dev/null`'a yazan bir arka plan süreci başlatıldı:

   ```bash
   dd if=/dev/zero of=/dev/null &
   ```

2. **`top` ile Gerçek Zamanlı Kaynak İzleme:**
   `top`, `htop`'un aksine varsayılan olarak her yerde mevcuttur:

   ```bash
   top
   ```

   Gözlem: `dd` bir CPU çekirdeğinin ~%100'ünü kullandığı görüldü.

### 📊 `top` vs `htop` Karşılaştırması

| Özellik                     | `top`                                                                 | `htop`                                                   |
| --------------------------- | --------------------------------------------------------------------- | -------------------------------------------------------- |
| **Sistem Erişilebilirliği** | Her yerde varsayılan olarak mevcut.                                   | Ayrıca kurulması gerekir (`apt`/`dnf install htop`).     |
| **Görsel Arayüz**           | Düz metin, manuel sıralama tuşları (`Shift+P` CPU, `Shift+M` Bellek). | Renkli arayüz, fare desteği, görsel kaynak göstergeleri. |
| **Süreç Ağacı**             | Düz liste; yerleşik ebeveyn/çocuk görünümü yok.                       | Yerleşik ağaç görünümü (`F5`).                           |
| **Kontrol**                 | Sinyaller için PID'yi manuel yazmak gerekir.                          | Süreçleri doğrudan `F9` ile sonlandırabilir.             |

> **Not:** `htop` daha kullanışlı olsa da, bazı kısıtlı sunucularda `htop` kurulu olmayacağından `top` de öğrenilmeli.

---

3. **PID'yi Alma:**
   `ps aux | grep dd`'den daha temiz bir yöntem:

   ```bash
   pidof dd
   ```

4. **Süreci Zorla Sonlandırma (SIGKILL) (`kill -9`):**
   `SIGTERM` (-15) gibi nazik sinyaller yok sayıldığında, `SIGKILL` (-9) ile zorla sonlandırma yapılır:

   ```bash
   kill -9 [Hedef_PID]
   ```

   Doğrulama: `top` veya `pidof dd` yeniden çalıştırıldığında sürecin kaybolduğu görülür.

---

## 🏎️ Süreç Önceliklendirme Yönetimi (`nice` & `renice`)

İşletim sistemi çekirdeği, işlemci saat döngülerini "Nice değerleri" adı verilen göreli öncelik metriğine göre zamanlar. Bu değerler `-20` (en yüksek öncelik) ile `19` (en düşük öncelik) arasında değişir.

### 🛠️ Örnekler

1. **Düşük Öncelikli Süreç Başlatma (`nice`):**
   Aktif servislerle rekabet etmemesi gereken arka plan işleri (örn. yedeklemeler) için:

   ```bash
   nice -n 19 ./report.sh &
   ```

2. **Çalışan Bir Sürecin Önceliğini Değiştirme (`renice`):**
   Yeniden başlatmadan, çalışan bir sürecin önceliğini ayarlamak için:

   ```bash
   sudo renice -n 15 -p 4821
   ```

   Sistem yanıtı: `4821 (process ID) old priority 0, new priority 15`

---

## 📊 Komut Referansı

| Komut        | Amacı                                                     | Örnek                  | Önemli Seçenekler    | Açıklama                                                    |
| ------------ | --------------------------------------------------------- | ---------------------- | -------------------- | ----------------------------------------------------------- |
| **`top`**    | Gerçek zamanlı sistem kaynak izleme.                      | `top`                  | Yerleşik             | Tüm minimal dağıtımlarda standart olarak mevcut.            |
| **`pidof`**  | Bir binary adıyla eşleşen PID'leri döndürür.              | `pidof nginx`          | —                    | Gürültüsüz çıktı, doğrudan PID döndürür.                    |
| **`kill`**   | Hedef süreç ID'sine sinyal gönderir.                      | `kill -9 1432`         | **`-9`** / **`-15`** | `-9` SIGKILL (anlık durdurma); `-15` SIGTERM (nazik çıkış). |
| **`pkill`**  | İsim eşleşmesiyle süreçleri sonlandırır.                  | `pkill dd`             | —                    | Tam isim ile süreçleri bulup sonlandırır.                   |
| **`nice`**   | Özel CPU önceliğiyle yeni süreç başlatır.                 | `nice -n 10 ./task.sh` | **`-n`**             | Çekirdek zamanlama motorunda ağırlığı ayarlar.              |
| **`renice`** | Çalışan bir sürecin önceliğini dinamik olarak değiştirir. | `renice -n -5 -p 221`  | **`-n`** / **`-p`**  | PID ile hedef süreci belirterek anında uygular.             |

---

ℹ️ _Tüm komutlar yerel ortamda test edilmiştir._
