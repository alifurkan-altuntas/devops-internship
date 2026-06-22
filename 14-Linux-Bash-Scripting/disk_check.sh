#!binbash
usage=$(df -h   awk 'NR==2 {print $5}'  cut -d'%' -f1)

if [ $usage -gt 80 ]; then

echo Warning Disk usage is ${usage}%
else
echo OK Disk usage is ${usage}%
fi