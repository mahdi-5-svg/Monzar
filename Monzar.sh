#!/bin/bash

# طلب وتجديد صلاحيات الجزر (Root)
sudo -v || exit
echo "تم الحصول على صلاحيات sudo"
command -v nmap >/dev/null || { zenity --error --text="Nmap not installed"; exit 1; }

# دالة التعامل مع الأخطاء والإلغاء
ex(){
    status=$1   
    if [ $status -ne 0 ]; then
        zenity --info --text='تم إنهاء البرنامج أو إلغاء العملية' --timeout=2
        exit
    fi
}

zenity --info --title="الترحيب" --text="مرحبا بك في Monzar"

# قائمة الفحص (تم تنظيف المسافات الزائدة)
ent=$(zenity --width=800 --height=600 --list \
    --title="نوع الفحص" \
    --column='الخيارات' \
    'اكتشاف الأجهزة في الشبكة' \
    'فحص أشهر البورتات في جهاز' \
    'فحص جميع البورتات' \
    'فحص بورت معين' \
    'معرفة الخدمات والإصدارات' \
    'معرفة نظام التشغيل' \
    'فحص سريع' \
    'فحص خفي SYN' \
    'فحص UDP' \
    'عرض البورتات المفتوحة فقط' \
    'تشغيل سكربتات اكتشاف الثغرات' \
    'اكتشاف معلومات HTTP' \
    'معرفة معلومات SSH' \
    'اكتشاف DNS' \
    'فحص قوي وشامل' \
    'فحص احترافي شامل'
)
ex $?

# طلب عنوان الهدف (وإلغاء السكربت إذا كان فارغاً)
IP=$(zenity --entry --title="العنوان" --text="ادخل عنوان IP أو URL")
ex $?
if [ -z "$IP" ]; then
    zenity --error --text="لم تقم بإدخال عنوان صالح!"
    exit 1
fi

# طلب البورت إذا اختار المستخدم فحص بورت معين
if [ "$ent" = "فحص بورت معين" ]; then
    port=$(zenity --entry --title='المنفذ' --text='ادخل رقم المنفذ')
    ex $?
fi

# تحديد الـ Flags بدلاً من كتابة الأمر كاملاً لتجنب مشاكل التنفيذ
case "$ent" in 
    "اكتشاف الأجهزة في الشبكة") flags="-sn" ;;
    "فحص أشهر البورتات في جهاز") flags="" ;;
    "فحص جميع البورتات") flags="-p-" ;;
    "فحص بورت معين") flags="-p $port" ;;
    "معرفة الخدمات والإصدارات") flags="-sV" ;;
    "معرفة نظام التشغيل") flags="-O" ;;
    "فحص سريع") flags="-F" ;;
    "فحص خفي SYN") flags="-sS" ;;
    "فحص UDP") flags="-sU" ;;
    "عرض البورتات المفتوحة فقط") flags="--open" ;;
    "تشغيل سكربتات اكتشاف الثغرات") flags="--script vuln" ;;
    "اكتشاف معلومات HTTP") flags="--script http-title" ;;
    "معرفة معلومات SSH") flags="--script ssh-hostkey" ;;
    "اكتشاف DNS") flags="--script dns-brute" ;;
    "فحص قوي وشامل") flags="-A" ;;
    "فحص احترافي شامل") flags="-sS -sV -O -p- -T4" ;;
esac

# سؤال المستخدم عن حفظ النتيجة
zenity --question --text='هل تريد حفظ النتيجة في ملف؟'
save=$?

tmpfile=$(mktemp)

# تشغيل الفحص في الخلفية مع وضع علامات تنصيص للـ IP لحمايته من حقن الأوامر
# نستخدم sudo لضمان عمل الفحوصات العميقة مثل -sS و -O
sudo nmap $flags "$IP" > "$tmpfile" &
pid=$!

# دائرة التحميل اللطيفة
(
while kill -0 $pid 2>/dev/null
do
    echo "# جاري دك حصون الهدف..."
    sleep 1
done
) | zenity --progress \
--title="Monzar Scanner" \
--text="جاري فحص الهدف..." \
--pulsate \
--auto-close

result=$(cat "$tmpfile")

# حفظ النتيجة في حال وافق المستخدم
if [ "$save" -eq 0 ]; then
    file=$(zenity --file-selection --save --confirm-overwrite)
    if [ -n "$file" ]; then
        echo "$result" > "$file"
        zenity --info --text="تم حفظ التقرير بنجاح!"
    fi
fi

# عرض النتيجة وحذف الملف المؤقت
zenity --text-info --width=800 --height=600 --title="نتيجة فحص Monzar" --filename="$tmpfile"
rm "$tmpfile"