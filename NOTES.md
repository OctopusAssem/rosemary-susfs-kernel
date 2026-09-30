# ملاحظات مهمة | Important Notes

هذا الملف يجمع ملاحظات المشروع، ويعرض رابط التنزيل الحالي بوضوح.

## التنزيل الحالي | Current download pair

الملفان التاليان متوافقان وموجودان معًا في [صفحة إصدار واحدة](https://github.com/OctopusAssem/rosemary-susfs-kernel/releases/tag/v5-verified-pair-2026-09-30):

- ملف التفليش: `rosemary-miui_a13-v5-managerfix-AnyKernel3.zip`
  - SHA-256: `531d9c0c4f2cd3c427268c277dd2b94a8994b2b0cd35fb7ad8ecd80d8e175b38`
- مدير ReSukiSU: `systemupdate-manager-v4.2.0-rc3.apk` (`com.android.system.update`، موقّع v2 فقط)
  - SHA-256: `72803f272cef73f419c06aad42949da43670c853c87fc7734314a379e2706a3d`

المدير هو النسخة المعدلة المسجلة في كيرنل v5. يظهر باسم **System Update** لكنه ليس تطبيق تحديث رسميًا. الملفات مخصصة لـ Redmi Note 10S (`rosemary`) على MIUI 14 / Android 13 فقط. صفحة الإصدار تجمع الملفين؛ لم يُعَد بناء الكيرنل في هذا التحديث.

## 1) عام لا يعني مشهور | Public is not discoverable

المستودع **عام (public)**، وأي شخص لديه الرابط يمكنه رؤية كل الملفات وتنزيلها بالكامل.
لكنه لا يظهر تلقائيًا في نتائج محركات البحث. للظهور: أضف Topics ووصفًا واضحًا وشارك الرابط.

This repository is **public**: anyone with the link can view and download everything.
It does **not** automatically appear in search engines. Add topics, a clear description, and share the link.

## 2) سلامة حساب GitHub | Account safety

- تفعيل المصادقة الثنائية (2FA) من Settings > Password and authentication.
- عدم مشاركة كلمات المرور أو الرموز (tokens) في أي محادثة.
- أي رمز وصول (PAT) يستخدم للرفع يجب حذفه بعد الانتهاء. (الرموز المؤقتة السابقة أُلغيت.)

## 3) تنبيه أمني وقانوني | Security and legal notice

- الحزمة تحتوي على **مدير روت معدل (APK)** يظهر باسم System Update.
- استخدمها على **مسؤوليتك الشخصية** وعلى جهازك الخاص فقط.
- **لا** تقدمها لأي شخص على أنها تحديث نظام حقيقي أو تطبيق رسمي.
- روت الجهاز قد يبطل الضمان ويؤثر على تطبيقات البنوك والدفع.

## 4) الخصوصية | Privacy

- مفتاح التوقيع الخاص **ks.jks غير مرفوع** في هذا المستودع عن قصد. المرفوع هو التطبيق الموقّع فقط.
- لا ترفع ks.jks ولا كلمة مروره إلى أي مكان عام.

## 5) بصمة المدير | Manager fingerprint

```text
size = 826
sha256(cert DER) = eac9123b4d9093377df677052ab3a6ecea7d99d81a58d5cf8853998bc443050d
```

البصمة مسجلة في كيرنل v5. للأجهزة/النسخ الأقدم فقط، راجع تعليمات الإصدار المناسب ولا تطبقها عشوائيًا.

## 6) الحزمة القديمة | Archived v4 KIT

الحزمة `rosemary-complete-KIT.zip` وملف كيرنل v4 محفوظان كسجل تاريخي فقط. لا تخلطهما مع ملفي v5 المعروضين في بداية الصفحة.

## 7) نتائج الكشف | Detection notes

- أهم سبب للكشف كان تطبيقات مساعدة مثل KsuWebUI (`io.github.a13e300.ksuwebui`) - يفضل إزالتها.
- Kknd: High واحد متبقٍ (Build Field Coherence) سببه Play Integrity Fix، وهو طبيعي.
- Native Detector / Momo / TB Checker / Hunter: نظيفة.

## 8) روابط | Links

- المستودع: https://github.com/OctopusAssem/rosemary-susfs-kernel
- أحدث تنزيلين متوافقين: https://github.com/OctopusAssem/rosemary-susfs-kernel/releases/tag/v5-verified-pair-2026-09-30
- أرشيف الإصدارات السابقة: https://github.com/OctopusAssem/rosemary-susfs-kernel/releases
- الموقع: https://rosemary-susfs-kernel.pages.bu.app/
