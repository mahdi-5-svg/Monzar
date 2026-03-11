#!/bin/bash

echo "جاري تثبيت أداة Monzar Scanner..."

# التأكد من وجود صلاحيات root
if [ "$EUID" -ne 0 ]; then
  echo "الرجاء تشغيل السكربت بصلاحيات root!"
  exit
fi

# تثبيت المتطلبات الضرورية
apt update
apt install -y nmap zenity

# نسخ الأداة إلى /usr/local/bin لتكون متاحة لكل المستخدمين
cp monzar.sh /usr/local/bin/monzar

# إعطاء صلاحية التنفيذ
chmod +x /usr/local/bin/monzar

echo "تم التثبيت بنجاح!"
echo "لتشغيل الأداة، اكتب الأمر: monzar"