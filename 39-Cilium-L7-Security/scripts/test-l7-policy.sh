#!/usr/bin/env bash
# Cilium L7 Network Policy — Doğrulama Testleri
#
# Kullanım:
#   chmod +x test-l7-policy.sh
#   ./test-l7-policy.sh
#
# Önkoşul: lab-setup.yaml ve payment-api-l7-policy.yaml uygulanmış olmalı.

set -euo pipefail
NS="lab-odeme"

echo "=== Test 1: Frontend izinli isteği atıyor (POST /api/v1/charge) ==="
echo "Beklenen: 200"
kubectl exec -n "$NS" frontend -- curl -s -X POST -o /dev/null -w "Sonuc: %{http_code}\n" \
  http://payment-service:8080/api/v1/charge

echo ""
echo "=== Test 2: Frontend yanlış metotla deniyor (GET yerine POST bekleniyor) ==="
echo "Beklenen: 403 (Envoy L7 seviyesinde engelledi)"
kubectl exec -n "$NS" frontend -- curl -s -X GET -o /dev/null -w "Sonuc: %{http_code}\n" \
  http://payment-service:8080/api/v1/charge

echo ""
echo "=== Test 3: Frontend yasaklı path deniyor (/admin) ==="
echo "Beklenen: 403 (Envoy engelledi)"
kubectl exec -n "$NS" frontend -- curl -s -X POST -o /dev/null -w "Sonuc: %{http_code}\n" \
  http://payment-service:8080/admin

echo ""
echo "=== Test 4: payment-api izinli dış hedefe gidiyor (api.github.com) ==="
echo "Beklenen: 200 (SNI dogrulandi, paket disari cikti)"
kubectl exec -n "$NS" payment-api -c client-tools -- curl -s -o /dev/null -w "Sonuc: %{http_code}\n" \
  https://api.github.com

echo ""
echo "=== Test 5: payment-api yasaklı dış hedefe gitmeye çalışıyor (veri kaçırma simülasyonu) ==="
echo "Beklenen: 000 / timeout (SNI'da izinsiz domain, paket disari hic cikamadi)"
kubectl exec -n "$NS" payment-api -c client-tools -- curl -s --max-time 5 -o /dev/null -w "Sonuc: %{http_code}\n" \
  https://www.google.com || echo "Sonuc: timeout (beklenen davranis)"

echo ""
echo "=== Testler tamamlandi ==="