# PROGUARD RULES — LocalAI Assistant

# قواعد عامة لـ Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# sqflite
-keep class org.sqlite.** { *; }
-keep class net.sqlcipher.** { *; }

# حفظ أسماء الأصناف المستخدمة عبر reflection
-dontwarn android.support.**
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
