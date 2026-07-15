# LocalAI Assistant — تطبيق Android أصلي

<div dir="rtl">

تطبيق **AI مساعد محلي** مبني بـ Flutter يجمع بين:
- 💬 **محادثة ذكية** مع دعم Markdown كامل وعرض الأكواد
- 🤖 **وضع Agent** مع أدوات (حاسبة، تاريخ، تلخيص، ترجمة)
- 🧠 **نماذج محلية مجانية** عبر Ollama (Llama, Qwen, Phi, Gemma, DeepSeek)
- 🎨 **واجهة عربية احترافية** بتصميم Material 3 (Light/Dark/System)
- 🔒 **خصوصية كاملة** — كل المعالجة محلية، لا إرسال للسحابة
- 💾 **تخزين محلي** للمحادثات (SQLite) + إعدادات قابلة للتخصيص

## 📋 المتطلبات لبناء APK

| الأداة | الإصدار الأدنى | رابط التحميل |
|-------|---------------|--------------|
| Flutter SDK | 3.19+ | https://flutter.dev/docs/get-started/install |
| Android SDK | API 34 | يأتي مع Android Studio |
| Java JDK | 17 | https://adoptium.net/ |
| Android Studio | Hedgehog+ | https://developer.android.com/studio |
| Ollama (للاختبار) | أي إصدار | https://ollama.com/ |

## 🚀 البناء السريع (محلياً)

```bash
# 1. فك ضغط المشروع
unzip localai_assistant.zip
cd localai_assistant

# 2. تثبيت التبعيات
flutter pub get

# 3. إنشاء الأيقونات
dart run flutter_launcher_icons

# 4. بناء APK (debug — سريع للاختبار)
flutter build apk --debug

# 5. أو بناء APK (release — أصغر وأسرع للتوزيع)
flutter build apk --release --split-per-abi
```

### 📱 مخرجات البناء

```
build/app/outputs/flutter-apk/
├── app-debug.apk                    # APK كامل (debug)
├── app-release.apk                  # APK كامل (release)
├── app-armeabi-v7a-release.apk      # أجهزة 32-bit قديمة
├── app-arm64-v8a-release.apk        # أجهزة 64-bit حديثة (مُوصى به)
└── app-x86_64-release.apk           # محاكيات
```

**للهواتف الحديثة (2020+)**: استخدم `app-arm64-v8a-release.apk` (الأصغر والأسرع)
**لكل الأجهزة**: استخدم `app-release.apk`

## ☁️ البناء السحابي (بلا تثبيت Flutter)

### الطريقة 1: GitHub Actions (مجاني)

1. ارفع المشروع إلى GitHub repository
2. أضف ملف `.github/workflows/build-apk.yml` (متوفر في المشروع)
3. اذهب إلى Actions → Build APK → Run workflow
4. حمّل APK من Artifacts

### الطريقة 2: Codemagic (مجاني للمشاريع الصغيرة)

1. اذهب إلى https://codemagic.io/
2. اربط حساب GitHub
3. اختر Flutter App
4. اضبط Build → Android → APK
5. ابدأ البناء — ستحصل على رابط تحميل APK

### الطريقة 3: FlutterFlow (بدون كود)

1. اذهب إلى https://flutterflow.io/
2. استورد ملفات lib/ كـ Custom Code
3. اضبط Build → APK
4. حمّل النتيجة

## ⚙️ إعداد Ollama على هاتفك

### الطريقة المُوصى بها: Ollama على الكمبيوتر

1. **ثبّت Ollama** على الكمبيوتر: https://ollama.com/download
2. **شغّل الخادم** متاحاً للشبكة:
   ```bash
   # Linux/Mac
   OLLAMA_HOST=0.0.0.0:11434 ollama serve

   # Windows (PowerShell)
   $env:OLLAMA_HOST="0.0.0.0:11434"; ollama serve
   ```
3. **حمّل نموذجاً** على الكمبيوتر:
   ```bash
   ollama pull llama3.2:3b
   ```
4. **في التطبيق** على هاتفك:
   - اذهب إلى الإعدادات
   - ضع عنوان IP الكمبيوتر (مثل `192.168.1.100`) بدلاً من `127.0.0.1`
   - تأكد أن الجهازان على نفس شبكة WiFi

