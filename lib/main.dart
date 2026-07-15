/// LocalAI Assistant — تطبيق AI مساعد محلي
/// يجمع بين المحادثة ووضع Agent مع دعم النماذج المحلية المجانية
///
/// الميزات:
/// - واجهة عربية احترافية بـ Material 3
/// - دعم Light/Dark/System Themes
/// - محادثة متدفقة (streaming)
/// - وضع Agent مع أدوات (حاسبة، تاريخ، تلخيص، ترجمة)
/// - إدارة النماذج (تحميل/حذف)
/// - تخزين محلي للمحادثات (SQLite)
/// - دعم RTL

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'services/app_provider.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/chat_screen.dart';
import 'screens/models_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // قفل الاتجاه عمودياً
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // تهيئة التخزين
  await StorageService.init();

  runApp(const LocalAiApp());
}

class LocalAiApp extends StatelessWidget {
  const LocalAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider()..loadSettings(),
      child: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final themeMode = _resolveThemeMode(StorageService.themeMode);
          final isArabic = StorageService.language == 'ar';

          return MaterialApp(
            title: 'LocalAI Assistant',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            locale: isArabic ? const Locale('ar') : const Locale('en'),
            builder: (context, child) {
              // إعداد اتجاه RTL للعربية
              return Directionality(
                textDirection:
                    isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: child!,
              );
            },
            initialRoute: '/',
            routes: {
              '/': (ctx) => const ChatScreen(),
              '/models': (ctx) => const ModelsScreen(),
              '/settings': (ctx) => const SettingsScreen(),
            },
          );
        },
      ),
    );
  }

  ThemeMode _resolveThemeMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
