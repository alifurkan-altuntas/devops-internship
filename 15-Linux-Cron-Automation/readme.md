# ⏰ Cron & Otomasyon — Disk Raporları, Log Arşivleme ve Tek Seferlik Görevler

Bu belge, `cron` ile tekrarlayan scriptleri zamanlama, `at` ile tek seferlik görevleri zamanlama, ve cron job'ları içinde `sudo` çalıştırırken yaşanan gerçek bir debug sürecini kapsar.

---

## 1. Görev

Her gece şunları yapan bir otomasyon kur:

- Logları arşivler
- Disk kullanım raporu üretir

---

## 2. Crontab Syntax'ı

```
* * * * * komut
│ │ │ │ │
│ │ │ │ └─ Haftanın günü (0-7, 0 ve 7 = Pazar)
│ │ │ └─── Ay (1-12)
│ │ └───── Ayın günü (1-31)
│ └─────── Saat (0-23)
└───────── Dakika (0-59)
```

Alan sırası: **dakika, saat, ayın günü, ay, haftanın günü.**

Her gece saat 02:00'de bir şey çalıştırmak için:

```
0 2 * * *
```

"Ayın günü" ve "haftanın günü" ayrı alanlardır — ikisini de `*` yapmak, ayın/haftanın hangi günü olduğuna bakılmaksızın "her gün" demektir. `0 2 * * 1-5` gibi bir kural, "her hafta içi günü, saat 02:00'de" anlamına gelir.

---

## 3. Disk Kullanım Raporu Scripti

Bash Scripting fazındaki disk kontrol mantığını yeniden kullanır, ama sonucu ekrana yazdırmak yerine bir dosyaya yazar — çünkü cron arka planda çalışır, ekranı izleyen kimse yoktur.

```bash
#!/bin/bash

today=$(date +%Y-%m-%d)
usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

mkdir -p ~/disk_reports
report_file="$HOME/disk_reports/disk_report_$today.txt"

if [ $usage -gt 80 ]; then
    echo "WARNING: Disk usage is ${usage}% on $today" > $report_file
else
    echo "OK: Disk usage is ${usage}% on $today" > $report_file
fi

echo "Report saved to $report_file"
```

Bu, cron altında hemen sorunsuz çalıştı — hiçbir yerde `sudo` kullanılmadı, çünkü hem disk kullanımını okumak hem de kullanıcının kendi home dizinine yazmak, normal kullanıcı izinleri içinde kalıyor.

---

## 4. Log Arşivleme Scripti (ve Gerçek Debug Süreci)

### Hedef

Nginx'in `access.log`'unu sıkıştır, tarih damgalı bir isimle bir arşiv klasörüne kaydet, sonra orijinal log dosyasını boşalt ki Nginx ona yazmaya devam edebilsin.

### İlk Versiyon

```bash
#!/bin/bash

today=$(date +%Y-%m-%d)
mkdir -p ~/nginx_archive

gzip -c /var/log/nginx/access.log > ~/nginx_archive/access-$today.log.gz
sudo truncate -s 0 /var/log/nginx/access.log

echo "Log archived as access-$today.log.gz"
```

Önemli parçalar:

- **`gzip -c`**: dosyayı sıkıştırır ama çıktıyı orijinal dosyanın yerine yazmak yerine stdout'a gönderir. `-c` olmadan, sade `gzip dosya` komutu, orijinali sıkıştırıp **siler** — burada istediğimiz şey bu değil, çünkü Nginx hâlâ o dosyaya yazıyor olabilir, ayrıca özel bir isim/konum istiyoruz.
- **`truncate -s 0`**: dosyayı silmeden, boyutunu 0 byte'a indirir. Bu önemli, çünkü dosyayı doğrudan silmek (`rm`), Nginx'in açık dosya tanıtıcısını bozabilir — `truncate`, dosya referansını sağlam tutar, sadece içeriği boşaltır.

### Sorun 1: Yönlendirmede İzin Hatası

