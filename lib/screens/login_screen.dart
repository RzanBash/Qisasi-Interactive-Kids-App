import 'package:flutter/material.dart';
import '../services/auth_repository.dart';
import '../screens/home_screen.dart';
import 'signup_screen.dart';

// استيراد صفحة الأدمن داشبورد من المسار الصحيح
import '../screens/admin/admin_dashboard.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  // التحكم باسم المستخدم بدلاً من الإيميل
  final _usernameCtrl = TextEditingController(); 
  final _passCtrl = TextEditingController();

  bool _loading = false;
  bool _passVisible = false;
  bool _rememberMe = false;
  String? _errorMsg;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final _auth = AuthRepository();

  static const _bg = Color(0xFFF7F9FC); 
  static const _purple = Color(0xFF7C4DFF);
  static const _card = Color(0xFFFFFFFF);
  static const _txtDark = Color(0xFF2E2063);
  static const _txtMid = Color(0xFF7C6BA8);
  static const _border = Color(0xFFE8E0FF);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _prefill();
  }

  Future<void> _prefill() async {
    final creds = await _auth.getSavedCredentials();
    if (creds['username'] != null && mounted) {
      setState(() {
        _usernameCtrl.text = creds['username']!;
        _passCtrl.text = creds['pass'] ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    // إرسال اسم المستخدم بدلاً من الإيميل للدالة
    final result = await _auth.loginUser(
      _usernameCtrl.text,
      _passCtrl.text,
      rememberMe: _rememberMe,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      // الفحص والتوجيه الذكي بناءً على صلاحية الحساب
      if (result.isAdmin) {
        // إذا كان أدمن: يذهب لصفحة الـ AdminDashboardScreen بدون متغيرات
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen()),
          (_) => false,
        );
      } else {
        // إذا كان مستخدم عادي: يذهب لشاشة الـ HomeScreen مع تمرير الـ userId
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => HomeScreen(userId: result.user!.userId!)),
          (_) => false,
        );
      }
    } else {
      setState(() => _errorMsg = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 28),
                _hero(),
                const SizedBox(height: 40),
                _formCard(),
                const SizedBox(height: 40),
                _loginBtn(),
                const SizedBox(height: 20),
                _signupLink(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // تم تعديل هذه الدالة لحذف زر السهم الخلفي وجعل الترحيب متناسقاً في جهة اليمين


  Widget _hero() => Center(
        child: Column(children: [
          const SizedBox(height: 16),
          const Text('سجل دخولك',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: _txtDark)),
        ]),
      );

  Widget _formCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
                color: _purple.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 6))
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(children: [
            if (_errorMsg != null) _errBox(),
            _buildField(
              ctrl: _usernameCtrl,
              label: 'اسم المستخدم',
              hint: 'اكتب اسمك هنا',
              icon: const Icon(Icons.person, color: _txtMid, size: 22),
              keyboard: TextInputType.text,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'أدخل اسم المستخدم' : null,
            ),
            const SizedBox(height: 14),
            _buildField(
              ctrl: _passCtrl,
              label: 'كلمة المرور',
              hint: '••••••••',
              icon: const Icon(Icons.lock_outline, color: _txtMid, size: 22),
              obscure: !_passVisible,
              trailing: GestureDetector(
                onTap: () => setState(() => _passVisible = !_passVisible),
                child: Icon(
                  _passVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: _txtMid,
                  size: 22,
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'أدخل كلمة المرور' : null,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _rememberMe = !_rememberMe),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('تذكرني في المرة القادمة',
                      style: TextStyle(color: _txtMid, fontSize: 13),
                      textDirection: TextDirection.rtl),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _rememberMe ? _purple : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _rememberMe
                            ? _purple
                            : const Color(0xFFCCC0F0),
                        width: 2,
                      ),
                    ),
                    child: _rememberMe
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required Widget icon,
    bool obscure = false,
    TextInputType? keyboard,
    Widget? trailing,
    String? Function(String?)? validator,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text(label,
                style: const TextStyle(
                    color: _txtDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            obscureText: obscure,
            keyboardType: keyboard,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _txtDark, fontSize: 15),
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintTextDirection: TextDirection.rtl,
              hintStyle: TextStyle(
                  color: _txtMid.withOpacity(0.5), fontSize: 14),
              prefixIcon: icon, // يضع الأيقونة جهة اليسار تلقائياً مع الكتابة من اليمين لليسار RTL
              suffixIcon: trailing != null
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: trailing)
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8F5FF),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: _border, width: 1.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: _purple, width: 2)),
              errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFFF5252), width: 1.5)),
              focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: Color(0xFFFF5252), width: 2)),
              errorStyle: const TextStyle(
                  color: Color(0xFFFF5252), fontSize: 12),
            ),
          ),
        ],
      );

  Widget _errBox() => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(children: [
          const Text('😕', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_errorMsg!,
                  style: const TextStyle(
                      color: Color(0xFFD32F2F), fontSize: 13),
                  textDirection: TextDirection.rtl)),
        ]),
      );

  Widget _loginBtn() => SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _loading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            disabledBackgroundColor: _purple.withOpacity(0.4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 6,
            shadowColor: _purple.withOpacity(0.4),
          ),
          child: _loading
              ? const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : const Text('ادخل عالم القصص',
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                  textDirection: TextDirection.rtl),
        ),
      );

  Widget _signupLink() => Center(
        child: GestureDetector(
          onTap: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const SignUpScreen())),
          child: RichText(
            textDirection: TextDirection.rtl,
            text: const TextSpan(
              style: TextStyle(color: _txtMid, fontSize: 14),
              children: [
                TextSpan(text: 'ما عندك حساب؟ '),
                TextSpan(
                    text: 'أنشئ حساباً الآن',
                    style: TextStyle(
                        color: _purple,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      );
}