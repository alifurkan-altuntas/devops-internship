#!/bin/bash
echo "=========================================="
echo "         Host Report         "
echo "=========================================="
echo -n "1. HostName:                 "
hostname
echo -n "2. Ip Address:               "
hostname -I
echo -n "3. System Information:       "
cat /etc/os-release | grep "PRETTY_NAME" | cut -d '=' -f 2 | tr -d '"'
echo "Disk Information:"
df -h / | awk 'NR==2 {print "Toplam: " $2 " | Kullanilan: " $3 " | Bos: " $4}'
echo "=========================================="