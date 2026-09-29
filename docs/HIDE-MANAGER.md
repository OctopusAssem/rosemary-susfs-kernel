# إخفاء مدير الروت (ReSukiSU) | Hiding the root manager

آخر تحديث: 2026-09-28 — **مُجرّب ويعمل** على rosemary مع ReSukiSU v4.2.0-rc3 والكيرنل v4.

---

## القاعدة الأساسية: v2 فقط | The key rule: v2 signature only

الكيرنل (`kernel/manager/apk_sign.c` + `userspace/ksud/src/apk_sign.rs`) يقبل **توقيع v2 فقط**:

* وجود **v1** (`META-INF/*.SF`) ⇒ `Unexpected v1 signature scheme found!` ⇒ رفض.
* وجود **v3 / v3.1** ⇒ رفض (ksud) / `goto invalid` (الكيرنل).

⇒ لازم الـ APK يكون موقّعًا بـ **v1=false, v2=true, v3=false**.

> أدوات مثل **uber-apk-signer** تنتج v1+v2+v3 ⇒ الكيرنل يرفضها. استخدم **apksigner** من Android build-tools مباشرة.

**بصمة المدير** = `cert_len` + `sha256(cert DER)` من بلوك v2 (نفس خوارزمية `calc_cert_sha256`).
للمقارنة: المدير الرسمي = `887` / `d3469712b6214462764a1d8d3e5cbe1d6819a0b629791b9f4101867821f1df64`.

---

## المتطلبات | Requirements

```bash
sudo apt install -y openjdk-17-jre-headless adb python3 curl zip
mkdir -p ~/ksu-hide && cd ~/ksu-hide
curl -LO https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar
curl -LO https://dl.google.com/android/repository/build-tools_r34-linux.zip
unzip -o build-tools_r34-linux.zip           # يطلع مجلد android-14
```

من `android-14/` هنحتاج: `lib/apksigner.jar` · `zipalign` · `lib64/*.so` (تشغيل `zipalign` محتاج `LD_LIBRARY_PATH`).

---

## الخطوات | Steps

```bash
# 1) اسم باكدج المدير الحالي
adb shell pm list packages | grep -Ei "resukisu|kernelsu|sukisu|ksunext"
#    مثال: package:com.resukisu.resukisu

# 2) اسحب الـ APK الأصلي
adb shell pm path com.resukisu.resukisu
adb pull /data/app/.../base.apk manager.apk

# 3) فك الـ APK
java -jar apktool_2.9.3.jar d -f manager.apk -o src
```

**4) عدّل `src/AndroidManifest.xml`:**
* غيّر `package="com.resukisu.resukisu"` → `package="com.android.system.update"`
* غيّر `android:label="..."` في `<application>` → `android:label="System Update"`

**5) احذف خاصية `android:defaultLocale`** من `src/res/xml/_generated_res_locale_config.xml` (apktool لا يعرفها).

**6) أضف `- arsc`** تحت `doNotCompress:` في `src/apktool.yml` حتى يكون `resources.arsc` **Stored** (إلزامي لأندرويد 13+).

```bash
# 7) أعد البناء
java -jar apktool_2.9.3.jar b src -o new.apk

# 8) zipalign (إلزامي) — يحتاج مكتبات build-tools
export LD_LIBRARY_PATH=$PWD/android-14/lib64
./android-14/zipalign -f -p 4 new.apk new_aligned.apk

# 9) مفتاح + توقيع v2 فقط
keytool -genkeypair -keystore my.jks -alias ks -keyalg RSA -keysize 2048 \
        -validity 10000 -storepass <PASS> -keypass <PASS> -dname "CN=ks"
java -jar android-14/lib/apksigner.jar sign \
     --ks my.jks --ks-pass pass:<PASS> --key-pass pass:<PASS> \
     --v1 false --v2 true --v3 false \
     --out signed_v2.apk new_aligned.apk

# 10) احسب البصمة (cert_len + sha256(cert DER)) — سكربت مساعد:
python3 manager_fingerprint.py signed_v2.apk

# 11) احذف القديم وركّب الجديد (المفتاح اتغير ⇒ لازم uninstall)
adb uninstall com.resukisu.resukisu
adb install signed_v2.apk

# 12) سجّل البصمة في الكيرنل
adb shell su -c '/data/adb/ksu/bin/ksud kernel dynamic-manager set <size> <hash>'
adb shell su -c '/data/adb/ksu/bin/ksud kernel dynamic-manager get --internal true'

# 13) ريستارت
adb reboot
```

بعد الريستارت التطبيق يعرض:

```
Working [Built-in]
SuperUser: 2   Modules: 2
```

مع تحذير أحمر **"The manager you are using is not the official ReSukiSU manager"** — ده **طبيعي وغير ضار** (لأن المفتاح اتغير).

---

## ملاحظات مهمة | Important notes

* `ksud kernel dynamic-manager` الأوامر المتاحة: `get | set | set-apk | clear` فقط. **مفيش خيار «Hide manager»** في ReSukiSU.
* `set-apk` بيفشل مع توقيع v3 (`Unexpected v3 signature found!`) ⇒ استخدم `set` بالقيم المحسوبة يدويًا.
* بعد أي تحديث للمدير أو للكيرنل: **أعد الخطوة 10/12** وسجّل البصمة الجديدة.
* الرجوع بسرعة:
  ```bash
  adb uninstall com.android.system.update
  adb install manager.apk                     # النسخة الأصلية
  adb shell su -c '/data/adb/ksu/bin/ksud kernel dynamic-manager clear'
  ```
* **حافظ على ملف المفتاح (`my.jks`) وباسورده** — لو ضاع، مش هتقدر تعيد بناء نسخة بنفس البصمة.
* في WSL: تشغيل `bash script.sh` يلتقط نسخة `adb` الخاصة بلينكس (لا ترى الجهاز) — نفّذ أوامر `adb` في الشلّ العادي.

---

## هل ده فعلاً بيخفي؟ | Does this actually help?

بصراحة ومُجرّبًا: **معظم أدوات الكشف لا ترصد المدير من الأساس.** المدير المخفي يفيد ضد تطبيقات (خصوصًا بنكية) بتفتّش على **أسماء باكدجات مديرين الروت المعروفة**. تكلفته: تحذير «not official manager» + تحديثات يدوية. القرار لك.
