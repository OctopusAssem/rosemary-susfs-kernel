# ملاحظات مهمة | Important Notes

هذا الملف يجمع كل الملاحظات والتنبيهات الخاصة بالمشروع، بالعربي والإنجليزي.

---

## 1) عام لا يعني مشهور | Public is not discoverable
المستودع **عام (public)**، وأي شخص لديه الرابط يمكنه رؤية كل الملفات وتنزيلها بالكامل.
لكنه لا يظهر تلقائيا في نتائج محركات البحث. للظهور: أضف Topics ووصفا واضحا وشارك الرابط.

This repository is **public**: anyone with the link can view and download everything.
It does **not** automatically appear in search engines. Add topics, a clear description, and share the link.

## 2) سلامة حساب GitHub | Account safety
- يفضل تغيير كلمة مرور GitHub دوريا.
- تفعيل المصادقة الثنائية (2FA) من Settings > Password and authentication.
- عدم مشاركة كلمات المرور أو الرموز (tokens) في أي محادثة.
- أي رمز وصول (PAT) يستخدم للرفع يجب حذفه بعد الانتهاء. (تم حذف كل الرموز المؤقتة المستخدمة.)

## 3) تنبيه أمني وقانوني | Security and legal notice
- الحزمة تحتوي على **مدير روت معدل (APK)** يظهر باسم System Update.
- استخدمها على **مسؤوليتك الشخصية** وعلى جهازك الخاص فقط.
- **لا** تقدمها لأي شخص على أنها تحديث نظام حقيقي أو تطبيق رسمي.
- روت الجهاز قد يبطل الضمان ويؤثر على تطبيقات البنوك والدفع.

## 4) الخصوصية | Privacy
- مفتاح التوقيع الخاص **ks.jks غير مرفوع** في هذا المستودع عن قصد. المرفوع هو التطبيق الموقّع فقط.
- لا ترفع ks.jks ولا كلمة مروره إلى أي مكان عام.

## 5) بصمة المدير (Dynamic Manager) | Manager fingerprint
```
size = 826
sha256(cert DER) = eac9123b4d9093377df677052ab3a6ecea7d99d81a58d5cf8853998bc443050d
```
لتسجيلها في الكيرنل:
```
adb shell su -c '/data/adb/ksu/bin/ksud kernel dynamic-manager set 826 eac9123b4d9093377df677052ab3a6ecea7d99d81a58d5cf8853998bc443050d'
adb shell su -c '/data/adb/ksu/bin/ksud kernel dynamic-manager get --internal true'
```

## 6) محتويات الحزمة الكاملة | Complete KIT contents
rosemary-complete-KIT.zip:
- kernel-rosemary-v4-AnyKernel3.zip
- SystemUpdate-manager-v4.2.0-rc3.apk (com.android.system.update، موقّع v2 فقط)
- finish-hide-manager.bat / finish-hide-manager.sh
- fingerprint.txt + README.txt

sha256 لكيرنل v4: eaeb6575597c7285b2ce080646687da98cc99552c395c98b368fa9737fa72880
sha256 لتطبيق المدير: 72803f272cef73f419c06aad42949da43670c853c87fc7734314a379e2706a3d

## 7) نتائج الكشف | Detection notes
- أهم سبب للكشف كان تطبيقات مساعدة مثل KsuWebUI (io.github.a13e300.ksuwebui) - يفضل إزالتها.
- Kknd: High واحد متبقٍ (Build Field Coherence) سببه Play Integrity Fix، وهو طبيعي.
- Native Detector / Momo / TB Checker / Hunter: نظيفة.

## 8) روابط | Links
- المستودع: https://github.com/sanafottazaz-collab/rosemary-susfs-kernel
- الإصدار: https://github.com/sanafottazaz-collab/rosemary-susfs-kernel/releases/tag/manager-kit
- الموقع: https://rosemary-susfs-kernel.pages.bu.app/
