import 'package:flutter/material.dart';
import '../engine/story_engine.dart';
import '../data/models/story_model.dart';
import 'story_view_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final int userId;
  const FavoritesScreen({super.key, required this.userId});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final StoryEngine _engine = StoryEngine();
  List<StoryModel> _favorites = [];
  bool _loading = true;

  static const _bg = Color(0xFFF7F9FC); 
  static const _card    = Color(0xFFFFFFFF);
  static const _purple  = Color(0xFF7C4DFF);
  static const _pink    = Color(0xFFFF6B8A);
  static const _txtDark = Color(0xFF2E2063);
  static const _txtMid  = Color(0xFF7C6BA8);
  static const _border  = Color(0xFFE8E0FF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await _engine.getFavoriteStories(widget.userId);
    if (mounted) setState(() { _favorites = favs; _loading = false; });
  }

  Future<void> _toggleFav(int storyId) async {
    // هنا يمكنك استدعاء دالة الحذف من المفضلة الخاصة بـ Engine إذا أردت
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      extendBody: true,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _pink))
                : _favorites.isEmpty
                    ? _buildEmpty()
                    : _buildList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 36, height: 36, // تم تصغير حجم الحاوية هنا
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(10), // تعديل الحواف لتناسب الحجم الجديد
            border: Border.all(color: _border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _txtDark, size: 14), // تم تصغير حجم الأيقونة هنا
        ),
      ),
      const Expanded(
        child: Column(children: [
          Text('قصصك المفضلة',
              style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w900, color: _txtDark),
              textDirection: TextDirection.rtl),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // تم تصغير البادينج ليصغر حجم الكونتينر
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _pink.withOpacity(0.25)),
        ),
        child: Text('${_favorites.length} قصة',
            style: const TextStyle(
                color: _pink, fontSize: 11, fontWeight: FontWeight.bold), // تم تصغير الخط قليلاً ليتناسق
            textDirection: TextDirection.rtl),
      ),
    ]),
  );

Widget _buildList() => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    itemCount: _favorites.length,
    itemBuilder: (_, i) {
      final story = _favorites[i];
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => StoryViewScreen(
            story:      story,
            userId:     widget.userId,
            locationId: story.locationId ?? 1,
            moodId:     story.moodId ?? 1,
          ),
        )).then((_) => _load()),
        child: Container(
          height: 135, // تم ضبط الارتفاع الإجمالي ليكون متناسقاً جداً
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border.withOpacity(0.6)),
            boxShadow: [
              BoxShadow(
                color: _txtDark.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Column(
                  children: [
                    // 1. مساحة النص تم تقصيرها هنا (vertical: 6 بدلاً من 10)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: _card,
                      alignment: Alignment.centerRight,
                      child: Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 14, // تم تصغير الخط قليلاً ليناسب المساحة القصيرة
                          fontWeight: FontWeight.w800,
                          color: _txtDark,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // 2. الصورة تأخذ باقي المساحة الأكبر الآن
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: Image.asset(
                          story.coverImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [_purple.withOpacity(0.2), _purple.withOpacity(0.05)],
                              ),
                            ),
                            child: const Center(
                              child: Text('📖', style: TextStyle(fontSize: 30)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // 3. زر المفضلة (القلب)
                Positioned(
                  left: 8,
                  bottom: 0,
                  top: 32, // تم تقليله ليتناسب مع بداية مساحة الصورة الجديدة
                  child: Center(
  child: Container(
    width: 36, // تحديد عرض ثابت وصغير للكونتينر الدائري
    height: 36, // تحديد ارتفاع ثابت متناسق
    decoration: BoxDecoration(
      color: _card.withValues(alpha: 0.9), // تم تحديثها لـ withValues بناءً على التحذيرات السابقة
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
        )
      ]
    ),
    child: IconButton(
      padding: EdgeInsets.zero, // تصفير الحشو الداخلي لمنع تمدد الحاوية
      constraints: const BoxConstraints(), // إزالة قيود الحجم الافتراضية الكبيرة للـ IconButton
      icon: const Icon(
        Icons.favorite_rounded, 
        color: _pink, 
        size: 22, // تم تصغير حجم الأيقونة قليلاً لتناسب حجم الدائرة الجديد بشكل أنيق
      ),
      onPressed: () => _toggleFav(story.storyId ?? 0),
    ),
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
  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('💔', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      const Text('لا توجد قصص مفضلة بعد',
          style: TextStyle(color: _txtDark, fontSize: 16,
              fontWeight: FontWeight.w700),
          textDirection: TextDirection.rtl),
      const SizedBox(height: 8),
      Text('اقرأ القصص واضغط القلب ❤️',
          style: TextStyle(color: _txtMid, fontSize: 13),
          textDirection: TextDirection.rtl),
    ]),
  );
}