`sudo gzip -c dosya > arsiv/dosya.gz` çalıştırmak "Permission denied" hatası verdi, çünkü `sudo` sadece `gzip` komutuna uygulanıyor — `>` yönlendirmesinin kendisi, **root'un değil, mevcut kullanıcının** izinleriyle çalışıyor. Log'u okumanın hiç `sudo` gerektirmediği anlaşıldığı için, bu satırdan `sudo`'yu kaldırarak sorun tamamen önlendi (`cat /var/log/nginx/access.log`, `sudo` olmadan çalıştı).

### Sorun 2: `chmod: Operation not permitted`

```text
chmod: 'archive_logs.sh' ögesinin erişim izinleri değiştiriliyor: İşleme izin verilmedi
```

Sebep: scriptin dosyası `root`'a aitti — muhtemelen bir noktada `sudo nano` ile açıldığı için. Şununla düzeltildi:

```bash
sudo chown altun:altun archive_logs.sh
```

### Sorun 3: Script Cron Altında "Başarılı" Oldu Ama Hiçbir Şey Yapmadı

Cron logları (`/var/log/syslog`, `grep -a CRON` ile filtrelenerek) scriptin tetiklendiğini ve "Log archived..." yazdırdığını gösteriyordu — ama arşiv dosyası fiilen boş/içeriksizdi. Scriptin gerçek çıktısını bir debug dosyasına yönlendirmek, asıl hatayı ortaya çıkardı:

```bash
* * * * * /home/altun/archive_logs.sh >> /home/altun/cron_debug.log 2>&1
```

```text
sudo: a password is required
```

**Kök sebep:** `sudo`, şifre sormak için interaktif bir terminal gerektirir. Cron interaktif olmayan bir şekilde çalışır — şifre girecek kimse yoktur — bu yüzden script içindeki her `sudo` komutu sessizce başarısız oldu. Script, son `echo` satırını yine de yazdırdı çünkü o kısım `sudo`'nun başarılı olmasına bağlı değildi.

Bu hata ilk başta görünmedi çünkü cron, varsayılan olarak komut çıktısını e-posta ile göndermeye çalışır, ve hiçbir mail sistemi (MTA) kurulu olmadığı için, bu çıktı (hata dahil) sessizce göz ardı edildi — `journalctl`'da `"No MTA installed, discarding output"` olarak görünüyordu.

### Çözüm: Dar Kapsamlı Bir `sudoers` Kuralı

