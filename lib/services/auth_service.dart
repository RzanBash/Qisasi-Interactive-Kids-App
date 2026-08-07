import '../../data/database/database_helper.dart';
import '../../data/models/user_model.dart';

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 1. منطق التسجيل (Sign Up)
  Future<int> registerUser(UserModel user) async {
    final db = await _dbHelper.database;
    // إضافة المستخدم وجدول قاعدة البيانات سيعيد الـ ID الجديد
    return await db.insert('Users', user.toMap());
  }

  // 2. منطق تسجيل الدخول (Login)
  Future<UserModel?> loginUser(String email, String password) async {
    final db = await _dbHelper.database;
    
    // البحث عن المستخدم بمطابقة الإيميل وكلمة المرور
    List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'Email = ? AND Password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null; // إذا لم يجد المستخدم أو البيانات خاطئة
  }

  // 3. التحقق من وجود الإيميل مسبقاً (لمنع التكرار)
  Future<bool> isEmailExists(String email) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps = await db.query(
      'Users',
      where: 'Email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }
}