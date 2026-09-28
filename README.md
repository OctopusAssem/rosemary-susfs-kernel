# Redmi Note 10S (rosemary) — KernelSU + SUSFS Kernel
### كيرنل مخصص لـ Redmi Note 10S (MIUI 14 / Android 13) مع إخفاء روت متقدّم

<p align="center">
  <b>Linux 4.14.186</b> · <b>ReSukiSU 4.2.0-rc3</b> · <b>SUSFS v2.3.0 (9/9)</b> · <b>AnyKernel3</b>
</p>

---

## ما هذا المشروع؟ | What is this?

**[العربية]**
كيرنل مخصص لجهاز **Xiaomi Redmi Note 10S** (`rosemary`) بنسخة **MIUI 14 / Android 13**، مبني من المصدر مع دمج **ReSukiSU** (مدير روت KernelSU) و **SUSFS v2.3.0**، بالإضافة إلى تعديلات تخفي نسخة الكيرنل وبصمته عن أدوات الكشف.

المشروع كامل ومفتوح: الباتشات، ملف البناء (GitHub Actions)، ملفات الكيرنل الجاهزة للفلاش، وطريقة إخفاء مدير الروت.

**[English]**
A custom kernel for the **Xiaomi Redmi Note 10S** (`rosemary`) running **MIUI 14 / Android 13**, built from source with **ReSukiSU** (KernelSU-based root manager) and **SUSFS v2.3.0**, plus patches that hide the kernel version/fingerprint from root-detection apps.

Everything is included: the patches, the GitHub Actions build workflow, ready-to-flash kernel images, and a guide to hiding the root manager app.

---

## المميزات | Features

| | |
|---|---|
| **Root** | ReSukiSU 4.2.0-rc3 (KernelSU fork) — kernel-level, no Magisk |
| **SUSFS** | v2.3.0 — NON-GKI, **9/9** features enabled |
| **إخفاء النسخة** | `uname` / `/proc/version` / f2fs reporting all spoofed to stock values |
| **المدير المخفي** | manager renamed + re-signed, registered via Dynamic Manager Configuration |
| **التعبئة** | AnyKernel3 — فلاش من أي ريكافري مخصص |
| **النوع** | NON-GKI, MediaTek MT6785 (Helio G95) |

القيم الستوك المستخدمة في الإخفاء | Stock values used for spoofing:

* `release` = `4.14.186-perf-g079d9bd73b14`
* `version` = `#1 SMP PREEMPT Sun Apr 14 03:38:02 UTC 2024`

---

## نتائج الفحص | Detection results

بعد تقفيل كل الحاجات (المدير مخفي + التطبيقات المكشوفة مش مثبّتة):

| الأداة | النتيجة |
|---|---|
| **Native Detector 7.7.0** | Environment is normal ✅ |
| **Momo 4.4.1** | normal ✅ |
| **TB Checker** | Basic / Device / **Strong** Pass ✅ |
| **Hunter 5.5.0** | لا كشوفات ✅ |
| **kknd Root Detector** | High واحد فقط (Build Field Coherence — سببه Play Integrity Fix، طبيعي) |

> ملاحظة مهمة ومُجرّبة: **معظم أدوات الكشف لا ترصد المدير أصلاً**. أهم سبب للكشف كان تطبيقات مساعدة مثل `KsuWebUI` (`io.github.a13e300.ksuwebui`) — شيلها فورًا لو عايز رسالة نظيفة.
> تفاصيل كاملة في [`detection-report.md`](detection-report.md).

> **Important, verified note:** most detectors never flag the manager itself. The biggest false lead was helper apps such as `KsuWebUI` (`io.github.a13e300.ksuwebui`) — uninstall it for a clean result. Full details in [`detection-report.md`](detection-report.md).

---

## التنزيل | Download

كيرنل جاهز للفلاش: **`rosemary-miui_a13-v4-f2fs-fixed-AnyKernel3.zip`**

* SHA-256: `eaeb6575597c7285b2ce080646687da98cc99552c395c98b368fa9737fa72880`
* موجود في قسم **Releases** في هذا المستودع.

Flashable kernel: **`rosemary-miui_a13-v4-f2fs-fixed-AnyKernel3.zip`** — see the **Releases** section.

### الحزمة الكاملة | Complete KIT

**`rosemary-complete-KIT.zip`** — كل حاجة في ملف واحد:

* الكيرنل الجاهز للفلاش (`kernel-rosemary-v4-AnyKernel3.zip`)
* مدير الروت المخفي (`SystemUpdate-manager-v4.2.0-rc3.apk` — باكدج `com.android.system.update`، موقّع v2 فقط)
* سكربت تشغيل بنقرة واحدة (`finish-hide-manager.bat` / `.sh`) — تركيب + تسجيل البصمة في الكيرنل + إعادة تشغيل
* `fingerprint.txt` + `README.txt`

