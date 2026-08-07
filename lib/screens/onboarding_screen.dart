import 'package:flutter/material.dart';
import 'login_screen.dart';

// ─── ثوابت الألوان والمظهر ───────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFFF7F9FC);  // خلفية مائلة للبيج الفاتح
  static const orange = Color(0xFFFF5722); // البرتقالي الزاهي للأزرار
  static const textDark = Color(0xFF1A1C29); // كحلي داكن جداً للعناوين
  static const textMid = Color(0xFF4A4B57); // رمادي داكن للنصوص الفرعية
}

class OnboardingScreen extends StatefulWidget {
  // استقبال الشاشة المحددة مسبقاً من الـ Splash بناءً على فحص الصلاحيات والأخطاء
  final Widget nextScreen;

  const OnboardingScreen({super.key, required this.nextScreen});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // إعداد بيانات الصفحات التعريفية
  static const _pages = [
    _OBData(
      imagePath: 'assets/images/pic/onp1.png',
      title: 'عوالم مختلفة!',
      body: 'استكشف أماكن سحرية وغامضة!',
    ),
    _OBData(
      imagePath: 'assets/images/pic/onp3.png',
      title: 'شخصيات مذهلة!',
      body: 'قابل أبطالك وحيواناتك الجديدة!',
    ),
    _OBData(
      imagePath: 'assets/images/pic/onp2.png',
      title: 'أنشئ قصتك الآن!',
      body: 'الآن اجمع بين أبطالك ومواقعك\nواكتب مغامرتك الخاصة!',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  bool get _isLastPage => _page == _pages.length - 1;

  // الانتقال للصفحة التالية، أو التوجه للشاشة الممررة (widget.nextScreen) عند نهاية الأونبوردينج
  void _next() {
    if (_isLastPage) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => widget.nextScreen),
      );
    } else {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ─── الجزء العلوي: زر تخطي (يمين) ونقاط التنقل (يسار) ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // نقاط التنقل (المؤشر) في جهة اليسار
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: active ? _C.textDark : _C.textDark.withOpacity(0.2),
                        ),
                      );
                    }),
                  ),
                  
                  // زر تخطي في جهة اليمين بلون بوتن التالي
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => widget.nextScreen),
                    ),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text(
                      'تخطي',
                      style: TextStyle(
                        color: _C.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── وسط الشاشة: الصور والنصوص المتغيرة ───────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // ─── أسفل الشاشة: الأزرار الرئيسية وروابط الدخول ────────────────────
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OBData p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // تم تغليف الـ Container بـ Padding لتصغير حجم الصورة وإعطائها مساحة مريحة للعين
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // هنا تم تصغير الصورة من خلال الحواف
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06), // ظل ناعم وخفيف جداً متناسق مع الحجم الصغير
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    p.imagePath,
                    fit: BoxFit.cover, // يقص الأطراف لتأخذ انحناء الـ ClipRRect بشكل ممتاز
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // العنوان الرئيسي
          Text(
            p.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _C.textDark,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          // النص الفرعي والشرح
          Text(
            p.body,
            style: const TextStyle(
              fontSize: 18,
              color: _C.textMid,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 36),
      child: Column(
        children: [
          // الزر الرئيسي الكبير مع ظلال رمادية داكنة وبارزة بشكل حاد وجميل
          Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey[600]!.withOpacity(0.6),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                _isLastPage ? 'انطلق!' : 'التالي',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // نص "لديك حساب؟ ادخل هنا" أسفل الزر
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            child: RichText(
              textDirection: TextDirection.rtl,
              text: const TextSpan(
                style: TextStyle(
                  color: _C.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: 'لديك حساب؟ '),
                  TextSpan(
                    text: 'ادخل هنا',
                    style: TextStyle(
                      color: _C.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// كلاس البيانات الخاص بتهيئة عناصر شاشات التعريف
class _OBData {
  final String imagePath;
  final String title;
  final String body;

  const _OBData({
    required this.imagePath,
    required this.title,
    required this.body,
  });
}