Geniş bir `sudo` yetkisi vermek yerine, gerçekten root gerektiren **tek komut** (`www-data`'ya ait bir dosyayı boşaltmak) için bir kural eklendi:

```bash
sudo visudo
```

```text
altun ALL=(ALL) NOPASSWD: /usr/bin/truncate -s 0 /var/log/nginx/access.log
```

Bu, önceki fazlardaki Least Privilege (En Düşük Yetki) prensibini takip ediyor — sadece o tam komut, o tam path ile, şifresiz erişim alıyor. Daha geniş bir yetki yok.

### Son Çalışan Versiyon

```bash
#!/bin/bash

today=$(date +%Y-%m-%d)
mkdir -p ~/nginx_archive

gzip -c /var/log/nginx/access.log > ~/nginx_archive/access-$today.log.gz
sudo truncate -s 0 /var/log/nginx/access.log

echo "Log archived as access-$today.log.gz"
```

`sudoers` düzeltmesinden sonra, bu hem elle çalıştırıldığında hem de cron altında, hiçbir şifre sormadan çalıştı.

---

## 5. Yan Not: `logrotate`

Gerçek production ortamlarında, Nginx zaten kendi log rotasyon mekanizmasını `logrotate` (`/etc/logrotate.d/nginx`) üzerinden sağlıyor — bu, root olarak her gün çalışır ve tam olarak bu işi (sıkıştırma, rotasyon, doğru sahiplikle dosyayı yeniden oluşturma) yapar:

```text
/var/log/nginx/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 www-data adm
    sharedscripts
    postrotate
        invoke-rc.d nginx rotate >/dev/null 2>&1
    endscript
}
```

Yukarıdaki özel script bu görev için kurulup düzeltilmiş olsa da, bunu anlamak değerli — gerçek bir kurulumda, zaten var olan bu mekanizma sıfırdan yeniden icat edilmez.

---

## 6. İki Scripti Zamanlama

```bash
crontab -e
```

```
0 2 * * * /home/altun/archive_logs.sh
0 2 * * * /home/altun/disk_report.sh
```

İkisi de her gece saat 02:00'de çalışır. Şununla doğrulandı:

```bash
crontab -l
```

---

## 7. `at` ile Tek Seferlik Zamanlama

`cron`, **tekrarlayan** görevler için. `at` ise, gelecekte **tam olarak bir kez** çalışması gereken bir şey için — tekrarlayan bir zamanlamaya gerek yok.

### `at`'ı Kurma ve Etkinleştirme

Bu sunucuda varsayılan olarak kurulu değil:

```bash
sudo apt install at -y
sudo systemctl enable --now atd
```

`atd`, `at` görevlerini gerçekten çalıştıran arka plan servisidir — kavramsal olarak `crond`'un cron için oynadığı rolün aynısı.

### Tek Seferlik Bir Görev Zamanlama

```bash
echo "echo Merhaba > /home/altun/at_test.txt" | at now + 1 minute
```

Bu, komutu şu andan 1 dakika sonra, tek seferlik çalışacak şekilde zamanlar.

### Bekleyen Görevleri Kontrol Etme

```bash
atq
```

**Önemli:** `atq`, sadece hâlâ **bekleyen** görevleri listeler. Bir görev gerçekten çalıştığında, `atq`'dan kaybolur — bu, başarısız olduğu anlamına gelmez, tamamlandığı anlamına gelir. Bir görevin gerçekten çalıştığını doğrulamanın asıl yolu, gerçek sonucunu kontrol etmektir:

```bash
cat /home/altun/at_test.txt
```

Bu doğrudan yaşandı: zamanlanmış saati geçtikten sonra bir görev `atq`'da "kaybolmuş" gibi göründü, ama çıktı dosyası görevin gerçekten başarıyla çalıştığını doğruladı — `atq`'nun boşalması beklenen bir davranıştı, bir hata değil.

### Bekleyen Bir Görevi İptal Etme

```bash
atrm <görev_numarası>
```

`atq`'nun gösterdiği görev numarasını kullanır.

---

## 📊 Komut Referansı

| Komut                                 | Amaç                                                                                           |
| ------------------------------------- | ---------------------------------------------------------------------------------------------- |
| **`crontab -e`**                      | Mevcut kullanıcının cron görevlerini düzenle.                                                  |
| **`crontab -l`**                      | Mevcut kullanıcının zamanlanmış cron görevlerini listele.                                      |
| **`gzip -c dosya > cikti.gz`**        | Orijinali silmeden/değiştirmeden sıkıştır.                                                     |
| **`truncate -s 0 dosya`**             | Dosyayı silmeden, boyutunu 0'a indir.                                                          |
| **`sudo visudo`**                     | Sudoers kurallarını güvenli şekilde düzenle (kaydetmeden önce syntax kontrolü yapar).          |
| **`NOPASSWD:`**                       | Belirli bir komutun, şifre sorulmadan `sudo` ile çalışmasına izin verir.                       |
| **`chown kullanici:kullanici dosya`** | Dosya sahipliğini değiştirir — bir dosya yanlışlıkla `root` olarak oluşturulduğunda gerekir.   |
| **`journalctl -u cron`**              | Bir görevin neden beklenmedik davrandığını debug etmek için cron'un kendi loglarını görüntüle. |
| **`at now + <süre>`**                 | Gelecekte bir noktada çalışacak tek seferlik bir komut zamanlar.                               |
| **`atq`**                             | Bekleyen (henüz çalışmamış) `at` görevlerini listeler.                                         |
| **`atrm <görev_numarası>`**           | Bekleyen bir `at` görevini iptal eder.                                                         |

---

ℹ️ _Buradaki gerçek ders, scriptlerin kendisi değildi — ikisi de oldukça basitti — ama elle çalıştığında çalışan bir şeyin, otomatikleştirildiğinde neden sessizce başarısız olduğunu debug etmek, ve cron'un interaktif olmayan doğasının bunu nasıl bozduğunu öğrenmekti. `at` ile de aynı ruh: görev gerçekte başarısız olmadı, sadece yanlış yerden kontrol edilince "kaybolmuş" gibi göründü._
