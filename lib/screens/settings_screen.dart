import 'package:flutter/material.dart';
import '../data/database/database_helper.dart';
import '../data/models/user_model.dart';
import '../services/auth_repository.dart';
import 'login_screen.dart';

class AvatarData {
  final String emoji;
  final String name;
  final String imagePath; 
  final List<Color> colors;

  const AvatarData(this.emoji, this.name, this.imagePath, this.colors);
}

const kAvatars = [
  AvatarData('🦁', 'الأسد الشجاع', 'assets/images/avatars/1.jpg',  [Color(0xFFFFB300), Color(0xFFFF6F00)]),
  AvatarData('🐬', 'الدولفين الذكي', 'assets/images/avatars/2.jpg', [Color(0xFF29B6F6), Color(0xFF0288D1)]),
  AvatarData('🦊', 'الثعلب الظريف', 'assets/images/avatars/3.jpg',  [Color(0xFFFF7043), Color(0xFFE64A19)]),
  AvatarData('🐸', 'الضفدع المرح', 'assets/images/avatars/4.jpg',   [Color(0xFF66BB6A), Color(0xFF2E7D32)]),
  AvatarData('🦄', 'اليونيكورن', 'assets/images/avatars/5.jpg',     [Color(0xFFCE93D8), Color(0xFF7B1FA2)]),
  AvatarData('🐧', 'البطريق الرائع', 'assets/images/avatars/6.jpg', [Color(0xFF78909C), Color(0xFF37474F)]),
  AvatarData('🐼', 'الباندا اللطيف', 'assets/images/avatars/7.jpg', [Color(0xFFBDBDBD), Color(0xFF424242)]),
  AvatarData('🦋', 'الفراشة الجميلة','assets/images/avatars/8.jpg', [Color(0xFFF48FB1), Color(0xFFC2185B)]),
  AvatarData('🐯', 'النمر القوي', 'assets/images/avatars/9.jpg',     [Color(0xFFFFCC80), Color(0xFFE65100)]),
  AvatarData('🦚', 'الطاووس الفاخر', 'assets/images/avatars/10.jpg', [Color(0xFF80CBC4), Color(0xFF00695C)]),
  AvatarData('🐺', 'الذئب الحكيم', 'assets/images/avatars/11.jpg',   [Color(0xFF90A4AE), Color(0xFF455A64)]),
  AvatarData('🦉', 'البومة العاقلة', 'assets/images/avatars/12.jpg', [Color(0xFFBCAAA4), Color(0xFF5D4037)]),
];

