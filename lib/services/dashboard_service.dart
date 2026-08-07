import 'package:sqflite/sqflite.dart';
import 'package:qisasi_app/data/database/database_helper.dart';

class DashboardService {
  final dbHelper = DatabaseHelper.instance;

  // 👤 عدد المستخدمين
  Future<int> getUsersCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Users');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 📚 عدد القصص
  Future<int> getStoriesCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Stories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 🎭 عدد الشخصيات
  Future<int> getCharactersCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Characters');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 🐾 عدد الحيوانات
  Future<int> getAnimalsCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Animals');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 📍 عدد الأماكن
  Future<int> getLocationsCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Locations');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // 🌈 عدد المودات
  Future<int> getMoodsCount() async {
    final db = await dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM Moods');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}