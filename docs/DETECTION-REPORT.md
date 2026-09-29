# تقرير نتائج الكشف | Detection report

الجهاز: Redmi Note 10S (`rosemary`) · MIUI 14 / Android 13 · الكيرنل v4 · ReSukiSU 4.2.0-rc3 + SUSFS 2.3.0
التطبيقات المثبّتة وقت الاختبار: **AlwaysStrong v1.0.4** (TrickyStore + PlayIntegrityFix) + **Zygisk Next 1.5.0**. لا Shamiko.

---

## النتائج النهائية | Final results

| الأداة | النتيجة | ملاحظة |
|---|---|---|
| **Native Detector 7.7.0** | Environment is normal ✅ | |
| **Momo 4.4.1** | normal ✅ | |
| **TB Checker** | Basic / Device / **Strong** Pass ✅ | Virtual integrity Fail = طبيعي (ليس محاكيًا) |
| **Hunter 5.5.0** | لا كشوفات ✅ | |
| **kknd Root Detector** | **1 High** فقط | سببه Play Integrity Fix، راجع تحت |

**الخلاصة:** الكيرنل + المدير المخفي مش بيتكشفوا. الباقي إما طبيعي (PIF) أو سببه تطبيقات مساعدة.

---

## kknd — تحليل مفصّل | Deep dive

kknd هو الأداة الوحيدة اللي طلعت تحذيرات، وأهم حاجة إننا نعرف سببها الحقيقي.
القوايم المدمجة فيه مشفّرة بـ **Base64 ثم XOR بمفتاح `0x37`**. بعد فك التشفير طلع إن كل الـ High كانت من **تطبيقات**، مش من الكيرنل:

### السبب الأول: `KsuWebUI` (`io.github.a13e300.ksuwebui`)

كان مسؤول عن **3 من 4** تحذيرات High:

| الفحص | دليل الفحص |
|---|---|
| `Root Manager Apps` | `io.github.a13e300.ksuwebui` موجود في قائمة الـ 60 باكدج |
| `Package Manager Check` | نفس القايمة + `launch intent` |
| `KernelSU / KSU Next` | موجود في قائمة `kernelSuPackages` (الفحص يتحقق من باكدجات المديرين كمان) |

⇒ **حذف KsuWebUI بالكامل (uninstall، مش تعطيل)** ينزّل النتيجة من 4 High إلى 1.

### السبب الثاني: `KeyAttestation` (`io.github.vvb2060.keyattestation`)

موجود كمان في قائمتي `rootPackages` و `patchedApps` ⇒ يشعل نفس فحصي `Root Manager Apps` و `Package Manager Check`.
لو محتاجه، شيله مؤقتًا وقت الفحص.

### الباقي طبيعي

| الفحص | السبب |
|---|---|
| `Build Field Coherence` (High) | Play Integrity Fix: `ro.build.fingerprint` متغيّر بينما `ro.system.build.fingerprint` ستوك ⇒ اختلاف. **ثمن الـ Strong Integrity.** |
| `Kernel / Patch Window Mismatch` (Warning) | تاريخ بناء الكيرنل المخفي (2024-04-14) بعيد عن تواريخ الباتشات الحديثة. طبيعي. |
| `Custom Recovery Artifacts` (Warning) | بيتحقق من وجود `/cache/recovery` — **موجود على أي جهاز أندرويد أصلي**. إنذار كاذب. |
| `Non-Rooted Power Apps` (Warning) | وجود Termux. معلوماتي. |

### مسارات الكيرنل اللي بيفتّش عليها | Kernel paths it probes

كلها كانت **غير موجودة/مخفية** عند الجهاز:

```
/dev/ksud  /dev/ksu  /data/adb/ksu  /data/adb/ksud  /data/adb/ksu/bin
/sys/module/kernelsu  /sys/kernel/ksu  /proc/kernelsu
```

وكمان: مفيش props باسم `ro.kernelsu.version` وأخواتها، ومفيش سوكت اسمه فيه `ksu` في `/proc/net/unix`.

> **درس:** قبل ما تلاحق الكيرنل، شيل التطبيقات المساعدة. أغلب «الكشوفات» بتيجي من `KsuWebUI` ومثيلاتها.

---

## أدوات مساعدة | Tooling

* `test-kernel.sh` — بناء + تحقّق سريع من قيم `uname`.
* سجّل البصمة/الحجم للمدير المخفي بـ `manager_fingerprint.py`.
