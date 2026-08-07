import 'package:flutter/material.dart';
import '../services/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/database/database_helper.dart'; 
import '../engine/story_engine.dart';       
import '../data/models/story_model.dart';   
import 'story_view_screen.dart';            

import 'library_screen.dart';
import 'customize_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'parent_dashboard.dart'; 

// تعريف بنية بيانات الأفاتار ومصفوفتها محلياً لضمان قراءتها داخل شاشة الهوم تلقائياً
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

class HomeScreen extends StatefulWidget {
  final int userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  UserModel? _user;
  
  final StoryEngine _storyEngine = StoryEngine();
  List<StoryModel> _favoriteStories = [];
  bool _loadingFavorites = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _loadUser();
    _loadLastActivity();
    _loadFavorites(); 
  }

  void _loadUser() async {
    final u = await AuthRepository().getSavedUser();
    if (mounted) setState(() => _user = u);
  }

  void _loadLastActivity() {
    if (mounted) {
      setState(() {});
    }
  }

  void _loadFavorites() async {
    try {
      final favs = await _storyEngine.getFavoriteStories(widget.userId);
      if (mounted) {
        setState(() {
          _favoriteStories = favs;
          _loadingFavorites = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFavorites = false);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  static const _bg = Color(0xFFF7F9FC); 
  static const _purple = Color(0xFF7C4DFF);
  static const _pink = Color(0xFFFF4081);
  static const _txtMid = Color(0xFF7C6BA8);
  static const _txtDark = Color(0xFF2E2063);

  @override
  Widget build(BuildContext context) {
    final avatarEmoji = _user?.avatar ?? '🦁';
    final name = _user?.username ?? 'صديقي المبدع';

    final matchedAvatar = kAvatars.firstWhere(
      (element) => element.emoji == avatarEmoji,
      orElse: () => kAvatars.first,
    );

    final heroHeight = MediaQuery.of(context).size.height * 0.38;

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildNewHero(heroHeight, matchedAvatar.imagePath, name),
                  _buildContinueReadingSection(),
                  const SizedBox(height: 25),
                  _buildKidsActionCards(),
                  const SizedBox(height: 20), 
                  _buildHorizontalFavoritesSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildTopBar(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewHero(double height, String imagePath, String name) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(40),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
              ),
            ),
            
            Positioned(
              left: 75.0,   
              bottom: 40.0, 
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      const Text(
                        'أهلاً بك يا ',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 5, color: Colors.black87)],
                        ),
                      ),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFFF176), Color(0xFFFFB300)], 
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                blurRadius: 6,
                                color: Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(0, 1),
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'جاهز لمغامرة جديدة ؟ ',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      shadows: [Shadow(blurRadius: 5, color: Colors.black87)],
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueReadingSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: () async {
        try {
          final db = await DatabaseHelper().database;
          final List<Map<String, dynamic>> result = await db.rawQuery(
            '''
            SELECT a.*, s.Title as StoryTitle, s.CoverImage as StoryCover, s.LocationID, s.MoodID, s.isCustomized
            FROM Activity a
            JOIN Stories s ON a.StoryID = s.StoryID
            WHERE a.UserID = ? AND a.Duration <= 300  
            ORDER BY a.LogDate DESC
            LIMIT 1
            ''',
            [widget.userId], 
          );

          if (result.isEmpty) return null;

          String? logDateStr = result.first['LogDate'] as String?;
          DateTime dateTime = DateTime.now();
          if (logDateStr != null && logDateStr.isNotEmpty) {
            try { dateTime = DateTime.parse(logDateStr).toLocal(); } catch (_) {}
          }

          dynamic durationValue = result.first['Duration'];
          int duration = durationValue is int ? durationValue : (int.tryParse(durationValue?.toString() ?? '') ?? 0);

          return {
            'StoryID': result.first['StoryID'], 
            'StoryTitle': result.first['StoryTitle']?.toString() ?? 'عنوان غير معروف',
            'CoverImage': result.first['StoryCover']?.toString() ?? '', 
            'LocationID': result.first['LocationID'],
            'MoodID': result.first['MoodID'],
            'isCustomized': result.first['isCustomized'] ?? 0,
            'LogDate': dateTime,
            'Duration': duration,
          };
        } catch (e) {
          debugPrint("خطأ أثناء جلب آخر نشاط مخصص: $e");
          return null;
        }
      }(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || 
            snapshot.data == null || 
            snapshot.data!['StoryTitle'] == 'عنوان غير معروف') {
          return const SizedBox(height: 15); 
        }

        final lastActivity = snapshot.data!;
        final storyTitle = lastActivity['StoryTitle'] as String;
        final storyImagePath = lastActivity['CoverImage'] as String?;

        final storyId = lastActivity['StoryID'] as int?;
        final locationId = lastActivity['LocationID'] as int?;
        final moodId = lastActivity['MoodID'] as int?;
        final isCustomizedValue = lastActivity['isCustomized'] as int? ?? 0;

        return Padding(
          padding: const EdgeInsets.only(top: 25, left: 20, right: 20),
          child: GestureDetector(
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: _purple)),
              );

              StoryModel? fullStory;
              
              try {
                if (storyId != null) {
                  final db = await DatabaseHelper().database;
                  final List<Map<String, dynamic>> maps = await db.query(
                    'Stories',
                    where: 'StoryID = ?',
                    whereArgs: [storyId],
                    limit: 1,
                  );

                  if (maps.isNotEmpty) {
                    final row = maps.first;
                    fullStory = StoryModel(
                      storyId: storyId,
                      title: (row['Title'] ?? storyTitle) as String,
                      content: (row['Content'] ?? 'لم يتم العثور على نص القصة بداخل قاعدة البيانات.') as String,
                      coverImage: (row['CoverImage'] ?? storyImagePath ?? '') as String,
                      isCustomized: (row['isCustomized'] ?? isCustomizedValue) as int,
                      userId: widget.userId,
                      locationId: locationId,
                      moodId: moodId,
                    );
                  }
                }
              } catch (e) {
                debugPrint("خطأ استثنائي أثناء جلب نص القصة: $e");
              }

              if (context.mounted) Navigator.pop(context);

              final currentStory = fullStory ?? StoryModel(
                storyId: storyId,
                title: storyTitle,
                content: 'تعذر تحميل القصة الحالية، يرجى إعادة المحاولة.',
                coverImage: storyImagePath ?? '',
                isCustomized: isCustomizedValue,
                userId: widget.userId,
                locationId: locationId,
                moodId: moodId,
              );

              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryViewScreen(
                      story: currentStory,
                      userId: widget.userId,
                      locationId: locationId ?? 1,
                      moodId: moodId ?? 1,
                    ),
                  ),
                );
                _loadFavorites();
                if (context.mounted) {
                  if (Navigator.canPop(context)) setState(() {}); 
                }
              }
            },
            child: Container(
              width: double.infinity,
              height: 135, 
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF9), 
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5C4A3A).withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl, 
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0), 
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16), 
                        child: SizedBox(
                          height: double.infinity,
                          child: storyImagePath != null && storyImagePath.isNotEmpty
                              ? Image.asset(
                                  storyImagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE8E0FF),
                                    child: const Icon(Icons.broken_image_rounded, color: _purple, size: 30),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFE8E0FF),
                                  child: const Icon(Icons.image_rounded, color: _purple, size: 30),
                                ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14.0, bottom: 14.0, left: 16.0, right: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            textDirection: TextDirection.rtl,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5E97), 
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF5E97).withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'تابع القراءة',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ), 
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.menu_book_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                storyTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2E2452),
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Text(
                                    'مستوى التقدم',
                                    style: TextStyle(
                                      fontSize: 10, 
                                      fontWeight: FontWeight.bold, 
                                      color: _txtDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: const LinearProgressIndicator(
                                  value: 0.65, 
                                  minHeight: 7,
                                  backgroundColor: Color(0xFFF1EDFF),
                                  valueColor: AlwaysStoppedAnimation<Color>(_purple),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHorizontalFavoritesSection() {
    if (_loadingFavorites) return const SizedBox();
    if (_favoriteStories.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 25),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FavoritesScreen(userId: widget.userId),
              ),
            ).then((_) {
              _loadFavorites(); 
              _loadLastActivity();
            }),
            //  تمت إزالة Expanded من هنا وتغليف المحتوى بـ SizedBox لتفادي مشاكل الأبعاد المفتوحة
            child: const SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end, 
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start, 
                    textDirection: TextDirection.rtl, 
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        color: _pink,
                        size: 20,
                      ),
                      SizedBox(width: 6), 
                      Text(
                        'قصصك المفضلة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _txtDark,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                  SizedBox(height: 4), 
                  Text(
                    'قصصٌ أحببتها، أعد قراءتها الآن ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _txtMid,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Directionality(
          textDirection: TextDirection.rtl, 
          child: SizedBox(
            height: 140, 
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _favoriteStories.length,
              itemBuilder: (context, index) {
                final story = _favoriteStories[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StoryViewScreen(
                        story: story,
                        userId: widget.userId,
                        locationId: story.locationId ?? 1,
                        moodId: story.moodId ?? 1,
                      ),
                    ),
                  ).then((_) {
                    _loadFavorites();
                    _loadLastActivity();
                  }),
                  child: Container(
                    width: 130, 
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _txtDark.withValues(alpha: 0.12), 
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            story.coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_purple.withValues(alpha: 0.3), _purple.withValues(alpha: 0.1)],
                                ),
                              ),
                              child: const Center(child: Text('📖', style: TextStyle(fontSize: 32))),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black54],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            left: 10,
                            child: Text(
                              story.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKidsActionCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _KidActionCard(
              title: 'مكتبة القصص',
              subtitle: 'استكشف عالم الخيال',
              imagePath: 'assets/images/pic/readyStory.png',
              topColor: const Color(0xFF916BFF),
              bottomColor: const Color(0xFF6236FF),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LibraryScreen(userId: widget.userId),
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 250));
                _loadLastActivity();
                _loadFavorites();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _KidActionCard(
              title: '!اصنع قصتك',
              subtitle: 'كن أنت كاتب المغامرة',
              imagePath: 'assets/images/pic/customizedStory.png',
              topColor: const Color(0xFFFF9E73),
              bottomColor: const Color(0xFFFF5722),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CustomizeScreen(userId: widget.userId),
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 250));
                _loadLastActivity();
                _loadFavorites();
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🚀 بناء الـ TopBar الجديد والمنبثق بصورة الأفتار الدائري التفاعلي
  Widget _buildTopBar() {
    final avatarEmoji = _user?.avatar ?? '🦁';

    // العثور على الألوان والإيموجي المخصص للأفاتار الحالي للطفل
    final currentAvatarData = kAvatars.firstWhere(
      (element) => element.emoji == avatarEmoji,
      orElse: () => kAvatars.first,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, 
        children: [
          PopupMenuButton<int>(
            elevation: 0, 
            constraints: const BoxConstraints(
              maxWidth: 130, 
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            
            color: Colors.white.withValues(alpha: 0.85), 
            
            padding: EdgeInsets.zero,
            
            // تحديد اتجاه ظهور القائمة والتعامل مع الضغط
            onSelected: (value) async {
              if (value == 1) {
                // الانتقال إلى شاشة الإعدادات
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(userId: widget.userId),
                  ),
                );
                _loadUser();
                _loadLastActivity();
              } else if (value == 2) {
                // الانتقال إلى شاشة لوحة التحكم للآباء (الإحصائيات)
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParentDashboardScreen(userId: widget.userId),
                    ),
                  ).then((_) => _loadFavorites());
                }
              }
            },
            // تصميم كارد الأفاتار الدائري الجذاب بمظهر طفولي
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: currentAvatarData.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: currentAvatarData.colors[1].withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  currentAvatarData.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            // بناء عناصر القائمة المنبثقة
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 1,
                height: 38, 
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF2E2063), 
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.settings_rounded, color: Colors.blue.shade600, size: 18),
                  ],
                ),
              ),
              PopupMenuDivider(height: 1, color: Colors.black.withValues(alpha: 0.05)), 
              PopupMenuItem<int>(
                value: 2,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      'الإحصائيات',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold, 
                        color: Color(0xFF2E2063),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.family_restroom_rounded, color: _purple, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KidActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color topColor;
  final Color bottomColor;
  final VoidCallback onTap;

  const _KidActionCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.topColor,
    required this.bottomColor,
    required this.onTap,
  });

  @override
  State<_KidActionCard> createState() => _KidActionCardState();
}

class _KidActionCardState extends State<_KidActionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final vibrantTopColor =
        Color.alphaBlend(widget.topColor.withValues(alpha: 0.8), widget.topColor);
    final vibrantBottomColor =
        Color.alphaBlend(widget.bottomColor.withValues(alpha: 0.8), widget.bottomColor);

    final bool isCreateStory =
        widget.title.contains("اصنع") || widget.title.contains("قصتك");

    final IconData centerIcon =
        isCreateStory ? Icons.auto_awesome_rounded : Icons.menu_book_rounded;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 165,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [vibrantTopColor, vibrantBottomColor],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: vibrantBottomColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 16,
                        right: 16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 0, 
                          left: 2,
                          right: 2,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Transform.translate(
                            offset: const Offset(0, 14), 
                            child: Transform.scale(
                              scale: 1.35,
                              alignment: Alignment.bottomCenter,
                              child: Image.asset(
                                widget.imagePath,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -22,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: vibrantBottomColor,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    centerIcon,
                    size: 24,
                    color: vibrantBottomColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}