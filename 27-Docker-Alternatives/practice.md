# 🐳 Docker Alternatifleri — Uygulamalı Testler

Bu belgede Podman kurulumu ve Docker ile karşılaştırma testleri yapıldı.

---

## 1. Podman Kurulumu

```bash
sudo apt update
sudo apt install -y podman
podman --version
```

```
podman version 4.9.3
```

(Kurulum sonunda bir "Pending kernel upgrade" uyarısı da çıktı — çalışan kernel ile beklenen kernel sürümü farklıydı, sistem yeniden başlatılırsa güncellenecek; testleri etkilemedi.)

Kurulum sırasında `podman.service` ve `podman.socket` gibi systemd birimleri de oluşturuldu — bu, "daemonless" iddiasıyla ilk bakışta çelişiyormuş gibi göründü, bir sonraki testte bunu araştırdık.

---

## 2. Daemonless İddiasının Testi

```bash
systemctl status podman.service
```

```
○ podman.service - Podman API Service
     Active: inactive (dead) since Wed 2026-07-22 11:07:45 UTC; 1min 26s ago
   Duration: 5.216s
TriggeredBy: ● podman.socket
```

```bash
systemctl status podman.socket
```

```
● podman.socket - Podman API Socket
     Active: active (listening) since Wed 2026-07-22 11:07:40 UTC; 2min 38s ago
     Listen: /run/podman/podman.sock (Stream)
```

`podman.service` sadece 5.2 saniye çalışıp durmuş — **socket-activated**, yani sürekli çalışmıyor, sadece bir istek geldiğinde uyanıyor. Docker ile karşılaştırma:

```bash
systemctl status docker
```

```
● docker.service - Docker Application Container Engine
     Active: active (running) since Wed 2026-07-01 07:32:24 UTC; 3 weeks 0 days ago
   Main PID: 958 (dockerd)
      Tasks: 106
     Memory: 235.6M
```

Docker **3 hafta önce** başlamış, hâlâ sürekli çalışıyor (`dockerd`, PID 958). Kanıt için Podman'ın socket'ini tamamen durdurup container çalıştırmayı denedik:

```bash
sudo systemctl stop podman.socket
podman run hello-world
```

```
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Socket kapalıyken bile `podman run` sorunsuz çalıştı — CLI, o servise hiç ihtiyaç duymuyor (servis sadece opsiyonel bir REST API için var).

---

## 3. Rootless İddiasının Testi

Aynı container'ı hem Docker'da hem Podman'da çalıştırıp, **host makinenin** process'i kime ait gördüğüne baktık.

**Docker:**

```bash
docker run -d --name root-test python-good sleep 300
ps aux | grep sleep
```

```
root      385024  1.6  0.0   3012  1788 ?        Ss   11:14   0:00 sleep 300
```

**Podman:** (Docker'ın yerel image deposu Podman'a görünmediği için `docker.io/library/alpine` kullanıldı)

```bash
podman run -d --name root-test-podman docker.io/library/alpine sleep 300
ps aux | grep sleep
```

```
altun     385153  4.7  0.0   1628  1028 ?        Ss   11:15   0:00 sleep 300
```

|                          | Docker   | Podman    |
| ------------------------ | -------- | --------- |
| Container içinde         | root     | root      |
| Host'ta process kime ait | **root** | **altun** |

İkisinde de container içinde `USER` belirtilmediği için root çalışıyor, ama host'un gördüğü kimlik tamamen farklı — Podman **user namespace** ile container'ın root'unu host'ta normal kullanıcıya (`UID mapping`) eşliyor. Container escape durumunda Docker'da host'ta root yetkisi, Podman'da sadece normal kullanıcı yetkisi elde edilir.

```bash
podman rm -f root-test-podman
docker rm -f root-test
```

---

## 4. Build Hızı Testi

İlk denemede Podman **2.2 kat yavaş** çıktı (26.3s vs 11.7s) — ama adil değildi: Docker'ın `python:3.11-slim` katmanı zaten cache'liydi, Podman sıfırdan indiriyordu. Ayrıca Podman varsayılan olarak OCI formatında build ettiği için `HEALTHCHECK is not supported for OCI image format` uyarısı aldık, `--format docker` ile düzeltildi.

Aradan bir engel çıktı: `~/.docker/config.json`'daki eski bir Docker Hub access token'ı Podman tarafından okunup reddedildi (`unauthorized`). `docker logout` ile temizlendi.

Adil bir tekrar test için her iki tarafın image deposu da tamamen sıfırlandı (`docker system prune -af`, `podman rmi -a -f`) — bu arada `docker system prune -af` 3.153GB geri kazandı, sadece durmuş container'ları/kullanılmayan image'ları sildi, çalışan siteler (nginx, openresty) etkilenmedi.

```bash
time docker build --no-cache -f Dockerfile.clean -t python-clean-docker .
# real 1m19.326s

time podman build --no-cache --format docker -f Dockerfile.clean -t python-clean-podman .
# real 1m25.856s
```

**Sonuç: ~%8 fark** — muhtemelen ölçüm gürültüsü, çünkü testler farklı zamanlarda yapıldı ve tek bir layer indirmesi (236MB) tek başına 46.4 saniye sürmüştü, yani sonuç büyük ölçüde o anki network koşullarına bağlıydı.

**Önemli keşif:** Docker ve Podman'ın image depoları **birbirinden tamamen izole** — biri diğerinin cache'ini hiç görmüyor. İlk testte Podman bu yüzden "çok hızlı" görünmüştü, aslında kendi önceki cache'ini kullanmıştı.

---

## 📊 Sonuç Özeti

| Test         | Bulgu                                                                                 |
| ------------ | ------------------------------------------------------------------------------------- |
| Daemonless   | Podman'ın servisi socket-activated, sadece istekte uyanıyor; Docker sürekli aktif     |
| Rootless     | Host'ta Docker container'ı root, Podman container'ı normal kullanıcı olarak görünüyor |
| Build hızı   | ~%8 fark, ölçüm gürültüsü sınırında — ciddi bir performans farkı yok                  |
| Image deposu | Docker ve Podman tamamen izole, birbirinin cache'ini görmüyor                         |

---

ℹ️ _Tüm testler gerçek bir Ubuntu VPS üzerinde yapılmıştır._
