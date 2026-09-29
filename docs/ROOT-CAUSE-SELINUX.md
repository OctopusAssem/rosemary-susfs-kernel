# السبب الجذري: لماذا كانت تطبيقات الشبكة تقفل | Root cause: SELinux probes

## المشكلة

تطبيق **WE / Vodafone** (`com.emeint.android.myservices`) كان يرفض العمل على الجهاز المروّت،
مع أن أدوات الكشف العامّة (Momo, Native Detector, TB Checker) لم ترصد شيئًا.

## التحليل

سجلات التطبيق أظهرت أنه يستعمل **عملية معزولة** (`app_zygote`) لفحص نواة النظام مباشرةً،
عبر نظام ملفات SELinux:

| الفحص | كيف يعمل |
| --- | --- |
| **SELinux Context Validity Oracle** | يكتب `u:object_r:<type>:s0` في selinuxfs ويسأل الكيرنل هل الـ context صالح ⇒ يكشف أنواع مخصوصة للروت مثل `u:object_r:ksu_file:s0` |
| **SELinux Policy Tampering** | يقرأ `/sys/fs/selinux/access` و`/sys/fs/selinux/status` ويقارن `policyload` مع `seqno` ⇒ يكشف إعادة تحميل سياسة معدّلة (شائع عند دمج قواعد KernelSU) |

نتيجة التطبيق قبل الإصلاح:

```
WARNING: system_server can execmem;
found Magisk; found KernelSU; found ZygiskNext; sequence=4;
ROOT: KernelSU, Magisk via SELinux context validity oracle
```

## الحلّ

وليس بحذف موديول ولا بإخفاء ملفات، بل بتفعيل ميزة في الكيرنل: **`selinux_hide`**
(Feature ID = 4).

الوصف الرسمي من ReSukiSU:

> *SELinux Hide — sanitize /sys/fs/selinux access results for app UIDs*

أي أن أي تطبيق يسأل عن سياسة SELinux يُجاب من نسخة **السياسة الأصلية (الستوك)** لا المعدّلة،
فتختفي آثار KernelSU والسِكونس والأنواع المخصوصة.

### كيف تُفعَّل

```sh
adb shell "su -c '/data/adb/ksu/bin/ksud feature set selinux_hide 1'"
adb shell "su -c '/data/adb/ksu/bin/ksud feature save'"
adb reboot
# تحقق بعد الإقلاع
adb shell "su -c '/data/adb/ksu/bin/ksud feature get selinux_hide'"
adb shell "su -c 'dmesg | grep -i selinux_hide'"
```

### لماذا يفشل `feature set` وحده؟

درس مهم — الخطأ `ioctl failed: Try again (os error 11)` أي `-EAGAIN`:

1. عند الإقلاع، الكيرنل يأخذ **نسخة احتياطية** من سياسة SELinux الأصلية في
   `kernel/selinux/rules.c:apply_kernelsu_rules()` (يُستدعى في مرحلة `init second_stage`).
2. لكن `kernel/runtime/boot_event.c:on_boot_completed()` يستدعي
   `ksu_selinux_hide_drop_backup_if_unused()`، والتي **تحذف النسخة الاحتياطية** إن كانت الميزة
   غير مُشغّلة — توفيرًا للذاكرة.
3. لذلك أي محاولة تفعيل **بعد** اكتمال الإقلاع تفشل ولا يمكن أن تنجح:

```
selinux_hide: no backup policydb available, please save feature and reboot to retry!
```

4. الحلّ: `ksud feature save` يكتب الاختيار في `/data/adb/ksu/.feature_config`، وعند الإقلاع
   التالي يُفعّلها `ksud` في **مرحلة post-fs-data** (عبر `feature::init_features()`)، أي
   **قبل** حذف النسخة الاحتياطية — فتنجح.

> ملاحظة مفيدة: تنفيذ `feature set` الفاشل يعلّم الميزة كـ«مطلوبة» في الذاكرة، ولذلك
> `feature get` يعطي `Value: 1` مباشرةً — وهذا كافٍ ليحفظها `feature save`.

## ماذا اكتُشف أيضًا

* **بندَي kknd المتبقيان** (Build Field Coherence + Kernel/Patch Window) ليسا أثر روت:
  * الأول سببه أن MIUI تعيد تسمية قسم النظام إلى `Xiaomi/missi/missi` بينما vendor/odm
    يبقى على قاعدة Android 12 — سلوك طبيعي في الروم (مؤكَّد مقابل نسخ MIUI حقيقية).
  * الثاني سببه موديول Play Integrity الذي يثبّت `ro.build.version.security_patch` لتاريخ حديث.
* **`FLAG_SECURE` ليس خاصية SELinux** — راجع [`FLAG-SECURE.md`](FLAG-SECURE.md).
