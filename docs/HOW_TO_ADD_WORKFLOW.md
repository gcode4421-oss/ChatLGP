# 📚 دليل تثبيت الـ workflow يدوياً

<div dir="rtl">

نظراً لأن الـ GitHub token المستخدم لا يملك صلاحية `workflow`، لا يمكنني رفع ملف workflow تلقائياً. اتبع هذه الخطوات البسيطة:

## الخطوات

### 1. اذهب إلى GitHub
افتح: https://github.com/gcode4421-oss/ChatLGP

### 2. أنشئ ملف workflow جديد
1. اضغط على زر **"Add file"** → اختر **"Create new file"**
2. في حقل اسم الملف، اكتب:
   ```
   .github/workflows/build-apk.yml
   ```
   (ستظهر مجلدات تلقائياً عند الكتابة)

### 3. الصق محتوى workflow
انسخ كامل محتوى الملف `docs/build-apk.workflow.yml` (الموجود في هذا المشروع) والصقه في محرر GitHub.

أو استخدم هذا الرابط المباشر للنسخ:
```
https://raw.githubusercontent.com/gcode4421-oss/ChatLGP/main/docs/build-apk.workflow.yml
```

### 4. احفظ التغييرات
- في أسفل الصفحة، اكتب رسالة commit: `ci: add APK build workflow`
- اضغط **"Commit new file"**

### 5. فعّل Actions
- اذهب إلى تبويب **"Actions"** في الـ repo
- إذا ظهر تحذير، اضغط **"I understand my workflows, go ahead and enable them"**
- اضغط على workflow **"Build APK"** → **"Run workflow"** → **"Run workflow"** أخضر

### 6. انتظر البناء
- سيستغرق البناء ~10-15 دقيقة
- ستجد الـ APKs في **Artifacts** أسفل صفحة الـ run

## ⚠️ ملاحظة مهمة
ملف `dart.yml` الموجود حالياً في `.github/workflows/` هو الافتراضي من GitHub الذي يستخدم `dart pub get` (يفشل لأن المشروع Flutter). يمكنك:
- **تعطيله**: Actions → Dart → `...` → Disable workflow
- **أو حذفه**: اذهب إلى `.github/workflows/dart.yml` → Delete file

## 🎯 النتيجة المتوقعة
بعد تشغيل workflow "Build APK" بنجاح، ستجد في Artifacts:
- `localai-debug-apk` — APK debug كامل (~50-80 MB)
- `localai-release-apks` — 3 APKs release:
  - `app-arm64-v8a-release.apk` (للأجهزة الحديثة - موصى به)
  - `app-armeabi-v7a-release.apk` (للأجهزة القديمة)
  - `app-x86_64-release.apk` (للمحاكيات)

حمّل `app-arm64-v8a-release.apk` لمعظم الهواتف الحديثة (2020+).

---

## 🔒 توصية أمنية
بعد إتمام هذه الخطوات، يُرجى:
1. حذف الـ token الحالي من GitHub Settings → Developer settings → Tokens
2. إنشاء token جديد بصلاحيات: `repo` + `workflow`
3. عدم مشاركة الـ token في أي محادثة مستقبلاً
