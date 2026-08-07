class ActivityModel {
  final int? activityId;
  final int userId;
  final int storyId;
  final int? characterId;
  final int? animalId;
  final int locationId;
  final int moodId;
  final String? logDate; // سيأتي تلقائياً من القاعدة
  final int duration;    // بالثواني

  ActivityModel({
    this.activityId,
    required this.userId,
    required this.storyId,
    this.characterId,
    this.animalId,
    required this.locationId,
    required this.moodId,
    this.logDate,
    required this.duration,
  });

  // تحويل البيانات من Map (القاعدة) إلى Object (دارت)
  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      activityId: map['ActivityID'], // المفتاح يطابق اسم العمود في SQL
      userId: map['UserID'],
      storyId: map['StoryID'],
      characterId: map['CharacterID'],
      animalId: map['AnimalID'],
      locationId: map['LocationID'],
      moodId: map['MoodID'],
      logDate: map['LogDate'],
      duration: map['Duration'],
    );
  }

  // تحويل الـ Object إلى Map ليتم تخزينه في القاعدة
  Map<String, dynamic> toMap() {
    return {
      'UserID': userId,
      'StoryID': storyId,
      'CharacterID': characterId,
      'AnimalID': animalId,
      'LocationID': locationId,
      'MoodID': moodId,
      'Duration': duration,
      // LogDate لا نرسله لأنه يدخل تلقائياً في القاعدة عبر CURRENT_TIMESTAMP
    };
  }
}