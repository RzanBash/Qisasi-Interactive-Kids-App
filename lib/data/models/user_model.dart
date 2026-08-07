class UserModel {
  final int? userId;
  final String username;
  final String email;
  final String password;
  final String gender;
  final int age;
  final String? avatar; // 👈 الحقل الجديد المضاف

  UserModel({
    this.userId,
    required this.username,
    required this.email,
    required this.password,
    required this.gender,
    required this.age,
    this.avatar, // 👈 تمت إضافته هنا كاختياري
  });

  // تحويل البيانات من Map (القاعدة) إلى Object (دارت)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['UserID'], 
      username: map['Username'],
      email: map['Email'],
      password: map['Password'],
      gender: map['Gender'],
      age: map['Age'],
      avatar: map['Avatar'], // 👈 تأكد أن الاسم يطابق العمود في SQL تماماً
    );
  }

  // تحويل الـ Object إلى Map ليتم تخزينه في القاعدة
  Map<String, dynamic> toMap() {
    return {
      'UserID': userId,
      'Username': username,
      'Email': email,
      'Password': password,
      'Gender': gender,
      'Age': age,
      'Avatar': avatar, // 👈 سيتم تخزين الأفاتار المختار هنا
    };
  }
}