### الطريقة البديلة: Ollama على الهاتف (Termux)

```bash
# 1. ثبّت Termux من F-Droid (ليس من Play Store)
# 2. في Termux:
pkg update && pkg upgrade
pkg install ollama
ollama serve &

# 3. حمّل نموذجاً
ollama pull qwen2.5:3b
```
ثم اترك التطبيق على `127.0.0.1:11434`.

## 🎯 الاستخدام

1. **افتح التطبيق** → سيحاول الاتصال بـ Ollama تلقائياً
2. **اذهب إلى "إدارة النماذج"** → حمّل نموذجاً (نوصي بـ `qwen2.5:3b` للعربية)
3. **اضبط النموذج الافتراضي** من الإعدادات
4. **ابدأ المحادثة** من الشاشة الرئيسية
5. **لتفعيل Agent**: القائمة → "تشغيل وضع Agent"

## 🌟 النماذج الموصى بها

| النموذج | الحجم | الأفضل لـ | يدعم العربية |
|--------|------|----------|--------------|
| `qwen2.5:3b` | ~2 GB | عام | ✅ ممتاز |
| `llama3.2:3b` | ~2 GB | عام | ✅ جيد |
| `phi3:mini` | ~2.3 GB | تحليل | ⚠️ محدود |
| `gemma2:2b` | ~1.6 GB | خفيف | ⚠️ محدود |
| `deepseek-r1:1.5b` | ~1.1 GB | استدلال | ⚠️ محدود |
| `qwen2.5:7b` | ~4.7 GB | احترافي | ✅ ممتاز |

## 📁 بنية المشروع

```
localai_assistant/
├── lib/
│   ├── main.dart                    # نقطة الدخول
│   ├── theme/
│   │   └── app_theme.dart           # ألوان وثيمات Material 3
│   ├── models/
│   │   └── chat_message.dart        # نماذج البيانات
│   ├── services/
│   │   ├── ai_service.dart          # عميل Ollama
│   │   ├── agent_service.dart       # منطق الـ Agent
│   │   ├── storage_service.dart     # SQLite + SharedPreferences
│   │   └── app_provider.dart        # إدارة الحالة
│   ├── screens/
│   │   ├── chat_screen.dart         # الشاشة الرئيسية
│   │   ├── conversations_screen.dart # قائمة المحادثات (Drawer)
│   │   ├── models_screen.dart       # إدارة النماذج
│   │   └── settings_screen.dart     # الإعدادات
│   ├── widgets/
│   │   ├── message_bubble.dart      # بطاقة الرسالة
│   │   └── chat_input.dart          # حقل الإدخال
│   └── utils/
│       └── timeago_ar.dart          # ترجمة timeago للعربية
├── android/                         # إعدادات Android
│   ├── app/
│   │   ├── build.gradle             # إعدادات البناء
│   │   ├── proguard-rules.pro       # قواعد التشويش
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # أذونات + تكوين
│   │       ├── kotlin/com/localai/assistant/
│   │       │   └── MainActivity.kt
│   │       └── res/                 # موارد (أيقونات، ثيمات)
│   ├── build.gradle
│   ├── settings.gradle
│   └── gradle.properties
├── .github/
│   └── workflows/
│       └── build-apk.yml            # CI/CD للبناء السحابي
├── pubspec.yaml                     # تبعيات Flutter
└── README.md
```

## 🔧 التخصيص

### تغيير اسم التطبيق
في `android/app/src/main/AndroidManifest.xml`:
```xml
android:label="اسم تطبيقك"
```

### تغيير لون التطبيق
في `lib/theme/app_theme.dart`، عدّل:
```dart
static const Color _primaryLight = Color(0xFF6366F1);
```

### تغيير معرّف الحزمة
في `android/app/build.gradle`:
```gradle
applicationId "com.yourcompany.yourapp"
```
وفي `android/app/src/main/kotlin/.../MainActivity.kt` — أعد تسمية المجلدات.

## 📜 الترخيص

MIT License — حر للاستخدام والتعديل والتوزيع.

## 🤝 المساهمة

المساهمات مرحب بها! افتح Issue أو Pull Request على GitHub.

</div>