class SettingsScreen extends StatefulWidget {
  final int userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  UserModel? _user;
  bool _loading = true;
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _passVisible = false; // الافتراضي مخفي
  bool _saving = false;
  String? _saveError;
  String? _saveSuccess;
  String _selectedAvatar = '🦁';

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _bg      = Color(0xFFF7F9FC); 
  static const _purple  = Color(0xFF7C4DFF);
  static const _txtDark = Color(0xFF2E2063);
  static const _txtMid  = Color(0xFF7C6BA8);
  static const _border  = Color(0xFFE8E0FF);
  static const _green   = Color(0xFF43A047);
  static const _red     = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('Users', where: 'UserID = ?', whereArgs: [widget.userId]);
    if (rows.isEmpty || !mounted) return;
    final user = UserModel.fromMap(rows.first);
    setState(() {
      _user = user;
      _nameCtrl.text  = user.username;
      _emailCtrl.text = user.email;
      _passCtrl.text  = user.password;
      if (rows.first['Avatar'] != null) {
        _selectedAvatar = rows.first['Avatar'] as String;
      }
      _loading = false;
    });
  }

  AvatarData get _currentAvatar => kAvatars.firstWhere((a) => a.emoji == _selectedAvatar, orElse: () => kAvatars.first);

  Future<void> _saveChanges() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _saveError = 'الاسم لا يمكن أن يكون فارغاً');
      return;
    }
    setState(() { _saving = true; _saveError = null; _saveSuccess = null; });
    final db = await DatabaseHelper.instance.database;

    await db.update('Users', {
      'Username': _nameCtrl.text.trim(),
      'Email':    _emailCtrl.text.trim(),
      'Password': _passCtrl.text.isEmpty ? _user!.password : _passCtrl.text,
      'Avatar':   _selectedAvatar, 
    }, where: 'UserID = ?', whereArgs: [widget.userId]);

    await _loadUser();
    setState(() { _saving = false; _saveSuccess = 'تم حفظ التغييرات بنجاح'; });
    Future.delayed(const Duration(seconds: 3), () { if (mounted) setState(() => _saveSuccess = null); });
  }

  Future<void> _logout() async {
    await AuthRepository().logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose(); _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        // استخدام Directionality لضمان اتجاه اليمين إلى اليسار (RTL) لجميع العناصر والشاشات الفرعية
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _loading 
              ? const Center(child: CircularProgressIndicator(color: _purple)) 
              : FadeTransition(
                  opacity: _fadeAnim,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 8),
                              if (_saveSuccess != null) _banner(_saveSuccess!, _green),
                              if (_saveError != null)   _banner(_saveError!, _red),
                              _profileHeader(),
                              const SizedBox(height: 24),
                              _avatarSection(),
                              const SizedBox(height: 24),
                              _editSection(),
                              const SizedBox(height: 24),
                              _actionsSection(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
    backgroundColor: _bg, elevation: 0, pinned: true,
    // انعكاس أيقونة الرجوع لتناسب واجهة RTL العربية
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_rounded, color: _txtDark),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(Icons.settings_outlined, color: _txtDark),
        SizedBox(width: 8),
        Text('الإعدادات', style: TextStyle(color: _txtDark, fontWeight: FontWeight.bold)),
      ],
    ),
  );

  Widget _profileHeader() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: _currentAvatar.colors),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        CircleAvatar(radius: 35, backgroundColor: Colors.white24, child: Text(_selectedAvatar, style: const TextStyle(fontSize: 35))),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_user!.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(_user!.email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _avatarSection() => _SectionCard(
    title: 'اختر شخصيتك', 
    icon: Icons.face_outlined,
    child: GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: kAvatars.length,
      itemBuilder: (_, i) {
        final av = kAvatars[i];
        final isSel = _selectedAvatar == av.emoji;
        return GestureDetector(
          onTap: () => setState(() => _selectedAvatar = av.emoji),
          child: Container(
            decoration: BoxDecoration(
              color: isSel ? av.colors[0] : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isSel ? av.colors[1] : _border, width: 2),
            ),
            child: Center(child: Text(av.emoji, style: const TextStyle(fontSize: 25))),
          ),
        );
      },
    ),
  );

  Widget _editSection() => _SectionCard(
    title: 'تعديل البيانات', 
    icon: Icons.edit_outlined,
    child: Column(
      children: [
        const SizedBox(height: 10),
        // حقل اسم المستخدم
        TextField(
          controller: _nameCtrl, 
          textAlign: TextAlign.right, 
          decoration: const InputDecoration(
            labelText: 'اسم المستخدم',
            alignLabelWithHint: true,
            floatingLabelAlignment: FloatingLabelAlignment.start,
            prefixIcon: Icon(Icons.person_outline, color: _txtMid),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
        const SizedBox(height: 20), // مسافة مريحة وموسعة بين الحقول
        
        // حقل البريد الإلكتروني
        TextField(
          controller: _emailCtrl, 
          textAlign: TextAlign.right, 
          decoration: const InputDecoration(
            labelText: 'البريد الإلكتروني',
            alignLabelWithHint: true,
            floatingLabelAlignment: FloatingLabelAlignment.start,
            prefixIcon: Icon(Icons.email_outlined, color: _txtMid),
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          ),
        ),
        const SizedBox(height: 20), // مسافة مريحة وموسعة
        
        // حقل كلمة المرور مع العين التفاعلية لإظهار وإخفاء النص
        TextField(
          controller: _passCtrl, 
          textAlign: TextAlign.right, 
          obscureText: !_passVisible, 
          decoration: InputDecoration(
            labelText: 'كلمة المرور الجديدة',
            alignLabelWithHint: true,
            floatingLabelAlignment: FloatingLabelAlignment.start,
            prefixIcon: Icon(Icons.lock_outline, color: _txtMid),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            suffixIcon: IconButton(
              icon: Icon(
                _passVisible ? Icons.visibility : Icons.visibility_off,
                color: _txtMid,
              ),
              onPressed: () {
                setState(() {
                  _passVisible = !_passVisible;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 30), // مسافة إضافية قبل زر الحفظ لترتيب أفضل
        
        ElevatedButton.icon(
          onPressed: _saving ? null : _saveChanges, 
         
          label: Text(_saving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ),
  );

  Widget _actionsSection() => OutlinedButton.icon(
    onPressed: _logout, 
    label: const Text('تسجيل الخروج', style: TextStyle(color: _red)),
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: _red),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  );

  Widget _banner(String msg, Color col) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12), 
    decoration: BoxDecoration(
      color: col.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: col.withValues(alpha: 0.3)),
    ),
    child: Text(msg, style: TextStyle(color: col, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
  );
}

class _SectionCard extends StatelessWidget {
  final String title; 
  final IconData icon; 
  final Widget child;
  
  const _SectionCard({required this.title, required this.icon, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE8E0FF), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15), 
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start, // محاذاة العناوين لليمين في بيئة RTL بشكل متناسق
              children: [
                Icon(icon, color: const Color(0xFF7C4DFF)),
                const SizedBox(width: 8), 
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E2063))),
              ],
            ),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }
}