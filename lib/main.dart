import 'package:flutter/material.dart';
import 'package:qisasi_app/data/database/database_helper.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'screens/customize_screen.dart';
import 'screens/favorites_screen.dart';

void main() async {
  // 1. التأكد من ربط محرك فلاتر
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تهيئة قاعدة البيانات مع معالجة الأخطاء
  try {
    await DatabaseHelper.instance.database;
    debugPrint("✅ Database initialized successfully");
  } catch (e) {
    debugPrint("❌ Database initialization failed: $e");
  }

  runApp(const QisasiApp());
}

class QisasiApp extends StatelessWidget {
  const QisasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'قِصَصي',
      debugShowCheckedModeBanner: false,

      // ضبط اتجاه اللغة العربية
      locale: const Locale('ar', 'SA'),

      // 🎨 تعديل الهوية البصرية لتكون "صديقة للطفل"
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: GoogleFonts.balooBhaijaan2().fontFamily,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF), // اللون البنفسجي الأساسي
          primary: const Color(0xFF6C63FF),
          secondary: const Color(0xFF4CAF50), // أخضر مريح للعين
          surface: Colors.white, // خلفية بيضاء نظيفة
        ),
        // تحسين مظهر النصوص
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF2D2D2D),
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(color: Color(0xFF444444)),
        ),
      ),

      // البداية دائماً من شاشة الـ Splash وهي ستتولى الباقي بشكل آمن
      home: const SplashScreen(),

      routes: {
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignUpScreen(),
      },

      onGenerateRoute: (settings) {
        // الحصول على الـ userId من الوسائط المرسلة عند الانتقال
        final userId = settings.arguments as int? ?? 2; // أحمد هو الافتراضي

        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(
              builder: (_) => HomeScreen(userId: userId),
            );
          case '/library':
            return MaterialPageRoute(
              builder: (_) => LibraryScreen(userId: userId),
            );
          case '/customize':
            return MaterialPageRoute(
              builder: (_) => CustomizeScreen(userId: userId),
            );
          case '/favorites':
            return MaterialPageRoute(
              builder: (_) => FavoritesScreen(userId: userId),
            );
          default:
            return null;
        }
      },
    );
  }
}