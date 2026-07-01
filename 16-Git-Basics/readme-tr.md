# 🔧 Git — Branch, Merge ve Gerçek Bir Push Çakışması

Bu belge, `git clone`, `git commit`, `git push`, `git branch` ve `git merge` komutlarını — ve bunları bu gerçek repo üzerinde test ederken yaşanan gerçek bir debug sürecini kapsar.

---

## 1. Temel Git İş Akışı

```
Çalışma Dizini → Staging Alanı → Yerel Depo → Uzak (GitHub)
  (dosyaların)     (git add)      (git commit)   (git push)
```

Bu repo, her fazda bu akışı zaten kullanıyordu — bu bölüm ağırlıklı olarak henüz karşılaşılmayan komutları ele alır: `clone`, `branch` ve `merge`.

### `git clone`

Uzak bir reponun tam kopyasını yerel makineye indirir:

```bash
git clone https://github.com/user/repo.git
```

Bu repoda doğrudan kullanılmadı (yerel olarak oluşturulup GitHub'a bağlandı), ama bu repoyu farklı bir makineye çekmek için kullanılacak komut budur.

### `git commit` / `git push`

Bu günlük boyunca zaten düzenli olarak kullanılıyor:

```bash
git add file
git commit -m "mesaj"
git push origin main
```

---

## 2. Branch Alma (Bu Repoda Canlı Test Edildi)

Branch, `main`'den bağımsız, açıkça birleştirilene kadar `main`'i etkilemeyen izole bir çalışma hattıdır.

### Branch oluşturma ve geçiş

```bash
git checkout -b test-branch
```

Tek adımda `test-branch`'i oluşturur ve ona geçer.

### İzolasyonu doğrulama

`test-branch`'te bir dosya (`test-file.txt`) commit edildi. `main`'e geri geçip dosyalar listelendiğinde **dosyanın orada olmadığı** görüldü — iki branch'in birleştirilene kadar bağımsız olduğu kanıtlandı:

```bash
git checkout main
dir
# test-file.txt burada listelenmez
```

### `main`'e geri birleştirme

```bash
git merge test-branch
```

Çıktı:

```text
Updating 64cd35a..f41fc2a
Fast-forward
```

**Fast-forward**, branch oluşturulduğundan beri `main`'in değişmediği anlamına gelir — Git gerçek bir merge commit oluşturmak zorunda kalmadı, sadece `main`'in pointer'ını `test-branch` ile eşleşecek şekilde ilerletti. Sonrasında `test-file.txt` `main`'de de göründü.

### Temizleme

```bash
git branch -d test-branch   # birleştirilmiş branch'i sil
git rm test-file.txt        # test dosyasını kaldır
git commit -m "clean up test branch demo file"
```

---

## 3. Gerçek Sorun: Push Reddedildi, Sonra Takılı Kalan Merge

### Push reddedildi

```bash
git push origin main
```

```text
! [rejected]        main -> main (fetch first)
hint: Updates were rejected because the remote contains work that you do not
have locally.
```

Bu, GitHub'ın `main` kopyasında yerel kopyada olmayan değişiklikler olduğu anlamına geliyordu — muhtemelen bu terminal oturumu dışında yapılan bir şeyden (örn. GitHub web arayüzü veya GitHub Desktop). Standart düzeltme önce pull yapmaktır.

### Pull takıldı

```bash
git pull origin main
```

Bu sefer temiz bir fast-forward yerine, hem yerel hem uzak farklılaşmıştı — Git gerçek bir merge commit oluşturması gerekiyordu, bu da bir commit mesajı gerektiriyor. Git, o mesajı yazmak için yapılandırılmış editörü açmaya çalıştı:

```text
hint: Waiting for your editor to close the file...
"C:\Program Files\JetBrains\WebStorm 2022.2.3\bin\webstorm64.exe": No such file or directory
error: there was a problem with the editor
Not committing merge; use 'git commit' to complete the merge.
```

Yapılandırılmış editör (WebStorm) o yolda kurulu değildi — Git hiçbir şey açamadı ve merge yarım kaldı (değişiklikler alındı ama commit edilmedi).

### Editörü düzeltme ve merge'ü tamamlama

```bash
git config --global core.editor "notepad"
git commit
```

Bu sefer Notepad, otomatik oluşturulmuş bir merge mesajıyla açıldı; kaydedip kapatmak merge'ü tamamladı:

```text
[main e48d7b4] Merge branch 'main' of https://github.com/.../devops-internship
```

`git config --global` yalnızca bu repo için değil, makinedeki her repo için geçerlidir — bu nedenle editör sorununu yalnızca bu repo için değil, ileriye dönük olarak düzeltir.

### Push başarılı oldu

```bash
git push origin main
```

```text
1a7283e..e48d7b4  main -> main
```

---

## 4. Temel Çıkarımlar

- Reddedilen push genellikle uzak reponun yerel repoda olmayan commit'ler içerdiği anlamına gelir — önce `git pull`, sonra tekrar push.
- Her merge basit bir fast-forward değildir — her iki taraf bağımsız olarak değiştiyse, Git gerçek bir merge commit'e (ve bunun için bir mesaja) ihtiyaç duyar.
- Git'in editör ayarı (`core.editor`) göründüğünden daha önemlidir — kurulu olmayan bir şeye işaret ediyorsa, mesaj gerektiren merge/commit işlemleri takılır.
- `git branch` (argümansız) yalnızca mevcut branch'leri **listeler** — bir tane oluşturmaz. Oluşturmak için isim gerekir: `git branch yeni-isim`.

---

## 📊 Komut Referansı

| Komut                                           | Amacı                                                                                      |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **`git clone <url>`**                           | Uzak bir reponun tam kopyasını yerel olarak indirir.                                       |
| **`git branch`**                                | Yerel branch'leri listeler (isim olmadan oluşturmaz).                                      |
| **`git branch <isim>`**                         | Yeni bir branch oluşturur.                                                                 |
| **`git checkout -b <isim>`**                    | Tek adımda yeni branch oluşturur ve geçer.                                                 |
| **`git merge <branch>`**                        | Belirtilen branch'i şu an aktif olan branch'e birleştirir.                                 |
| **`git pull`**                                  | Uzak değişiklikleri getirir ve yerel branch'e birleştirir.                                 |
| **`git push origin main`**                      | `main`'deki yerel commit'leri uzak repoya gönderir.                                        |
| **`git config --global core.editor "notepad"`** | Git'in commit/merge mesajları için kullandığı varsayılan editörü makine genelinde ayarlar. |

---

ℹ️ _Bu reponun geri kalanında branch kullanılmadı — tek kişinin çalıştığı bir öğrenme günlüğünde doğrudan `main`'e commit yapmak basit ve yeterlidir; branch ağırlıklı olarak ekip ortamlarında veya riskli değişiklikleri izole etmek için değer katar._
