import 'package:flutter/material.dart';
import '../engine/story_engine.dart';
import '../data/models/story_model.dart';
import 'story_view_screen.dart';

class LibraryScreen extends StatefulWidget {
  final int userId;
  const LibraryScreen({super.key, required this.userId});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final StoryEngine _engine = StoryEngine();
  List<StoryModel>  _stories = [];
  bool              _loading = true;

  static const _bg      = Color(0xFFF7F9FC); 
  static const _card    = Color(0xFFFFFFFF);
  static const _purple  = Color(0xFF7C4DFF);
  static const _gold    = Color(0xFFFFB300);
  static const _txtDark = Color(0xFF2E2063);
  static const _txtMid  = Color(0xFF7C6BA8);
  static const _border  = Color(0xFFE8E0FF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _engine.getReadyStories();
    if (mounted) setState(() { _stories = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _purple))
                : _stories.isEmpty
                    ? _buildEmpty()
                    : _buildGrid(),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.all(20),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 8)],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _txtDark, size: 18),
        ),
      ),
      const Expanded(
        child: Column(children: [
          
          Text('مكتبة القصص',
              style: TextStyle(fontSize: 19,
                  fontWeight: FontWeight.w900, color: _txtDark),
              textDirection: TextDirection.rtl),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _gold.withOpacity(0.35)),
        ),
        child: Text('${_stories.length} قصة',
            style: const TextStyle(
                color: _gold, fontSize: 12, fontWeight: FontWeight.bold),
            textDirection: TextDirection.rtl),
      ),
    ]),
  );

  Widget _buildGrid() => GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.68, // تم تعديل النسبة لتعطي كروت أكثر طولاً وأناقة كأغلفة الكتب
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
    ),
    itemCount: _stories.length,
    itemBuilder: (_, i) => _StoryCard(
      story:  _stories[i],
      userId: widget.userId,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(
            builder: (_) => StoryViewScreen(
              story:      _stories[i],
              userId:     widget.userId,
              locationId: _stories[i].locationId ?? 1,
              moodId:     _stories[i].moodId ?? 1,
            ),
          )).then((_) => setState(() {})),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text('📭', style: TextStyle(fontSize: 64)),
      const SizedBox(height: 16),
      Text('لا توجد قصص حالياً',
          style: TextStyle(color: _txtMid, fontSize: 15),
          textDirection: TextDirection.rtl),
    ]),
  );
}

// ─── بطاقة قصة المطور بالكامل ──────────────────────────────────────────────────
class _StoryCard extends StatefulWidget {
  final StoryModel  story;
  final int         userId;
  final VoidCallback onTap;

  const _StoryCard({required this.story, required this.userId, required this.onTap});

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  final StoryEngine _engine = StoryEngine();
  bool _isFav = false;

  static const _purple = Color(0xFF7C4DFF);
  static const _pink   = Color(0xFFFF6B8A);
  static const _border = Color(0xFFE8E0FF);

  @override
  void initState() {
    super.initState();
    _checkFav();
  }

  Future<void> _checkFav() async {
    final storyId = widget.story.storyId;
    if (storyId == null) return;
    final f = await _engine.isFavorite(widget.userId, storyId);
    if (mounted) setState(() => _isFav = f);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _border.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. صورة الغلاف كخلفية ممتدة لكامل الكرت
              Image.asset(
                widget.story.coverImage,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _purple.withOpacity(0.3),
                        _purple.withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text('📖', style: TextStyle(fontSize: 40)),
                  ),
                ),
              ),

              // 2. تدرج ظلي ناعم بالأسفل لضمان وضوح النص مهما كانت ألوان الصورة خلفه
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black45,
                        Colors.black87,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. النص متموضع في الأسفل وبادئ من اليمين تماماً مع الأوتلاين الجديد الناعم
              Positioned(
                bottom: 12, // يرتفع قليلاً عن الحافة ليكون منسقاً
                right: 12,
                left: 12,
                child: Stack(
                  alignment: Alignment.centerRight, // لضمان تطابق النص الأساسي مع الـ Outline من اليمين
                  children: [
                    // تحديد أسود خفيف ومقلل (Outline)
                    Text(
                      widget.story.title,
                      style: TextStyle(
                        fontSize: 14, // متناسق مع حجم كروت الجريد الداخلي
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 2
                          ..color = Colors.black87,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right, // لبدء الأسطر الإضافية من اليمين دائماً
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // النص الأساسي الأبيض
                    Text(
                      widget.story.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right, // لبدء الأسطر الإضافية من اليمين دائماً
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 4. زر أو أيقونة المفضلة بتصميم زجاجي عصري في الأعلى
              if (_isFav)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: _pink,
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}