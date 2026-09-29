# البناء من المصدر | Building from source

البناء بيتم على **GitHub Actions** (مجانًا) — مش محتاج جهاز قوي ولا تنزيل أدوات.

---

## 1) جهّز المستودع

المشروع ده **مش** مشروع كامل بذاته؛ هو طبقة فوق قالب البناء
[`JackA1ltman/NonGKI_Kernel_Build_2nd`](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd).

* اعمل **Fork** للقالب، أو استخدم نسختك الموجودة منه.
* انسخ ملفات المشروع فوقه بنفس المسارات:

| من المشروع ده | إلى جذر المستودع |
|---|---|
| `rosemary_susfs_fixed.patch` | `rosemary_susfs_fixed.patch` |
| `.github/workflows/build-rosemary-a13.yml` | `.github/workflows/build-rosemary-a13.yml` |

> ⚠️ الباتش **لازم** يكون في **جذر** المستودع لأن الـ workflow يقرأه من `$GITHUB_WORKSPACE`.

---

## 2) الإعدادات داخل الـ workflow

المتغيرات المهمة في `build-rosemary-a13.yml`:

```yaml
KERNEL_SOURCE: https://github.com/gabutgadungan/android_kernel_xiaomi_rosemary
KERNEL_BRANCH: rosemary-13
DEFCONFIG_NAME: rosemary_defconfig
KERNELSU_AUTO_GET: "true"
KERNELSU_AUTO_FORK: resukisu        # ReSukiSU (مش KernelSU-Next)
SUSFS_ENABLE: "true"
SUSFS_FIXED:  "true"
AK3_SOURCE: https://github.com/osm0sis/AnyKernel3.git
PACK_METHOD: AnyKernel3
ROM_TEXT: miui_a13
HOOK_METHOD: syscall
```

---

## 3) الباتش بيعمل إيه؟

`rosemary_susfs_fixed.patch` (203 سطر) فيه 3 أجزاء:

1. **تعديلات SUSFS** في `fs/proc/task_mmu.c` وغيرها (تتوافق مع penguin/التفرّعات).
2. **تثبيت إخفاء `uname`** في:
   * `fs/proc/version.c` → استخدام `susfs_spoof_uname()`
   * `kernel/utsname_sysctl.c` و `kernel/sys.c` → نفس المنطق
   * `init/version.c` → تثبيت `release` و `version` على القيم الستوك
3. **إصلاح f2fs** في `fs/f2fs/Kconfig`: ضبط `F2FS_FAKE_KERNEL_RELEASE` و `F2FS_FAKE_KERNEL_VERSION` للنصوص الكاملة.

السبب الجذري الجزء (3): `CONFIG_F2FS_REPORT_FAKE_KERNEL_VERSION` يجعل `fsck.f2fs` ترى اسمًا **أقصر** من الستوك — ده يكشف إن النسخة معدّلة.

الـ workflow كمان بيتحقق آليًا بعد التطبيق:

```
grep -q "susfs_is_uname_spoof_buffer_set" fs/proc/version.c
grep -q "susfs_spoof_uname" kernel/utsname_sysctl.c
grep -q "susfs_spoof_uname" kernel/sys.c
grep -q "4.14.186-perf-g079d9bd73b14" init/version.c
```

---

## 4) شغّل البناء

* تبويب **Actions** → اختر `Build Redmi Note 10S (MIUI 14 / A13) KernelSU-Next + SUSFS`
* **Run workflow** → branch المناسب.
* اول تشغيل ياخد وقت (تنزيل toolchain)، بعدها أفضل.

---

## 5) الناتج

```
rosemary-miui_a13-v4-f2fs-fixed-AnyKernel3.zip
```

* `Image.gz-dtb` هو نواة الكيرنل.
* الملف **AnyKernel3** ⇒ يفلش من أي ريكافري مخصص من غير الحاجة لملف boot مبني مسبقًا.

تأكد من القيم النهائية:

```bash
unzip -p rosemary-miui_a13-*-AnyKernel3.zip Image.gz-dtb > img
strings img | grep -m1 "4.14.186-perf-g079d9bd73b14"
```

---

## ملاحظات

* أول بناء بينتج تحذيرات كثيرة — طبيعي. تأكد بس إن خطوة `patch -p1 --fuzz=0` نجحت.
* لو الـ workflow فشل في `patch-susfs`، غالبًا الـ patch الخاص بالقالب اتغيّر — راجع `SUSFS_FOLDER_FIXED`.
* ملفات الكيرنل الناتجة كبيرة (≈15MB) — استخدم **Releases** لتوزيعها.