🔗 التحميل: https://github.com/sanafottazaz-collab/rosemary-susfs-kernel/releases/download/manager-kit/rosemary-complete-kit.zip

بصمة المدير (Dynamic Manager): `826 eac9123b4d9093377df677052ab3a6ecea7d99d81a58d5cf8853998bc443050d`

**`rosemary-complete-KIT.zip`** — everything in one file: the flashable kernel, the hidden manager APK (package `com.android.system.update`, v2-only signed), a one-click install+register script, and the fingerprint. Same download link as above.

---

## البناء من المصدر | Building

المشروع يعتمد على قالب البناء [`JackA1ltman/NonGKI_Kernel_Build_2nd`](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd).

1. اعمل Fork للقالب (أو استخدم نسختك منه).
2. انسخ محتوى هذا المستودع فوقه بنفس المسارات:
   * `rosemary_susfs_fixed.patch` → جذر المستودع باسم `rosemary_susfs_fixed.patch`
   * `.github/workflows/build-rosemary-a13.yml` → نفس المسار
3. من تبويب **Actions** شغّل الـ workflow يدويًا (`workflow_dispatch`).
4. الناتج: `rosemary-miui_a13-v4-f2fs-fixed-AnyKernel3.zip`.

الشرح المفصّل خطوة بخطوة في [`build.md`](build.md).

---

## الفلاش | Flashing

1. اعمل نسخة احتياطية لـ **boot** (اختياري لكن مستحسن).
2. من ريكافري مخصص (TWRP / OrangeFox) → **Install** → اختر ملف الـ zip.
3. بعد الفلاش، ثبّت مدير ReSukiSU وافتحه مرة.
4. تفاصيل أكثر + خطوات التحقق في [`flash.md`](flash.md).

---

## إخفاء مدير الروت | Hiding the manager

ReSukiSU **لا يملك** خيار «Hide manager» مثل Magisk. البديل: إعادة تسمية الباكدج + توقيع جديد + تسجيل البصمة في الكيرنل عبر `dynamic-manager`.

الدليل الكامل (مُجرّب ويعمل): [`hide-manager.md`](hide-manager.md)
السكربت الجاهز: [`hide-manager-wsl.sh`](hide-manager-wsl.sh)

> `ReSukiSU has no "Hide manager" option.` The equivalent is package rename + re-sign + `ksud kernel dynamic-manager set`.

---

## هيكل المستودع | Repository layout

```
.
├── README.md
├── LICENSE
├── build-rosemary-a13.yml            # GitHub Actions workflow (-> .github/workflows/)
├── rosemary_susfs_fixed.patch        # kernel patch (-> repo root)
├── build.md                          # building from source
├── flash.md                          # flashing & verifying
├── hide-manager.md                   # hiding the root manager app
├── detection-report.md               # detector results + analysis
├── hide-manager-wsl.sh               # automated manager-hiding script
├── manager_fingerprint.py            # compute dynamic-manager size/hash
└── test-kernel.sh
```

---

## شكر وتقدير | Credits

* **User Creator:** *Assem_Hussein*
* **Kernel source:** [gabutgadungan/android_kernel_xiaomi_rosemary](https://github.com/gabutgadungan/android_kernel_xiaomi_rosemary) (`rosemary-13`)
* **Root manager:** [ReSukiSU](https://github.com/ReSukiSU/ReSukiSU)
* **SUSFS:** [simonpunk/susfs4ksu](https://github.com/simonpunk/susfs4ksu)
* **Build template:** [JackA1ltman/NonGKI_Kernel_Build_2nd](https://github.com/JackA1ltman/NonGKI_Kernel_Build_2nd) & [NonGKI_Kernel_Patches](https://github.com/JackA1ltman/NonGKI_Kernel_Patches)
* **Packing:** [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3)
* **Toolchain:** [Neutron-Toolchains/antman](https://github.com/Neutron-Toolchains/antman)

---

## تنبيه | Disclaimer

**[العربية]** الفلاش على مسؤوليتك. تأكد من مطابقة النسخة (MIUI 14 / Android 13) قبل الفلاش، واحتفظ دائمًا بنسخة من الـ boot الأصلي للرجوع. المشروع تعليمي/شخصي ولا يضمن أي نتيجة.

**[English]** Flash at your own risk. Verify your ROM matches (MIUI 14 / Android 13) before flashing and always keep a backup of your stock boot image. Provided as-is, no warranty.

Licensed under **GPL-2.0** (kernel source).


---

