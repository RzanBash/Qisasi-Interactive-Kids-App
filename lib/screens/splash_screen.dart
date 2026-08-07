import 'package:flutter/material.dart';
import '../services/auth_repository.dart';
import 'onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/admin/admin_dashboard.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
 
  @override
  void initState() {
    super.initState();
    // جعلنا المدة الإجمالية للأنيميشن مناسبة لحركة الدخول والاستقرار
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    // حركة التكبير بلمسة مرنة تناسب تطبيقات الأطفال (easeOutBack)
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    
    // ظهور تدريجي في أول نصف من وقت الأنيميشن
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)));
    
    _ctrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _route();
    });
  }
 
  Future<void> _route() async {
    // ننتظر 2500 مللي ثانية (ثانيتين ونصف) ليعيش المستخدم تجربة الشعار
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // جلب البيانات والتحقق من المستخدم أثناء عرض الـ Splash
    Widget nextScreen;
    try {
      final auth = AuthRepository();
      final userId = await auth.getSavedUserId();
      if (!mounted) return;
 
      if (userId == null) {
        nextScreen = const LoginScreen();
      } else {
        bool admin = false;
        try {
          admin = await auth.isAdmin(userId).timeout(
            const Duration(seconds: 2),
            onTimeout: () => false,
          );
        } catch (dbError) {
          debugPrint("❌ خطأ أثناء الاستعلام: $dbError");
          admin = false;
        }

        if (admin) {
          nextScreen = const AdminDashboardScreen();
        } else {
          nextScreen = HomeScreen(userId: userId);
        }
      }
    } catch (globalError) {
      debugPrint("💥 خطأ عام: $globalError");
      nextScreen = const LoginScreen();
    }

    if (!mounted) return;

    // تفعيل حركة الاختفاء التدريجي (Fade Out) قبل الانتقال
    await _ctrl.reverse(from: 1.0); 

    if (!mounted) return;

    // التوجيه إلى الشاشة التالية بسلاسة
    Navigator.pushReplacement(
      context, 
      _fade_(OnboardingScreen(nextScreen: nextScreen)),
    );
  }
 
  PageRouteBuilder _fade_(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 600), // زيادة السلاسة أثناء التنقل
      );
 
  @override
  void dispose() { 
    _ctrl.dispose(); 
    super.dispose(); 
  }
 
  @override
  Widget build(BuildContext context) {
    // تم استخدام لون الخلفية الأبيض ليتطابق تماماً مع خلفية الصورة المرفقة
    return Scaffold(
      backgroundColor: Color(0xFFF7F9FC) , 
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Image.asset(
                  'assets/images/pic/splash.png', // تأكد من مطابقة امتداد الصورة (jpg أو png) في ملف pubspec.yaml
                  width: MediaQuery.of(context).size.width * 0.85, // جعل حجم الصورة متناسق مع كل الشاشات
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}