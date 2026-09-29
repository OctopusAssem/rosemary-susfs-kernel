# إلغاء FLAG_SECURE | Disabling FLAG_SECURE

## ما هي `FLAG_SECURE`؟

راية (`Window flag`) يستخدمها التطبيق ليمنع **تصوير الشاشة** وتسجيل الفيديو وبثّ الشاشة.
عند محاولة التصوير تظهر صورة سوداء بدل المحتوى. تستخدمها تطبيقات البنوك، المحافظ،
نتفليكس، والمراسلة المقيّدة.

## هل تُلغى من الكيرنل؟

**لا.** هذه نقطة مهمة:

* `FLAG_SECURE` **ليست** خاصية SELinux ولا جزءًا من نواة لينكس.
* تُدار بالكامل في **SystemServer / WindowManagerService / SurfaceFlinger** في طبقة Java
  (`frameworks/base`)، أي خارج نطاق الكيرنل تمامًا.
* ميزات KernelSU المتاحة: `su_compat` · `kernel_umount` · `sulog` · `adb_root` · `selinux_hide`
* ميزات SUSFS v2.3.0 التسع: `SUS_PATH` · `SUS_MOUNT` · `SUS_KSTAT` · `SPOOF_UNAME` ·
  `HIDE_KSU_SUSFS_SYMBOLS` · `SPOOF_CMDLINE_OR_BOOTCONFIG` · `OPEN_REDIRECT` · `SUS_MAP` ·
  `ENABLE_LOG`

**لا يوجد ولا يمكن أن يوجد** خيار كيرنل لهذا الغرض. أي حلّ صحيح يعمل في طبقة الجافا.

## الحلّ المستخدم: Simple Flag Secure v7.7

الموديول [`ShivamXD6/Simple-Flag-Secure`](https://github.com/ShivamXD6/Simple-Flag-Secure):

* يعدّل `services.jar` على مستوى الـ bytecode باستخدام `sfs.jar` (dexlib2) **عند التثبيت فقط**.
* يوقف الدوال: `isSecureLocked` · `notAllowCaptureDisplay` · `preventTakingScreenshotToTargetWindow`
* يخفي إشعار كشف اللقطة على Android 14+.
* **بدون** Zygisk · LSPosed · Xposed.
* صفر خدمات خلفية، صفر استهلاك بطارية.
* متوافق مع Magisk · KernelSU · APatch (بما فيها ReSukiSU).

### المتطلبات

* `services.jar` **deodexed** — نسخة MIUI 14 الرسمية كذلك ✅
* Android 10+

### التركيب

الموديول مُضمَّن داخل `rosemary-v5-ALLINONE-AnyKernel3.zip` ويُثبَّت تلقائيًّا عند أول إقلاع
(راجع [`ALL-IN-ONE.md`](ALL-IN-ONE.md)).

للتركيب المنفصل: نزّل `Simple_Flag_Secure_v7.7.zip` من مستودع المطوّر وثبّته من مدير الروت.
سجّل السكربت عملية التعديل في `/sdcard/Download/sfs_install.log`.

### التحكم

زر Action في مدير الروت يبدّل بين `ALLOWED` و `BLOCKED`. الضغط على أزرار الصوت:
`Vol +` للتبديل · `Vol -` لتشغيل التشخيص — بدون إعادة إقلاع.

---

## ملاحظة عن الإخفاء

الموديول يركّب `services.jar` المعدّل عبر `bind mount`، ويستخدم خصيصًا:

```sh
# post-fs-data.sh
mount -o bind "$PATCHED_JAR" "$TARGET_JAR"
/data/adb/ksu/bin/ksu_susfs add_sus_kstat "$TARGET_JAR"
/data/adb/ksu/bin/ksu_susfs add_try_umount "$TARGET_JAR" 1
/data/adb/ksud kernel umount add "$TARGET_JAR" --flags 2
```

أي أنه **يتكامل مباشرة مع SUSFS** لإخفاء التركيب عن التطبيقات — لذلك لا يزيد سطح الكشف.
