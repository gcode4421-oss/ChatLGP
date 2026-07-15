# Contributing to LocalAI Assistant

<div dir="rtl">

شكراً لاهتمامك بالمساهمة في **LocalAI Assistant**! 

## طرق المساهمة

### الإبلاغ عن الأخطاء
1. تحقق من [Issues المفتوحة](https://github.com/gcode4421-oss/ChatLGP/issues) لتجنب التكرار
2. افتح Issue جديد مع:
   - وصف واضح للمشكلة
   - خطوات إعادة الإنتاج
   - السلوك المتوقع مقابل الفعلي
   - لقطات شاشة إن أمكن
   - معلومات الجهاز (Android version، نموذج الهاتف)

### اقتراح ميزات
نحب سماع أفكارك! افتح Issue مع:
- وصف الميزة المقترحة
- حالة الاستخدام (لماذا تحتاجها؟)
- أمثلة من تطبيقات أخرى (إن وجدت)

### المساهمة بالكود

#### الإعداد المحلي
```bash
# Fork الـ repo ثم clone
git clone https://github.com/YOUR_USERNAME/ChatLGP.git
cd ChatLGP

# تثبيت التبعيات
flutter pub get

# تشغيل التطبيق
flutter run
```

#### قبل إرسال Pull Request
1. أنشئ فرعاً جديداً: `git checkout -b feature/feature-name`
2. اتبع أسلوب الكود
3. أضف اختبارات إن أمكن
4. تأكد من نجاح `flutter analyze`
5. اكتب رسائل commit واضحة

#### أسلوب الكود
- استخدم `flutter analyze` بدون تحذيرات
- اتبع [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- استخدم `const` حيثما أمكن
- اكتب تعليقات بالعربية للدوال المعقدة
- استخدم أسماء واضحة للمتغيرات والدوال

### الترجمة
نرحب بمساهمات الترجمة:
- إضافة لغات جديدة
- تحسين الترجمات الحالية
- مراجعة الترجمات العربية

### التوثيق
- تحسين README
- كتابة أمثلة استخدام
- إنشاء شروحات تفاعلية

## هيكل المشروع

```
lib/
|-- main.dart              # نقطة الدخول
|-- theme/                 # ألوان وثيمات
|-- models/                # نماذج البيانات
|-- services/              # خدمات (AI, Storage, etc.)
|-- screens/               # شاشات التطبيق
|-- widgets/               # widgets قابلة لإعادة الاستخدام
|-- utils/                 # أدوات مساعدة
```

## الإرشادات

### ملفات Dart
- ملف واحد = مسؤولية واحدة
- أقصى طول للسطر: 100 حرف
- استخدم `prefer_single_quotes`
- تجنّب `print()` — استخدم `debugPrint()` أو logger

### UI
- اتبع Material 3
- دعم Light و Dark themes
- تأكد من عمل RTL للعربية
- استخدم `Theme.of(context)` للألوان

### الاختبار
```bash
flutter test
flutter analyze
```

## العملية

1. Fork المشروع
2. أنشئ فرع ميزة (`git checkout -b feature/amazing-feature`)
3. Commit تغييراتك (`git commit -m 'Add: amazing feature'`)
4. Push إلى الفرع (`git push origin feature/amazing-feature`)
5. افتح Pull Request

## رخصة المساهمة

بمساهمتك في هذا المشروع، فإنك توافق على أن مساهماتك ستُرخّص تحت رخصة MIT.

---

شكراً لك!
</div>
