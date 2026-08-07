import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  static Database? _database;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "qisasi.db");

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE Users ADD COLUMN Avatar TEXT DEFAULT '🦁'",
          );
        }

        // ضفته
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE Users ADD COLUMN IsActive INTEGER DEFAULT 1",
          );
        }
      },
      onConfigure: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

  //  ضفته
  Future<void> fixStoriesData() async {
    final db = await database;

    await db.rawUpdate('''
    UPDATE Stories
    SET LocationID = 1
    WHERE LocationID IS NULL 
       OR LocationID = 0 
       OR LocationID NOT IN (SELECT LocationID FROM Locations)
  ''');

    await db.rawUpdate('''
    UPDATE Stories
    SET MoodID = 1
    WHERE MoodID IS NULL 
       OR MoodID = 0 
       OR MoodID NOT IN (SELECT MoodID FROM Moods)
  ''');
  }

  Future _onCreate(Database db, int version) async {
    // 1. Users

    await db.execute('''CREATE TABLE Users (
      UserID INTEGER PRIMARY KEY AUTOINCREMENT,
      Username TEXT UNIQUE,
      Password TEXT,
      Email TEXT,
      Gender TEXT,
      Age INTEGER,
      Avatar TEXT DEFAULT '🦁' ,
           
           
      IsActive INTEGER DEFAULT 1    

    )'''); // IsActive INTEGER DEFAULT 1   ضفته

    // 2. Roles
    await db.execute('''CREATE TABLE Roles (
      RoleID INTEGER PRIMARY KEY AUTOINCREMENT,
      RoleName TEXT
    )''');

    // 3. UserRoles
    await db.execute('''CREATE TABLE UserRoles (
      UserID INTEGER,
      RoleID INTEGER,
      PRIMARY KEY (UserID, RoleID),
      FOREIGN KEY (UserID) REFERENCES Users (UserID) ON DELETE CASCADE,
      FOREIGN KEY (RoleID) REFERENCES Roles (RoleID) ON DELETE CASCADE
    )''');

    // 4. Permissions
    await db.execute('''CREATE TABLE Permissions (
      PermissionID INTEGER PRIMARY KEY AUTOINCREMENT,
      PermissionName TEXT
    )''');

    // 5. RolePermission
    await db.execute('''CREATE TABLE RolePermission (
      RoleID INTEGER,
      PermissionID INTEGER,
      PRIMARY KEY (RoleID, PermissionID),
      FOREIGN KEY (RoleID) REFERENCES Roles (RoleID) ON DELETE CASCADE,
      FOREIGN KEY (PermissionID) REFERENCES Permissions (PermissionID) ON DELETE CASCADE
    )''');

    // 6. Stories
    await db.execute('''CREATE TABLE Stories (
      StoryID INTEGER PRIMARY KEY AUTOINCREMENT,
      Title TEXT,
      Content TEXT,
      CoverImage TEXT,
      isCustomized INTEGER DEFAULT 0,
      UserID INTEGER,
      LocationID INTEGER,
      MoodID INTEGER,
      FOREIGN KEY (UserID) REFERENCES Users (UserID),
      FOREIGN KEY (LocationID) REFERENCES Locations (LocationID),
      FOREIGN KEY (MoodID) REFERENCES Moods (MoodID)
    )''');

    // 7. Favorites
    await db.execute('''CREATE TABLE Favorites (
      FavoriteID INTEGER PRIMARY KEY AUTOINCREMENT,
      UserID INTEGER,
      StoryID INTEGER,
      CreatedAt TEXT DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (UserID) REFERENCES Users (UserID) ON DELETE CASCADE,
      FOREIGN KEY (StoryID) REFERENCES Stories (StoryID) ON DELETE CASCADE,
      UNIQUE(UserID, StoryID) 
    )''');

    // 8. Characters (أضيف حقل ImagePath)
    await db.execute('''CREATE TABLE Characters (
      CharacterID INTEGER PRIMARY KEY AUTOINCREMENT,
      CharacterName TEXT,
      ImagePath TEXT
    )''');

    // 9. StoryCharacters
    await db.execute('''CREATE TABLE StoryCharacters (
      CharacterID INTEGER,
      StoryID INTEGER,
      PRIMARY KEY (CharacterID, StoryID),
      FOREIGN KEY (CharacterID) REFERENCES Characters (CharacterID) ON DELETE CASCADE,
      FOREIGN KEY (StoryID) REFERENCES Stories (StoryID) ON DELETE CASCADE
    )''');

    // 10. Animals (أضيف حقل ImagePath)
    await db.execute('''CREATE TABLE Animals (
      AnimalID INTEGER PRIMARY KEY AUTOINCREMENT,
      AnimalName TEXT,
      ImagePath TEXT
    )''');

    // 11. StoryAnimals
    await db.execute('''CREATE TABLE StoryAnimals (
      AnimalID INTEGER,
      StoryID INTEGER,
      PRIMARY KEY (AnimalID, StoryID),
      FOREIGN KEY (AnimalID) REFERENCES Animals (AnimalID) ON DELETE CASCADE,
      FOREIGN KEY (StoryID) REFERENCES Stories (StoryID) ON DELETE CASCADE
    )''');

    // 12. Moods (أضيف حقل ImagePath)
    await db.execute('''CREATE TABLE Moods (
      MoodID INTEGER PRIMARY KEY AUTOINCREMENT,
      MoodName TEXT,
      ImagePath TEXT
    )''');

    // 13. Locations (أضيف حقل ImagePath)
    await db.execute('''CREATE TABLE Locations (
      LocationID INTEGER PRIMARY KEY AUTOINCREMENT,
      LocationName TEXT,
      ImagePath TEXT
    )''');

    // 14. Activity
    await db.execute('''CREATE TABLE Activity (
      ActivityID INTEGER PRIMARY KEY AUTOINCREMENT,
      UserID INTEGER,
      StoryID INTEGER,
      LogDate TEXT DEFAULT CURRENT_TIMESTAMP,
      Duration INTEGER,
      FOREIGN KEY (UserID) REFERENCES Users (UserID) ON DELETE CASCADE,
      FOREIGN KEY (StoryID) REFERENCES Stories (StoryID) ON DELETE CASCADE
    )''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    try {
      await _insertStaticData(db);

      final String response = await rootBundle.loadString(
        'assets/stories_data/stories.json',
      );
      final List<dynamic> data = json.decode(response);

      for (var story in data) {
        final int currentId = story['StoryID'];
        await db.insert('Stories', {
          'StoryID': currentId,
          'Title': story['Title'],
          'Content': story['StoryContent'],
          'CoverImage': 'assets/images/covers/$currentId.png',
          'isCustomized': (currentId <= 160) ? 1 : 0,
          'LocationID':
              (story['LocationID'] == null || story['LocationID'] == 0)
              ? 1
              : story['LocationID'],
          'MoodID': (story['MoodID'] == null || story['MoodID'] == 0)
              ? 1
              : story['MoodID'],
          'UserID': 1,
        });

        if (story['CharacterID'] != null && story['CharacterID'] != 0) {
          await db.insert('StoryCharacters', {
            'StoryID': currentId,
            'CharacterID': story['CharacterID'],
          });
        }

        if (story['AnimalID'] != null && story['AnimalID'] != 0) {
          await db.insert('StoryAnimals', {
            'StoryID': currentId,
            'AnimalID': story['AnimalID'],
          });
        }
      }
      print('✅ نجاح: تم إنشاء قاعدة البيانات بنجاح.');
    } catch (e) {
      print('❌ خطأ أثناء تعبئة قاعدة البيانات: $e');
      rethrow;
    }
  }

  Future<void> _insertStaticData(Database db) async {
    // تعبئة Moods مع الصور
    var moods = ['تعليمي', 'مرح', 'قبل النوم'];
    for (int i = 0; i < moods.length; i++) {
      int id = i + 1;
      await db.insert('Moods', {
        'MoodID': id,
        'MoodName': moods[i],
        'ImagePath': 'assets/images/moods/$id.png',
      });
    }

    // تعبئة Locations مع الصور
    var locations = ['غابة', 'منزل', 'فضاء', 'مدرسة', 'بحر'];
    for (int i = 0; i < locations.length; i++) {
      int id = i + 1;
      await db.insert('Locations', {
        'LocationID': id,
        'LocationName': locations[i],
        'ImagePath': 'assets/images/locations/$id.png',
      });
    }

    // تعبئة Characters مع الصور
    var characters = [
      'طفل',
      'بطل خارق',
      'أميرة',
      'معلم',
      'طبيب',
      'أصدقاء',
      'رائد فضاء',
      'مخترع',
    ];
    for (int i = 0; i < characters.length; i++) {
      int id = i + 1;
      await db.insert('Characters', {
        'CharacterID': id,
        'CharacterName': characters[i],
        'ImagePath': 'assets/images/characters/$id.png',
      });
    }

    // تعبئة Animals مع الصور
    var animals = ['أسد', 'كلب', 'سلحفاة', 'فيل', 'قطة'];
    for (int i = 0; i < animals.length; i++) {
      int id = i + 1;
      await db.insert('Animals', {
        'AnimalID': id,
        'AnimalName': animals[i],
        'ImagePath': 'assets/images/animals/$id.png',
      });
    }

    await db.insert('Roles', {'RoleName': 'admin'});
    await db.insert('Roles', {'RoleName': 'child'});

    await db.insert('Users', {
      'UserID': 1,
      'Username': 'Admin',
      'Password': '123',
      'Email': 'admin@gmail.com',
      'Gender': 'Female',
      'Age': 25,
      'Avatar': '🦉',
    });
    await db.insert('UserRoles', {'UserID': 1, 'RoleID': 1});

    await db.insert('Users', {
      'UserID': 2,
      'Username': 'Ahmed',
      'Password': '000',
      'Email': 'ahmed@gmail.com',
      'Gender': 'male',
      'Age': 7,
      'Avatar': '🦁',
    });
    await db.insert('UserRoles', {'UserID': 2, 'RoleID': 2});
  }

  Future<Map<String, dynamic>?> getLastActivityForChild(int childId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT a.*, s.Title as StoryTitle 
      FROM Activity a
      JOIN Stories s ON a.StoryID = s.StoryID
      WHERE a.UserID = ?
      ORDER BY a.LogDate DESC
      LIMIT 1
    ''',
      [childId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllActivitiesForChild(
    int childId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT a.*, s.Title as StoryTitle 
      FROM Activity a
      JOIN Stories s ON a.StoryID = s.StoryID
      WHERE a.UserID = ?
      ORDER BY a.LogDate DESC
    ''',
      [childId],
    );
  }

  Future<Map<String, dynamic>> getChildSummary(int childId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as totalStoriesRead,
        COALESCE(SUM(Duration), 0) as totalMinutesSpent
      FROM Activity
      WHERE UserID = ?
    ''',
      [childId],
    );

    return {
      'totalStoriesRead': result.first['totalStoriesRead'] ?? 0,
      'totalMinutesSpent': result.first['totalMinutesSpent'] ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getCharacterStats(int childId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT c.CharacterName, COUNT(*) as count
      FROM Activity a
      JOIN Stories s ON a.StoryID = s.StoryID
      JOIN StoryCharacters sc ON s.StoryID = sc.StoryID
      JOIN Characters c ON sc.CharacterID = c.CharacterID
      WHERE a.UserID = ?
      GROUP BY c.CharacterID
      ORDER BY count DESC
      LIMIT 5
    ''',
      [childId],
    );
  }

  Future<List<Map<String, dynamic>>> getLocationStats(int childId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT l.LocationName, COUNT(*) as count
      FROM Activity a
      JOIN Stories s ON a.StoryID = s.StoryID
      JOIN Locations l ON s.LocationID = l.LocationID
      WHERE a.UserID = ? AND s.LocationID IS NOT NULL
      GROUP BY l.LocationID
      ORDER BY count DESC
      LIMIT 5
    ''',
      [childId],
    );
  }

  Future<List<Map<String, dynamic>>> getMoodStats(int childId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT m.MoodName, COUNT(*) as count
      FROM Activity a
      JOIN Stories s ON a.StoryID = s.StoryID
      JOIN Moods m ON s.MoodID = m.MoodID
      WHERE a.UserID = ? AND s.MoodID IS NOT NULL
      GROUP BY m.MoodID
      ORDER BY count DESC
      LIMIT 5
    ''',
      [childId],
    );
  }

  Future<List<Map<String, dynamic>>> getAnimalStats(int childId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT a.AnimalName, COUNT(*) as count
    FROM Activity ac
    JOIN Stories s ON ac.StoryID = s.StoryID
    JOIN StoryAnimals sa ON s.StoryID = sa.StoryID
    JOIN Animals a ON sa.AnimalID = a.AnimalID
    WHERE ac.UserID = ? AND sa.AnimalID IS NOT NULL
    GROUP BY a.AnimalID
    ORDER BY count DESC
    LIMIT 5
    ''',
      [childId],
    );
  }

  Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    final result = await db.query(
      'Users',
      where: 'UserID = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<int> getTotalReadingTime(int childId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(Duration), 0) as totalSeconds
    FROM Activity
    WHERE UserID = ?
    ''',
      [childId],
    );

    // ✅ معالجة القيمة بشكل آمن
    final dynamic value = result.first['totalSeconds'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<Map<String, dynamic>?> getLastActivityWithRealTime(int childId) async {
    final db = await database;
    final result = await db.rawQuery(
      '''
    SELECT a.*, s.Title as StoryTitle 
    FROM Activity a
    JOIN Stories s ON a.StoryID = s.StoryID
    WHERE a.UserID = ?
    ORDER BY a.LogDate DESC
    LIMIT 1
    ''',
      [childId],
    );

    if (result.isEmpty) return null;

    // ✅ تحويل LogDate إلى DateTime مع معالجة الأخطاء
    String? logDateStr = result.first['LogDate'] as String?;
    DateTime dateTime;

    if (logDateStr != null && logDateStr.isNotEmpty) {
      try {
        dateTime = DateTime.parse(
          logDateStr,
        ).toLocal(); // ✅ تحويل إلى التوقيت المحلي
      } catch (e) {
        dateTime = DateTime.now();
      }
    } else {
      dateTime = DateTime.now();
    }

    // ✅ معالجة Duration بشكل آمن
    dynamic durationValue = result.first['Duration'];
    int duration = 0;
    if (durationValue is int) {
      duration = durationValue;
    } else if (durationValue is String) {
      duration = int.tryParse(durationValue) ?? 0;
    }

    return {
      'StoryTitle': result.first['StoryTitle']?.toString() ?? 'عنوان غير معروف',
      'LogDate': dateTime,
      'Duration': duration,
    };
  }

  Future<int> insertActivityWithRealTime(
    int userId,
    int storyId,
    int durationSeconds,
  ) async {
    final db = await database;

    // ✅ استخدام toIso8601String() لحفظ الوقت مع المنطقة الزمنية
    final now = DateTime.now().toIso8601String();

    // ✅ التأكد من أن durationSeconds رقم صحيح
    int finalDuration = durationSeconds is int ? durationSeconds : 0;

    return await db.insert('Activity', {
      'UserID': userId,
      'StoryID': storyId,
      'Duration': finalDuration,
      'LogDate': now,
    });
  }

 
  // جلب المستخدمين مع الدور الحقيقي
  Future<List<Map<String, dynamic>>> getUsersWithRoles() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      u.UserID,
      u.Username,
      u.Email,
      u.IsActive,
      IFNULL(r.RoleName, 'child') AS RoleName
    FROM Users u
    LEFT JOIN UserRoles ur ON u.UserID = ur.UserID
    LEFT JOIN Roles r ON ur.RoleID = r.RoleID
  ''');
  }

  Future<int> insertUserWithRole({
    required String username,
    required String email,
    required String password,
    required int roleId,
  }) async {
    final db = await database;

    // 1️⃣ إدخال المستخدم
    int userId = await db.insert("Users", {
      "Username": username,
      "Email": email,
      "Password": password,
    });

    // 2️⃣ ربطه بالدور
    await db.insert("UserRoles", {"UserID": userId, "RoleID": roleId});

    return userId;
  }

  Future<void> updateUserWithRole({
    required int userId,
    required String username,
    required String email,
    required int roleId,
    String password = '',
  }) async {
    final db = await database;

    Map<String, dynamic> data = {"Username": username, "Email": email};

    // إذا كتب باسورد جديد
    if (password.isNotEmpty) {
      data["Password"] = password;
    }

    await db.update("Users", data, where: "UserID = ?", whereArgs: [userId]);

    await db.update(
      "UserRoles",
      {"RoleID": roleId},
      where: "UserID = ?",
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(int userId) async {
    final db = await database;

    await db.delete("UserRoles", where: "UserID = ?", whereArgs: [userId]);

    await db.delete("Users", where: "UserID = ?", whereArgs: [userId]);
  }

  // ضفت
  Future<List<Map<String, dynamic>>> getStoriesWithDetails({
    int? moodId,
    int? locationId,
  }) async {
    final db = await database;

    String query = '''
    SELECT 
      s.*,
      l.LocationName,
      m.MoodName
    FROM Stories s
    LEFT JOIN Locations l ON s.LocationID = l.LocationID
    LEFT JOIN Moods m ON s.MoodID = m.MoodID
    WHERE 1=1
  ''';

    List<dynamic> args = [];

    if (moodId != null) {
      query += ' AND s.MoodID = ?';
      args.add(moodId);
    }

    if (locationId != null) {
      query += ' AND s.LocationID = ?';
      args.add(locationId);
    }

    query += ' ORDER BY s.StoryID DESC';

    return await db.rawQuery(query, args);
  }

  // اضفته
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<int> insertItem(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data);
  }

  String cleanValue(dynamic value) {
    if (value == null) return '';
    final v = value.toString().trim();
    if (v == '0') return '';
    return v;
  }

  // 🔵 Update عام لأي جدول
  Future<int> updateItem(
    String table,
    String idCol,
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;

    return await db.update(table, data, where: "$idCol = ?", whereArgs: [id]);
  }

  Future<int> deleteItem(String table, String idCol, int id) async {
    final db = await database;
    return await db.delete(table, where: '$idCol = ?', whereArgs: [id]);
  }

  // ضفته
  Future<void> freezeUser(int userId) async {
    final db = await database;

    await db.update(
      "Users",
      {"IsActive": 0},
      where: "UserID = ?",
      whereArgs: [userId],
    );
  }

  Future<void> activateUser(int userId) async {
    final db = await database;

    await db.update(
      "Users",
      {"IsActive": 1},
      where: "UserID = ?",
      whereArgs: [userId],
    );
  }
}
