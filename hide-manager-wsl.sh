#!/usr/bin/env bash
#
# إخفاء تطبيق مدير الروت (ReSukiSU / KernelSU) عن أدوات الكشف
#                         نسخة WSL  +  adb
#
# الفكرة: نأخذ APK المدير، نعيد بناءه باسم باكدج عشوائي واسم عرض عام،
# نوقّعه بمفتاح جديد، نركّبه، ثم نُسجّل توقيعه في الكيرنل عبر
# Dynamic Manager Configuration، وأخيرًا نحذف المدير الأصلي.
#
# الاستخدام:  bash hide-manager-wsl.sh
#
set -uo pipefail

# ================= عدّل دول بس =================
OLD_PKG="auto"                       # اسم باكدج المدير الحالي، أو "auto" للكشف التلقائي
NEW_PKG="com.android.system.update"  # الباكدج الجديد (خلّيه يبان رسمي وعادي)
NEW_LABEL="System Update"            # اسم التطبيق اللي هيظهر على الشاشة
# ==============================================

WORK="$HOME/ksu-manager-hide"
ADB="adb"
KSUD="/data/adb/ksu/bin/ksud"

say()  { printf "\n\033[1;36m>> %s\033[0m\n" "$*"; }
warn() { printf "\n\033[1;33m!! %s\033[0m\n" "$*"; }
die()  { printf "\n\033[1;31mXX %s\033[0m\n" "$*"; exit 1; }

# ---------------------------------------------------------------- 1) الأدوات
say "1/9  تثبيت الأدوات المطلوبة"
if ! command -v java >/dev/null; then
  sudo apt update && sudo apt install -y openjdk-17-jre-headless
fi
if ! command -v adb >/dev/null; then
  sudo apt install -y adb
fi
mkdir -p "$WORK/dl" "$WORK/apk"
cd "$WORK"

[ -f dl/apktool.jar ] || curl -L -o dl/apktool.jar \
  "https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar"
[ -f dl/uber-apk-signer.jar ] || curl -L -o dl/uber-apk-signer.jar \
  "https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar"

# ---------------------------------------------------------------- 2) الموبايل
say "2/9  توصيل الموبايل"
adb start-server >/dev/null 2>&1
adb devices
adb shell true >/dev/null 2>&1 || die "الموبايل مش موصول. شغّل USB debugging واعمل adb devices."

# ------------------------------------------------- 3) كشف باكدج المدير تلقائي
if [ "$OLD_PKG" = "auto" ]; then
  say "3/9  بشوف باكدج المدير"
  for c in com.resukisu.resukisu me.weishu.kernelsu com.rifsxd.ksunext com.sukisu.ultra; do
    if adb shell pm list packages | tr -d '\r' | grep -qx "package:$c"; then OLD_PKG="$c"; break; fi
  done
  if [ "$OLD_PKG" = "auto" ]; then
    warn "مالقيتش باكدج مدير معروف. دي قائمة الاحتمالات:"
    adb shell pm list packages | tr -d '\r' | grep -Ei "kernelsu|resukisu|sukisu|ksunext|kitsune|apatch" || true
    die "اكتب اسم الباكدج في OLD_PKG فوق وشغّل السكربت تاني."
  fi
fi
echo "    المدير الحالي: $OLD_PKG"
echo "    الجديد:        $NEW_PKG  ($NEW_LABEL)"

# ---------------------------------------------------------------- 4) سحب APK
say "4/9  سحب APK المدير"
APK_PATH="$(adb shell pm path "$OLD_PKG" | sed -n '1s/package://p' | tr -d '\r')"
[ -n "$APK_PATH" ] || die "مش قادر أجيب مسار APK"
echo "    $APK_PATH"
adb pull "$APK_PATH" apk/manager.apk >/dev/null || die "فشل سحب الـ APK"
echo "    تم النسخ الاحتياطي في $WORK/apk/manager.apk"

# ------------------------------------------------------- 5) فك + تغيير الهوية
say "5/9  فك الـ APK وتغيير الباكدج والاسم"
rm -rf apk/src
java -jar dl/apktool.jar d -f apk/manager.apk -o apk/src >/dev/null || die "فشل apktool d"
python3 - "$NEW_PKG" "$NEW_LABEL" <<'PY'
import re, sys
newpkg, newlabel = sys.argv[1], sys.argv[2]
p = "apk/src/AndroidManifest.xml"
s = open(p, encoding="utf-8").read()
s2 = re.sub(r'package="[^"]*"', f'package="{newpkg}"', s, count=1)
if s2 == s:
    sys.exit("ما قدرتش ألاقي خاصية package في المانيفست")
s = s2
s2 = re.sub(r'(<application\b[^>]*?android:label=")[^"]*"', lambda m: m.group(1) + newlabel + '"', s, count=1)
if s2 == s:
    print("تنبيه: الاسم الظاهر سايبه زي ما هو")
else:
    s = s2
open(p, "w", encoding="utf-8").write(s)
print("    المانيفست اتعدّل")
PY

# ---------------------------------------------------------------- 6) إعادة بناء
say "6/9  إعادة البناء والتوقيع"
java -jar dl/apktool.jar b apk/src -o apk/manager_new.apk >/dev/null || die "فشل apktool b"
rm -rf apk/signed && mkdir -p apk/signed
java -jar dl/uber-apk-signer.jar --apk apk/manager_new.apk --out apk/signed >/dev/null || die "فشل التوقيع"
SIGNED="$(ls apk/signed/*Signed.apk 2>/dev/null | head -1)"
[ -n "$SIGNED" ] || die "مش لاقي الـ APK الموقّع"
echo "    $SIGNED"

# ---------------------------------------------------------------- 7) التركيب
say "7/9  تركيب النسخة الجديدة"
adb install -r "$SIGNED" || die "فشل التركيب"
NEW_PATH="$(adb shell pm path "$NEW_PKG" | sed -n '1s/package://p' | tr -d '\r')"
echo "    اتركّب في: $NEW_PATH"

# ------------------------------------------- 8) تسجيل التوقيع في الكيرنل
say "8/9  تسجيل التوقيع الجديد في الكيرنل (Dynamic Manager)"
adb shell "su -c '$KSUD kernel dynamic-manager set-apk $NEW_PATH'"
adb shell "su -c '$KSUD kernel dynamic-manager get --internal true'"

warn "دلوقتي افتح تطبيق \"$NEW_LABEL\" على الموبايل وتأكد إنه شغّال وبيطلّع شاشة الروت."
read -r -p "لو التطبيق شغّال تمام اكتب yes للمتابعة وحذف المدير القديم: " ok
if [ "$ok" = "yes" ]; then
  say "9/9  حذف المدير القديم + ريستارت"
  adb uninstall "$OLD_PKG" || warn "فشل حذف المدير القديم — احذفه يدويًا"
  adb reboot
  echo
  echo "خلص. بعد الريستارت: اتأكد بالـ Kknd إن Root Manager Apps مابقاش FOUND."
else
  warn "اتوقفت من غير حذف. المدير القديم لسه موجود."
fi

echo
echo "لو حصلك أي مشكلة، الرجوع بأمر واحد:"
echo "  adb shell \"su -c '$KSUD kernel dynamic-manager clear'\""
echo "  adb install -r $WORK/apk/manager.apk"
