import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/user_model.dart';

class AuthRepository {
  static const String _keyUserId    = 'saved_user_id';
  static const String _keyRemember  = 'remember_me';
  static const String _keyUsername  = 'saved_username'; 
  static const String _keyPass      = 'saved_pass';
  
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // ─── تسجيل مستخدم جديد (إضافة الأفاتار الافتراضي) ─────────────────
  
  Future<AuthResult> registerUser(UserModel user) async {
    final db = await _db.database;

    final dup = await db.rawQuery(
      "SELECT UserID FROM Users WHERE LOWER(Username) = LOWER(?)",
      [user.username.trim()],
    );

    if (dup.isNotEmpty) {
      return AuthResult.failure('هذا الاسم مستخدم مسبقاً، اختر اسماً آخر 👤');
    }

    // تم إضافة 'Avatar' هنا ليتم حفظه عند التسجيل لأول مرة
    final userId = await db.insert('Users', {
      'Username': user.username.trim(),
      'Password': user.password,
      'Email':    user.email.trim(),
      'Gender':   user.gender,
      'Age':      user.age,
      'Avatar':   user.avatar ?? '🦁', // إذا لم يختر، نضع الأسد كافتراضي
    });

    await db.insert('UserRoles', {'UserID': userId, 'RoleID': 2}); 
    await _saveSession(userId);

    return AuthResult.success(
      UserModel(
        userId:   userId,
        username: user.username,
        email:    user.email,
        password: user.password,
        gender:   user.gender,
        age:      user.age,
        avatar:   user.avatar ?? '🦁', // إرجاع المودل مع الأفاتار
      ),
      isAdmin: false,
    );
  }
  
  // ─── تسجيل الدخول (يعمل تلقائياً لأن UserModel.fromMap يتعامل مع الأفاتار) ───
  
  Future<AuthResult> loginUser(
    String username,
    String password, {
    bool rememberMe = false,
  }) async {
    final db = await _db.database;

    final rows = await db.rawQuery(
      "SELECT * FROM Users WHERE LOWER(Username) = LOWER(?) AND Password = ?",
      [username.trim(), password],
    );

    if (rows.isEmpty) {
      return AuthResult.failure('أوه! اسم المستخدم أو كلمة المرور غير صحيحة 😕');
    }

    // هنا UserModel.fromMap سيقوم تلقائياً بجلب الأفاتار من السطر (Row)
    final user = UserModel.fromMap(rows.first);

    final roleRows = await db.rawQuery('''
      SELECT r.RoleName FROM Roles r
      JOIN UserRoles ur ON r.RoleID = ur.RoleID
      WHERE ur.UserID = ?
    ''', [user.userId]);

    final admin = roleRows.any(
      (r) => (r['RoleName'] as String).toLowerCase() == 'admin',
    );

    await _saveSession(user.userId!);

    if (rememberMe) {
      await _saveCredentials(username.trim(), password);
    } else {
      await _clearCredentials();
    }

    return AuthResult.success(user, isAdmin: admin);
  }
  
  // ─── بقية الدوال (getSavedUser و getSavedCredentials) ──────────────────────
  
  // ملاحظة: دالة getSavedUser ستعمل بشكل صحيح الآن لأنها تستخدم UserModel.fromMap
  Future<UserModel?> getSavedUser() async {
    final userId = await getSavedUserId();
    if (userId == null) return null;
    final db = await _db.database;
    final rows = await db.query('Users', where: 'UserID = ?', whereArgs: [userId]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  // ... (بقية الدوال تبقى كما هي تماماً) ...
  
  Future<void> _saveCredentials(String username, String pass) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyRemember, true);
    await p.setString(_keyUsername, username); 
    await p.setString(_keyPass, pass);
  }
  
  Future<void> _clearCredentials() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyRemember);
    await p.remove(_keyUsername);
    await p.remove(_keyPass);
  }
  
  Future<Map<String, String?>> getSavedCredentials() async {
    final p = await SharedPreferences.getInstance();
    final remember = p.getBool(_keyRemember) ?? false;
    if (!remember) return {'username': null, 'pass': null};
    return {
      'username': p.getString(_keyUsername), 
      'pass': p.getString(_keyPass)
    };
  }
  
  Future<void> _saveSession(int userId) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_keyUserId, userId);
  }
  
  Future<int?> getSavedUserId() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_keyUserId);
  }
  
  Future<bool> isAdmin(int userId) async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT r.RoleName FROM Roles r
      JOIN UserRoles ur ON r.RoleID = ur.RoleID
      WHERE ur.UserID = ?
    ''', [userId]);
    return rows.any((r) => (r['RoleName'] as String).toLowerCase() == 'admin');
  }
  
  Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_keyUserId);
  }
}

class AuthResult {
  final bool success;
  final UserModel? user;
  final bool isAdmin;
  final String? errorMessage;
  
  AuthResult._({required this.success, this.user, this.isAdmin = false, this.errorMessage});
  
  factory AuthResult.success(UserModel user, {required bool isAdmin}) =>
      AuthResult._(success: true, user: user, isAdmin: isAdmin);
  
  factory AuthResult.failure(String msg) =>
      AuthResult._(success: false, errorMessage: msg);
}