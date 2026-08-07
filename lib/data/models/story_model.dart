class StoryModel {
  final int? storyId; // حرف d صغير للالتزام بمعايير Dart
  final String title;
  final String content;
  final String coverImage;
  final int isCustomized;
  final int? userId;
  final int? locationId;
  final int? moodId;

  StoryModel({
    this.storyId,
    required this.title,
    required this.content,
    required this.coverImage,
    required this.isCustomized,
    this.userId,
    this.locationId,
    this.moodId,
  });

  factory StoryModel.fromMap(Map<String, dynamic> map) {
    return StoryModel(
      // هنا نكتب اسم العمود في SQL كما هو تماماً
      storyId: map['StoryID'], 
      title: map['Title'],
      content: map['Content'],
      coverImage: map['CoverImage'],
      isCustomized: map['isCustomized'],
      userId: map['UserID'],
      locationId: map['LocationID'],
      moodId: map['MoodID'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'StoryID': storyId,
      'Title': title,
      'Content': content,
      'CoverImage': coverImage,
      'isCustomized': isCustomized,
      'UserID': userId,
      'LocationID': locationId,
      'MoodID': moodId,
    };
  }
}