# الفلاش والتحقق | Flashing & verifying

## قبل أي حاجة | Before you start

| | |
|---|---|
| الجهاز | Xiaomi Redmi Note 10S — `rosemary` (M2101K7BG، MT6785) |
| النظام المطلوب | **MIUI 14 / Android 13** (لا تفلّش على A14 أو A12) |
| الريكافري | ريكافري مخصص (TWRP / OrangeFox) |
| النسخة الاحتياطية | احتفظ بـ stock `boot.img` للرجوع |

> ⚠️ النواة مبنية لنسخة Boot لـ MIUI 14 فقط. الفلاش على ROM مختلف قد يمنع الإقلاع.

---

## خطوات الفلاش | Steps

1. نزّل [`rosemary-miui_a13-v5-managerfix-AnyKernel3.zip`](https://github.com/OctopusAssem/rosemary-susfs-kernel/releases/download/v5-verified-pair-2026-09-30/rosemary-miui_a13-v5-managerfix-AnyKernel3.zip) من صفحة التنزيل الحالية.
2. (اختياري) اعمل نسخة احتياطية من `boot` من داخل الريكافري: **Backup → Boot**.
3. **Install** → اختر ملف الـ zip → **Swipe to confirm**.
4. **Reboot to system**.
5. ثبّت [مدير ReSukiSU المتوافق](https://github.com/OctopusAssem/rosemary-susfs-kernel/releases/download/v5-verified-pair-2026-09-30/systemupdate-manager-v4.2.0-rc3.apk) وافتحه مرة واحدة.
   * رقم الإصدار v4.2.0-rc3، واسم التطبيق الظاهر **System Update**. توقيعه مسجّل في كيرنل v5.
6. المفروض تشوف `Working [Built-in]` + SuperUser/Modules.

---

## التحقق بعد الريستارت | Verify after boot

```bash
# 1) نسخة الكيرنل (المفروض تكون القيم الستوك)
adb shell uname -a
#   Linux localhost 4.14.186-perf-g079d9bd73b14 #1 SMP PREEMPT Sun Apr 14 03:38:02 UTC 2024 aarch64

adb shell cat /proc/version     # نفس القيم
```

```bash
# 2) SUSFS
adb shell su -c 'cat /data/adb/ksu/susfs_config'   # أو من مدير الروت
adb shell su -c '/data/adb/ksu/bin/ksud kernel susfs get'
```

```bash
# 3) Root شغال
adb shell su -c 'id'      # uid=0(root)
```

```bash
# 4) الإخفاء (اختياري)
adb shell su -c '/data/adb/ksu/bin/ksud kernel dynamic-manager get --internal true'
```

---

## لو حصلت مشكلة | Troubleshooting

| الحالة | السبب المتوقع | الحل |
|---|---|---|
| bootloop | ROM غير مطابق | ارجع بالـ boot الأصلي من الريكافري |
| المدير بيقول `No KernelSU driver detected` | توقيع المدير غير مسجّل في الكيرنل | `dynamic-manager set <size> <hash>` أو ركّب المدير الرسمي |
| المدير رفض التثبيت | نسخة قديمة بنفس الباgcd مختلف التوقيع | `adb uninstall <pkg>` ثم ثبّت |
| التطبيقات مش بتشتغل (بعض البنوك) | بتكشف إضافات مساعدة | شيل تطبيقات مثل KsuWebUI، راجع `DETECTION-REPORT.md` |

**الرجوع الكامل:**
```bash
# من الريكافري: Install → stock_boot_backup.img  (أو Restore)
```

---

## إعادة الفلاش فوق نسخة قديمة

ملفات AnyKernel3 آمنة لإعادة الفلاش: بس فلّش الـ zip الجديد من فوق القديم بدون أي مسح (dirty flash)، واقفل الـ cache/dalvik اختياريًا.
