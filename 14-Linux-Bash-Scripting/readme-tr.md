# 🐚 Bash Scripting — Değişkenler, Koşullar ve Disk Kullanımı Uyarısı

Bu belge, Bash değişkenlerini, komut yerleştirmeyi, sayısal karşılaştırmaları ve disk kullanımını kontrol edip eşiği aştığında uyaran küçük bir script yazmayı kapsar.

---

## 1. Görev

Disk kullanımını kontrol eden ve %80'i aşarsa uyarı yazdıran bir script yazılacak.

Beklenen çıktı:

```
WARNING: Disk usage is 85%
```

---

## 2. Disk Kullanım Değerini Alma

### Başlangıç noktası: `df -h`

```bash
df -h /
```

Çıktı:

```text
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  9.0G   10G   47% /
```

İhtiyaç duyulan `Use%` sütunudur — ama bu çıktı bir script'te doğrudan kullanılamaz. Yalnızca sayıya indirgemek gerekir.

### Doğru satırı izole etme

Önceki fazlardan hatırlanan `NR==2` kullanımı başlık satırını atlayıp yalnızca veri satırını alır:

```bash
df -h / | awk 'NR==2 {print $5}'
```

Bu, `Use%` sütununun değerini verir, örn. `48%`.

### `%` işaretini kaldırma

```bash
df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1
```

`cut -d'%' -f1`, metni `%` karakterini ayraç olarak kullanarak böler ve ilk parçayı korur — geriye sadece sayı kalır (`48`).

### Değişkende saklama

```bash
usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
```

`$(...)` komut yerleştirmedir — komutu çalıştırır ve çıktısını değişkende saklar. Bash değişkeni atarken `=` etrafında boşluk olmamalıdır (`name = "x"` başarısız olur, `name="x"` çalışır).

---

## 3. Değeri Karşılaştırma

Bash, `[ ]` içinde sayısal karşılaştırmalar için `>` veya `<` kullanmaz — bunun yerine özel flag'ler kullanır:

| Operatör | Anlamı          |
| -------- | --------------- |
| `-gt`    | büyüktür        |
| `-lt`    | küçüktür        |
| `-ge`    | büyük veya eşit |
| `-le`    | küçük veya eşit |
| `-eq`    | eşit            |

```bash
if [ $usage -gt 80 ]; then
    echo "WARNING: Disk usage is ${usage}%"
fi
```

### Yolda karşılaşılan gerçek bir hata

İlk yazımda şu hata üretildi:

```text
./disk_check.sh: line 4: [48: command not found
```

Sebep: `[` ile `$usage` arasındaki eksik boşluk — `[$usage` yerine `[ $usage` yazılması gerekiyordu. Bash'in `[`'i aslında bir komuttur ve doğru tanınması için her iki tarafında boşluk gerekir; boşluk olmadan bash, `[48` adında var olmayan bir komutu çalıştırmaya çalıştı.

Boşluğu eklemek sorunu anında çözdü.

---

## 4. `else` Dalı Ekleme

Her iki durumda da geri bildirim almak için (yalnızca eşiği aştığında değil):

```bash
#!/bin/bash

usage=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)

if [ $usage -gt 80 ]; then
    echo "WARNING: Disk usage is ${usage}%"
else
    echo "OK: Disk usage is ${usage}%"
fi
```

`${usage}%`'deki süslü parantezler her yerde zorunlu değildir, ama değişken adının nerede bittiğini açıkça gösterir — özellikle `%` işaretinden hemen önce görsel olarak karışabilecek durumlarda yararlıdır.

---

## 5. Neden Döngü veya Fonksiyon Yok

Bu görev tek bir değeri bir kez kontrol etmeyi gerektiriyordu — `for` döngüsü veya `function` eklemek bu script için gerçek bir amaca hizmet etmezdi. Her ikisi de gerçek bir tekrarlayan veya yeniden kullanılabilir ihtiyaç olduğunda mantıklıdır (örn. birden fazla mount noktasını kontrol etme veya `cron` ile zamanlanmış çalıştırma) — sadece "her şeyi kullanmak" için zorlamak yapay olurdu.

---

## 📊 Komut Referansı

| Kavram                    | Örnek                    | Amacı                                                          |
| ------------------------- | ------------------------ | -------------------------------------------------------------- |
| **Değişken atama**        | `name="value"`           | `=` etrafında boşluk olmamalı.                                 |
| **Komut yerleştirme**     | `var=$(command)`         | Komutun çıktısını değişkende saklar.                           |
| **`awk 'NR==2'`**         | `awk 'NR==2 {print $5}'` | Belirli bir satırı numarasına göre seçer.                      |
| **`cut -d -f`**           | `cut -d'%' -f1`          | Metni ayraçla böler ve bir alan seçer.                         |
| **Sayısal karşılaştırma** | `[ $a -gt $b ]`          | Bash'in sayı karşılaştırma yöntemi (`-gt`, `-lt`, `-eq`, vb.). |
| **`if`/`else`/`fi`**      | yukarıya bkz.            | Bash koşullu bloğu; `end` değil `fi` ile kapatılır.            |
| **`chmod +x`**            | `chmod +x script.sh`     | Script'in doğrudan çalıştırılabilmesi için execute izni verir. |
| **`./script.sh`**         | `./script.sh`            | Mevcut dizindeki çalıştırılabilir bir script'i çalıştırır.     |

---

ℹ️ _Yerel ortamda test edilmiştir; script yalnızca `/` dizinini kontrol eder — bu görevin kapsamı dışında olduğundan otomatik çalıştırma (örn. `cron` ile) yapılandırılmamıştır._
