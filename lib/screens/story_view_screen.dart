import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/story_model.dart';
import '../engine/story_engine.dart';
import '../services/story_audio_service.dart';
import 'puzzle_game_screen.dart';

// ─── ثوابت الألوان ────────────────────────────────────────────────────────────
class _C {
  static const purple = Color(0xFF7C4DFF);
  static const orange = Color(0xFFFF7043);
  static const pink = Color(0xFFFF6B8A);
  static const txtDark = Color(0xFF2E2063);
  static const txtMid = Color(0xFF7C6BA8);
  static const border = Color(0xFFE8E0FF);
  static const gold = Color(0xFFFFB300);
}

// ─── نموذج إعدادات القراءة ────────────────────────────────────────────────────
class ReadingPrefs {
  double fontSize;
  Color bgColor;
  Color textColor;
  ReadingPrefs({
    this.fontSize = 17,
    this.bgColor = const Color(0xFFFDFBF7),
    this.textColor = const Color(0xFF3E2723),
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class StoryViewScreen extends StatefulWidget {
  final StoryModel story;
  final int userId;
  final int? characterId;
  final int? animalId;
  final int locationId;
  final int moodId;

  const StoryViewScreen({
    super.key,
    required this.story,
    required this.userId,
    this.characterId,
    this.animalId,
    required this.locationId,
    required this.moodId,
  });

  @override
  State<StoryViewScreen> createState() => _StoryViewScreenState();
}

class _StoryViewScreenState extends State<StoryViewScreen>
    with TickerProviderStateMixin {
  final StoryEngine _engine = StoryEngine();
  late final StoryAudioService _audioService;

  bool _isFavorite = false;
  late Stopwatch _stopwatch;
  bool _logged = false;

  late AnimationController _heartCtrl;
  late Animation<double> _heartAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final ScrollController _scrollCtrl = ScrollController();
  final ReadingPrefs _prefs = ReadingPrefs();

  // الألوان الأربعة
  static const _bgOptions = [
    {'label': 'بيج فاتح', 'bg': Color(0xFFFDFBF7), 'txt': Color(0xFF3E2723)},
    {'label': 'غبار الورد', 'bg': Color(0xFFDCAEAE), 'txt': Color(0xFF4A2828)},
    {'label': 'رمادي قاسي', 'bg': Color(0xFF212121), 'txt': Color(0xFFECEFF1)},
    {'label': 'داكن عميق', 'bg': Color(0xFF0F172A), 'txt': Color(0xFFF8FAFC)},
  ];

  @override
  void initState() {
    super.initState();

    _stopwatch = Stopwatch()..start();
    _loadFavoriteState();

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut));

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    _audioService = StoryAudioService(
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  Future<void> _loadFavoriteState() async {
    final id = widget.story.storyId;
    if (id == null) return;
    final fav = await _engine.isFavorite(widget.userId, id);
    if (mounted) setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    final id = widget.story.storyId;
    if (id == null) return;
    final newState = await _engine.toggleFavorite(widget.userId, id);
    if (mounted) setState(() => _isFavorite = newState);
    _heartCtrl.reset();
    _heartCtrl.forward();
  }

  Future<void> _logActivity() async {
    if (_logged) return;
    _logged = true;
    _stopwatch.stop();
    final id = widget.story.storyId;
    if (id == null) return;
    await _engine.logActivity(
      userId: widget.userId,
      storyId: id,
      characterId: widget.characterId,
      animalId: widget.animalId,
      locationId: widget.locationId,
      moodId: widget.moodId,
      durationInSeconds: _stopwatch.elapsed.inSeconds,
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _stopwatch.stop();
    _heartCtrl.dispose();
    _fadeCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _prefs.bgColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Center(
        child: _topBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ),
      actions: [
        _topBtn(
          icon: Icons.tune_rounded,
          color: _C.purple,
          onTap: _showReadingSettings,
        ),
        const SizedBox(width: 4),
        AnimatedBuilder(
          animation: _heartAnim,
          builder: (_, __) => Transform.scale(
            scale: _heartAnim.value,
            child: _topBtn(
              icon: _isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _C.pink,
              onTap: _toggleFavorite,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.story.coverImage,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEDE7FF), Color(0xFFB39DDB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: const Center(
                  child: Text('📖', style: TextStyle(fontSize: 80)),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _prefs.bgColor.withValues(alpha: 0.95),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBtn({
    required IconData icon,
    VoidCallback? onTap,
    Color color = const Color(0xFF2E2063),
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6),
        ],
      ),
      child: Icon(icon, color: color, size: 16),
    ),
  );

  Widget _buildBody() {
    return Container(
      color: _prefs.bgColor,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.story.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _prefs.textColor,
              height: 1.4,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 70,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(colors: [_C.orange, _C.gold]),
              ),
            ),
          ),
          const SizedBox(height: 18),

          _buildAudioBar(),
          const SizedBox(height: 22),

          Text(
            widget.story.content,
            style: TextStyle(
              fontSize: _prefs.fontSize,
              color: _prefs.textColor,
              height: 2.1,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 32),

          Center(child: _buildFinishBtn()),
        ],
      ),
    );
  }

  Widget _buildAudioBar() {
    final String label;
    final IconData playIcon;

    if (_audioService.isLoading) {
      label = 'جاري التحميل...';
      playIcon = Icons.hourglass_top_rounded;
    } else if (_audioService.isPlaying && !_audioService.isPaused) {
      label = 'جاري الإستماع للقصة...';
      playIcon = Icons.pause_rounded;
    } else if (_audioService.isPlaying && _audioService.isPaused) {
      label = 'متوقف مؤقتاً ⏸';
      playIcon = Icons.play_arrow_rounded;
    } else {
      label = 'اضغط للاستماع للقصة ';
      playIcon = Icons.play_arrow_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.border),
        boxShadow: [
          BoxShadow(
            color: _C.purple.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_audioService.isPlaying) ...[
            _audioCircle(
              icon: Icons.stop_rounded,
              color: _C.orange,
              size: 38,
              onTap: _audioService.stopAudio,
            ),
            const SizedBox(width: 8),
          ],
          _audioCircle(
            icon: playIcon,
            color: _C.purple,
            size: 48,
            onTap: _audioService.isLoading
                ? null
                : () => _audioService.toggleAudio(widget.story.content),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _C.txtMid,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_audioService.isPlaying) ...[
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _C.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _C.orange.withValues(alpha: 0.35)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _audioCircle({
    required IconData icon,
    required Color color,
    required double size,
    VoidCallback? onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: color, size: size * 0.48),
    ),
  );

  Widget _buildFinishBtn() {
    return GestureDetector(
      onTap: () {
        _audioService.stopAudio();
        _logActivity();
        _showFinishedDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_C.purple, Color(0xFF9B59B6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _C.purple.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 10),
            Text(
              'أنهيت القصة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: AnimatedBuilder(
                      animation: _heartAnim,
                      builder: (_, __) => Transform.scale(
                        scale: _heartAnim.value,
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _C.pink,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Text('🌟', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 8),
              const Text(
                'أبدعت في القراءة',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _C.txtDark,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 6),
              const Text(
                'هل تريد أن تلعب لعبة ممتعة؟',
                style: TextStyle(color: _C.txtMid, fontSize: 14),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PuzzleLevelScreen(
                          imagePath: widget.story.coverImage,
                          userId: widget.userId,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _C.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🧩', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 8),
                      Text(
                        'لنلعب!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Color(0xFFE8E0FF),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_rounded, color: _C.txtMid, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'إنهاء والعودة',
                        style: TextStyle(
                          color: _C.txtMid,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textDirection: TextDirection.rtl,
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
  }

  void _showReadingSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ReadingSettingsSheet(
        prefs: _prefs,
        bgOptions: _bgOptions,
        onChanged: () => setState(() {}),
      ),
    );
  }
}

// ─── BottomSheet إعدادات القراءة ────────────────────────────────────────────
class _ReadingSettingsSheet extends StatefulWidget {
  final ReadingPrefs prefs;
  final List<Map<String, Object>> bgOptions;
  final VoidCallback onChanged;

  const _ReadingSettingsSheet({
    required this.prefs,
    required this.bgOptions,
    required this.onChanged,
  });

  @override
  State<_ReadingSettingsSheet> createState() => _ReadingSettingsSheetState();
}

class _ReadingSettingsSheetState extends State<_ReadingSettingsSheet> {
  static const _txtMain = Color(0xFF1A1A1A);
  static const _txtMuted = Color(0xFF757575);
  static const _neutralBg = Color(0xFFF5F5F7);
  static const _borderClr = Color(0xFFEEEEEE);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'تخصيص القراءة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _txtMain,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: _neutralBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    _buildTextSizeBtn(Icons.add_rounded, () {
                      if (widget.prefs.fontSize < 26) {
                        setState(() => widget.prefs.fontSize += 1);
                        widget.onChanged();
                      }
                    }),
                    Container(
                      constraints: const BoxConstraints(minWidth: 36),
                      child: Text(
                        '${widget.prefs.fontSize.round()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _txtMain,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    _buildTextSizeBtn(Icons.remove_rounded, () {
                      if (widget.prefs.fontSize > 13) {
                        setState(() => widget.prefs.fontSize -= 1);
                        widget.onChanged();
                      }
                    }),
                  ],
                ),
              ),
              const Text(
                'حجم الخط',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: _txtMuted,
                  fontSize: 14,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'مظهر الصفحة',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: _txtMuted,
              fontSize: 14,
                ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: widget.bgOptions.map((opt) {
                final bg = opt['bg'] as Color;
                final txt = opt['txt'] as Color;
                final isSelected = widget.prefs.bgColor.value == bg.value;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.prefs.bgColor = bg;
                      widget.prefs.textColor = txt;
                    });
                    widget.onChanged();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF7C4DFF)
                            : _borderClr,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7C4DFF).withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded, color: txt, size: 18)
                        : const SizedBox.shrink(),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSizeBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: _txtMain,
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
    );
  }
}