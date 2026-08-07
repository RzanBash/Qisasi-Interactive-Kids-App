import 'package:flutter/material.dart';
import '../services/auth_repository.dart';
import '../data/models/user_model.dart';
import '../screens/home_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();

  String _gender    = 'male';
  double _ageSlider = 7;
  bool _loading     = false;
  bool _passVis     = false;
  bool _confVis     = false;
  String? _error;

  // ─── بيانات الأفاتار ──────────────────────
  String _selectedAvatar = '🦁'; 
  final List<String> _avatars = ['🦁', '🐬', '🦊', '🐸', '🦄', '🐧', '🦋', '🦉', '🐯'];
  // ──────────────────────────────────────────────────────────

  late AnimationController _slideCtrl;
  late Animation<Offset> _slideAnim;

  // قوة كلمة المرور
  int get _passStrength {
    final p = _passCtrl.text;
    if (p.length < 3) return 0;
    if (p.length < 5) return 1;
    if (p.length < 8) return 2;
    return 3;
  }

  static const _strengthEmoji = ['🔴 ضعيفة جداً', '🟡 مقبولة', '🟠 جيدة', '🟢 بطل!'];
  static const _strengthColors = [
    Color(0xFFEF5350), Color(0xFFFFB300),
    Color(0xFFFF7043), Color(0xFF66BB6A),
  ];

  static const _bg      = Color(0xFFF7F9FC); 
  static const _purple  = Color(0xFF7C4DFF);
  static const _orange  = Color(0xFFFF7043);
  static const _txtDark = Color(0xFF2E2063);
  static const _txtMid  = Color(0xFF7C6BA8);
  static const _border  = Color(0xFFE8E0FF);
  static const _card    = Colors.white;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(() => setState(() {}));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    final result = await AuthRepository().registerUser(UserModel(
      username: _nameCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
      gender:   _gender,
      age:      _ageSlider.round(),
      avatar:   _selectedAvatar,
    ));

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(userId: result.user!.userId!)),
        (_) => false,
      );
    } else {
      setState(() => _error = result.errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 20),
                _header(),
                const SizedBox(height: 24),
                _avatarSection(), 
                const SizedBox(height: 24),
                _formCard(),
                const SizedBox(height: 24),
                _genderCard(),
                const SizedBox(height: 20),
                _ageCard(),
                const SizedBox(height: 28),
                _submitBtn(),
                const SizedBox(height: 18),
                _loginLink(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── ودجت اختيار الأفاتار ──────────────────────
  Widget _avatarSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        const Text('اختر شخصيتك الإفتراضية',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txtDark),
          textDirection: TextDirection.rtl),
        const SizedBox(width: 6),
      ]),
      const SizedBox(height: 14),
      SizedBox(
        height: 85,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: true, 
          itemCount: _avatars.length,
          itemBuilder: (context, i) {
            final av = _avatars[i];
            final sel = _selectedAvatar == av;
            return GestureDetector(
              onTap: () => setState(() => _selectedAvatar = av),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 75,
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: sel ? _purple : _card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sel ? _purple : _border, width: sel ? 2.5 : 1.5),
                  boxShadow: sel ? [BoxShadow(color: _purple.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                ),
                child: Center(child: Text(av, style: const TextStyle(fontSize: 38))),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      const Text('أنشئ حسابك',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _txtDark),
        textDirection: TextDirection.rtl,
      ),
    ],
  );

  Widget _formCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: _purple.withOpacity(0.07),
          blurRadius: 16,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          if (_error != null) _errBox(),

          // حقل الاسم
          _qField(_nameCtrl, 'الاسم', 'ما اسمك؟', Icons.person_outline,
              validator: (v) => (v == null || v.isEmpty) ? 'أدخل اسمك' : null),
          const SizedBox(height: 14),

          // حقل البريد الإلكتروني
          _qField(_emailCtrl, 'البريد الإلكتروني', 'username@gmail.com', Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                
                final emailValue = v.trim().toLowerCase();
                
                if (!emailValue.endsWith('@gmail.com')) {
                  return 'يجب أن ينتهي البريد بـ @gmail.com';
                }
                
                if (emailValue.length <= 10) {
                  return 'يرجى كتابة اسم المستخدم قبل @gmail.com';
                }
                
                return null;
              }),
          const SizedBox(height: 14),

          // حقل كلمة المرور
          _qField(_passCtrl, 'كلمة المرور', '••••••••', Icons.lock_outline,
              obscure: !_passVis,
              trailing: GestureDetector(
                  onTap: () => setState(() => _passVis = !_passVis),
                  child: Icon(_passVis ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _txtMid, size: 22)),
              validator: (v) {
                if (v == null || v.length < 3) return 'كلمة المرور قصيرة جداً';
                return null;
              }),

          // مؤشر قوة كلمة المرور
          if (_passCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _strengthIndicator(),
          ],
          const SizedBox(height: 14),

          // حقل تأكيد كلمة المرور
          _qField(_confirmCtrl, 'تأكيد كلمة المرور', '••••••••', Icons.lock_clock_outlined,
              obscure: !_confVis,
              trailing: GestureDetector(
                  onTap: () => setState(() => _confVis = !_confVis),
                  child: Icon(_confVis ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: _txtMid, size: 22)),
              validator: (v) {
                if (v != _passCtrl.text) return 'كلمة المرور غير متطابقة';
                return null;
              }),
        ],
      ),
    ),
  );

  Widget _strengthIndicator() {
    final s = _passStrength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(_strengthEmoji[s],
              style: TextStyle(fontSize: 13, color: _strengthColors[s],
                fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(3, (i) {
            final filled = s > i;
            return Expanded(child: Container(
              margin: EdgeInsets.only(right: i > 0 ? 4 : 0),
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: filled ? _strengthColors[s] : const Color(0xFFE8E0FF),
              ),
            ));
          }).reversed.toList(),
        ),
      ],
    );
  }

  Widget _genderCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(
        color: _orange.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          const Text('الجنس',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txtDark),
            textDirection: TextDirection.rtl),
          const SizedBox(width: 6),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _genderChip('أنثى', 'female', Icons.female)),
          const SizedBox(width: 12),
          Expanded(child: _genderChip('ذكر', 'male', Icons.male)),
        ]),
      ],
    ),
  );

  Widget _genderChip(String label, String value, IconData icon) {
    final sel = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        decoration: BoxDecoration(
          gradient: sel ? const LinearGradient(
            colors: [Color(0xFFFF7043), Color(0xFFFFB74D)],
          ) : null,
          color: sel ? null : const Color(0xFFFFF3EE),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? _orange : const Color(0xFFFFCCBC),
            width: sel ? 2 : 1.5,
          ),
          boxShadow: sel ? [BoxShadow(
            color: _orange.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3),
          )] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: sel ? Colors.white : _orange, size: 20),
            const SizedBox(width: 6),
            Text(label,
              style: TextStyle(
                color: sel ? Colors.white : _orange,
                fontWeight: FontWeight.bold, fontSize: 15,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ageCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _border),
      boxShadow: [BoxShadow(
        color: _purple.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end, 
          children: [
            const Text('كم عمرك؟',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _txtDark),
              textDirection: TextDirection.rtl),
          ],
        ),
        const SizedBox(height: 8),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _purple,
            inactiveTrackColor: const Color(0xFFE8E0FF),
            thumbColor: _purple,
            overlayColor: _purple.withOpacity(0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            trackHeight: 6,
          ),
          child: Slider(
            value: _ageSlider,
            min: 6, max: 10, divisions: 4,
            onChanged: (v) => setState(() => _ageSlider = v),
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              final age = 6 + i;
              final sel = _ageSlider.round() == age;
              return Text('$age',
                style: TextStyle(
                  color: sel ? _purple : _txtMid,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  fontSize: sel ? 16 : 12, // تكبير الخط عند الاختيار ليبرز
                ));
            }),
          ),
        ),
      ],
    ),
  );

  Widget _qField(
    TextEditingController ctrl,
    String label, String hint, IconData icon, {
    bool obscure = false,
    TextInputType? keyboard,
    Widget? trailing,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(label, style: const TextStyle(
            color: _txtDark, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
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
            hintStyle: TextStyle(color: _txtMid.withOpacity(0.5), fontSize: 14),
            prefixIcon: Icon(icon, color: _txtMid.withOpacity(0.6), size: 20),
            suffixIcon: trailing != null
                ? Padding(padding: const EdgeInsets.all(12), child: trailing)
                : null,
            filled: true, fillColor: const Color(0xFFF8F5FF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border, width: 1.5)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _purple, width: 2)),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF5252), width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF5252), width: 2)),
            errorStyle: const TextStyle(color: Color(0xFFFF5252), fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _errBox() => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFCDD2)),
    ),
    child: Row(children: [
      const Text('😅', style: TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(child: Text(_error!,
        style: const TextStyle(color: Color(0xFFD32F2F), fontSize: 13),
        textDirection: TextDirection.rtl)),
    ]),
  );

  Widget _submitBtn() => SizedBox(
    width: double.infinity, height: 58,
    child: ElevatedButton(
      onPressed: _loading ? null : _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: _purple,
        disabledBackgroundColor: _purple.withOpacity(0.4),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6, shadowColor: _purple.withOpacity(0.4),
      ),
      child: _loading
          ? const SizedBox(width: 26, height: 26,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
          : const Text('إنشاء الحساب',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              textDirection: TextDirection.rtl),
    ),
  );

  Widget _loginLink() => Center(
    child: GestureDetector(
      onTap: () => Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen())),
      child: RichText(
        textDirection: TextDirection.rtl,
        text: const TextSpan(
          style: TextStyle(color: _txtMid, fontSize: 14),
          children: [
            TextSpan(text: 'لديك حساب؟ '),
            TextSpan(text: 'سجل دخولك هنا',
              style: TextStyle(color: _purple, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    ),
  );
}