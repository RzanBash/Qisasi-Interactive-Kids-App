import 'dart:math';
import '../data/database/database_helper.dart';
import '../data/models/story_model.dart';

class StoryEngine {
  final DatabaseHelper _db = DatabaseHelper.instance;

  static const int _moodWeight = 5;
  static const int _characterWeight = 3;
  static const int _locationWeight = 3;
  static const int _animalWeight = 2;

  // ─── محرك المطابقة ────────────────────────────────────────────────────────
  Future<StoryModel?> findBestStory({
    required int moodId,
    required int locationId,
    int? characterId,
    int? animalId,
  }) async {
    final db = await _db.database;
    final List<Map<String, dynamic>> rawStories = await db.rawQuery('''
      SELECT s.*, sc.CharacterID, sa.AnimalID
      FROM Stories s
      LEFT JOIN StoryCharacters sc ON s.StoryID = sc.StoryID
      LEFT JOIN StoryAnimals    sa ON s.StoryID = sa.StoryID
      WHERE s.isCustomized = 1
    ''');

    if (rawStories.isEmpty) return null;

    Map<int, int> scores = {};
    Map<int, Map<String, dynamic>> storiesMap = {};

    for (var row in rawStories) {
      final int storyId = row['StoryID'];
      int score = 0;

      if (row['MoodID'] != null && row['MoodID'] == moodId)
        score += _moodWeight;
      if (row['LocationID'] != null && row['LocationID'] == locationId)
        score += _locationWeight;
      if (characterId != null &&
          row['CharacterID'] != null &&
          row['CharacterID'] == characterId)
        score += _characterWeight;
      if (animalId != null &&
          row['AnimalID'] != null &&
          row['AnimalID'] == animalId)
        score += _animalWeight;

      if (!scores.containsKey(storyId) || scores[storyId]! < score) {
        scores[storyId] = score;
        storiesMap[storyId] = row;
      }
    }

    if (scores.isEmpty) return null;
    int maxScore = scores.values.reduce(max);
    List<int> topIds = scores.entries
        .where((e) => e.value == maxScore)
        .map((e) => e.key)
        .toList();

    final random = Random();
    int selectedId = topIds[random.nextInt(topIds.length)];
    return StoryModel.fromMap(storiesMap[selectedId]!);
  }

  // ─── جلب قصة بـ ID ────────────────────────────────────────────────────────
  Future<StoryModel?> getStoryById(int storyId) async {
    final db = await _db.database;
    final res = await db.query(
      'Stories',
      where: 'StoryID = ?',
      whereArgs: [storyId],
    );
    if (res.isEmpty) return null;
    return StoryModel.fromMap(res.first);
  }

  // ─── المفضلة (جدول Favorites المستقل) ────────────────────────────────────

  Future<bool> isFavorite(int userId, int storyId) async {
    final db = await _db.database;
    final res = await db.query(
      'Favorites',
      where: 'UserID = ? AND StoryID = ?',
      whereArgs: [userId, storyId],
    );
    return res.isNotEmpty;
  }

  /// يرجع الحالة الجديدة: true = أصبح مفضلاً
  Future<bool> toggleFavorite(int userId, int storyId) async {
    final db = await _db.database;
    final already = await isFavorite(userId, storyId);

    if (already) {
      await db.delete(
        'Favorites',
        where: 'UserID = ? AND StoryID = ?',
        whereArgs: [userId, storyId],
      );
      return false;
    } else {
      await db.insert('Favorites', {'UserID': userId, 'StoryID': storyId});
      return true;
    }
  }

  Future<List<StoryModel>> getFavoriteStories(int userId) async {
    final db = await _db.database;
    final res = await db.rawQuery(
      '''
      SELECT s.*
      FROM Stories s
      INNER JOIN Favorites f ON s.StoryID = f.StoryID
      WHERE f.UserID = ?
      ORDER BY f.CreatedAt DESC
    ''',
      [userId],
    );
    return res.map((e) => StoryModel.fromMap(e)).toList();
  }

  // ─── المكتبة الجاهزة ──────────────────────────────────────────────────────
  Future<List<StoryModel>> getReadyStories() async {
    final db = await _db.database;
    final res = await db.query(
      'Stories',
      where: 'isCustomized = ?',
      whereArgs: [0],
    );
    return res.map((e) => StoryModel.fromMap(e)).toList();
  }

  // ─── تسجيل النشاط ─────────────────────────────────────────────────────────
  // ==========================================================================
  // ========== تم التعديل بواسطة مهندس المكتبة (لإصلاح توقيت UTC) ==========
  // ==========================================================================
  // التعديل: إضافة LogDate يدوياً بالتوقيت المحلي بصيغة ISO 8601
  // السبب: CURRENT_TIMESTAMP في قاعدة البيانات يعمل بتوقيت UTC
  // النتيجة: الآن الوقت يظهر بشكل صحيح في Dashboard (نفس توقيت الجوال)
  // ==========================================================================
  Future<void> logActivity({
    required int userId,
    required int storyId,
    int? characterId,
    int? animalId,
    required int locationId,
    required int moodId,
    required int durationInSeconds,
  }) async {
    final db = await _db.database;

    // ✅ إضافة الوقت الحالي بصيغة ISO 8601 مع المنطقة الزمنية
    final now = DateTime.now().toIso8601String();

    await db.insert('Activity', {
      'UserID': userId,
      'StoryID': storyId,
      'Duration': durationInSeconds,
      'LogDate': now, // <-- إضافة التاريخ والوقت بصيغة صحيحة
    });
  }

}
