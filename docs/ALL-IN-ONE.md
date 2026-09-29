# الملف الشامل | ALL-IN-ONE

## ما هو؟

`rosemary-v5-ALLINONE-AnyKernel3.zip` — ملف تفليش **واحد** يحتوي:

| المكوّن | الوصف |
| --- | --- |
| **كيرنل v5** | Linux 4.14.186 + ReSukiSU 4.2.0-rc3 + SUSFS v2.3.0 (9/9) + تصحيح توقيع المدير |
| **AlwaysStrong v1.0.4** | موديول تلقائي: TEE-Simulator-RS + PlayIntegrityFork + keybox (id=`tricky_store`) |
| **Simple Flag Secure v7.7** | إلغاء `FLAG_SECURE` للسماح بتصوير الشاشة في كل التطبيقات |

* SHA-256: `6390b6f6c7ff587aebc628c58da2547988bf71ae471324f8aa1f66a405ec5dad`
* الحجم: 20,422,635 بايت

---

## كيف يعمل؟

الملف مبني على [AnyKernel3](https://github.com/osm0sis/AnyKernel3).
عند الفلاش:

1. `anykernel.sh` يستدعي `dump_boot` ثم `write_boot` → يُكتب الكيرنل `Image.gz-dtb` في قسم `boot`.
2. أي أن `do.modules=1` و `do.systemless=1` يجعل AK3 يُنشئ موديول مساعد باسم `ak3-helper`
   وينقل مجلد `modules/` إليه، مع نسخ `post-fs-data.sh` إلى داخله باسم `post-fs-data.2.sh`.
3. عند أول إقلاع، يشغّل `ak3-helper/post-fs-data.sh` السكربت المُرفق فيُثبّت الموديولين
   المضمّنين في `/data/adb/modules/`:
   * `tricky_store` ← من `modules/system/lib/modules/tricky_store/`
   * `simple_flag_secure` ← من `modules/system/lib/modules/simple_flag_secure/`
4. بعد الإقلاع التالي يظهر الموديولان في مدير الروت كأنك ثبّتّهما يدويًّا.

### تحسينات تقليل الحجم

المكتبات الأصلية (native libs) تُقلَّص تلقائيًّا: يُحتفظ فقط بمعمارية الجهاز (`arm64-v8a`
لهذا الجهاز)، فتنزل من ~9.6 MB إلى ~6.7 MB.

---

## الفلاش

1. افتح مدير KernelSU/ReSukiSU (باسم `System Update`).
2. **Modules** → زر التثبيت → اختر `rosemary-v5-ALLINONE-AnyKernel3.zip`.
3. انتظر انتهاء الفلاش، ثم أعد الإقلاع.
4. بعد الإقلاع: افتح Modules مرة أخرى للتأكد من ظهور `AlwaysStrong` و `Simple Flag Secure`.

> ⚠️ ملاحظة: هذا الملف **يفلّش الكيرنل أيضًا** — لا تستخدمه إن كنت على روم مختلف عن
> **MIUI 14 / Android 13**.

---

## التحقق بعد الفلاش

```sh
# الموديولات المثبتة
adb shell "su -c 'ls /data/adb/modules'"

# الموديول المساعد
adb shell "su -c 'cat /data/adb/modules/ak3-helper/module.prop'"

# ميزات الكيرنل (يجب أن تظهر selinux_hide = 1)
adb shell "su -c '/data/adb/ksu/bin/ksud feature list'"

# نسخة SUSFS والميزات المفعّلة
adb shell "su -c '/data/adb/ksu/bin/ksu_susfs show version'"
adb shell "su -c '/data/adb/ksu/bin/ksu_susfs show enabled_features'"
```

---

## إعداد KernelSU الموصى به

| الميزة | القيمة | لماذا |
| --- | --- | --- |
| `su_compat` | مفعّلة | توافق تطبيقات `su` القديمة |
| `kernel_umount` | مفعّلة | فصل الموديولات تلقائيًّا عن التطبيقات |
| `selinux_hide` | **مفعّلة** | تنقية استعلامات `/sys/fs/selinux` — تلزم لتطبيقات الشبكة (WE/Vodafone) |
| `sulog` | مطفأة | تقليل البصمة |
| `adb_root` | مطفأة | تقليل البصمة |

لتفعيل `selinux_hide` بعد الإقلاع (مرة واحدة):

```sh
adb shell "su -c '/data/adb/ksu/bin/ksud feature set selinux_hide 1'"
adb shell "su -c '/data/adb/ksu/bin/ksud feature save'"
adb reboot
```

> ⚠️ أمر `feature set` وحده يفشل بـ `ioctl failed: Try again (os error 11)` إن نُفّذ بعد اكتمال
> الإقلاع، لأن الكيرنل يحذف النسخة الاحتياطية من سياسة SELinux في `on_boot_completed`.
> لذلك **يجب** تنفيذ `feature save` ثم إعادة الإقلاع (يعمل التفعيل في مرحلة `post-fs-data`).

---

## الملفات المصدرية | Sources

* AlwaysStrong: <https://github.com/evoker0/AlwaysStrong> (v1.0.4)
* Simple Flag Secure: <https://github.com/ShivamXD6/Simple-Flag-Secure> (v7.7)

جميع الحقوق لمطوّريها الأصليين.
