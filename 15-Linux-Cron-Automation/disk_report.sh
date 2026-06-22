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