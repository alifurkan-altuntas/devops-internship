#!/usr/bin/env bash
# Hubble Gözlemlenebilirlik Katmanını Etkinleştirme
#
# Hubble, Cilium'un "kör uçuş" sorununu çözen aracı — IP adresleri yerine
# pod kimlikleriyle (identity-aware) canlı trafik akışını gösterir.
#
# Kullanım:
#   chmod +x setup-hubble.sh
#   ./setup-hubble.sh

set -euo pipefail

echo "=== Hubble UI etkinlestiriliyor ==="
cilium hubble enable --ui

echo ""
echo "=== Hubble UI pod/servis durumu kontrol ediliyor ==="
kubectl get pods,svc -n kube-system -l k8s-app=hubble-ui

echo ""
echo "=== cilium status ile dogrulama ==="
cilium status

echo ""
echo "=== Canli akisi terminalden izlemek icin ayri bir terminalde calistir: ==="
echo "  cilium hubble observe --namespace lab-odeme"
echo ""
echo "=== Web arayuzunu acmak icin (baska bir terminalde, acik tut): ==="
echo "  kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 12000:80"
echo "  Sonra taraycidan: http://<vm-ip>:12000"