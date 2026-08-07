import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

// ─── ثوابت ────────────────────────────────────────────────────────────────────
class _K {
  static const bg      = Color(0xFFF7F9FC); 
  static const white   = Color(0xFFFFFFFF);
  static const purple  = Color(0xFF7C4DFF);
  static const orange  = Color(0xFFFF7043);
  static const teal    = Color(0xFF00BCD4);
  static const gold    = Color(0xFFFFB300);
  static const green   = Color(0xFF43A047);
  static const pink    = Color(0xFFFF6B8A);
  static const txtDark = Color(0xFF2E2063);
  static const txtMid  = Color(0xFF7C6BA8);
  static const border  = Color(0xFFE8E0FF);
}

// ─── مستويات الصعوبة ──────────────────────────────────────────────────────────
enum Difficulty { easy, medium, hard }

extension DifficultyX on Difficulty {
  int    get grid  => const [3, 4, 5][index];
  String get label => ['سهل ', 'متوسط ', 'صعب '][index];
  Color  get color => [_K.green, _K.gold, _K.orange][index];
  bool   get hasGhost  => this == Difficulty.easy;
  int    get hintCount => this == Difficulty.medium ? 3 : 0;
}

// ─── نموذج قطعة ───────────────────────────────────────────────────────────────
class _Piece {
  final int correct; 
  bool placed;       

  _Piece(this.correct) : placed = false;
}

// ══════════════════════════════════════════════════════════════════════════════
// شاشة اختيار المستوى
// ══════════════════════════════════════════════════════════════════════════════
class PuzzleLevelScreen extends StatelessWidget {
  final String imagePath;
  final int    userId;

  const PuzzleLevelScreen({
    super.key,
    required this.imagePath,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      body: SafeArea(
        child: Column(children: [
          // رأس الشاشة
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              _BackBtn(onTap: () => Navigator.pop(context)),
              const Expanded(
                child: Column(children: [
                  Text('🧩', style: TextStyle(fontSize: 32)),
                  Text('تركيب الصور ',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900, color: _K.txtDark),
                      textDirection: TextDirection.rtl),
                ]),
              ),
              const SizedBox(width: 44),
            ]),
          ),

          // معاينة الصورة
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                imagePath,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                cacheWidth: 400,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: _K.border,
                  child: const Center(
                      child: Text('🖼️', style: TextStyle(fontSize: 60))),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text('اختر مستوى الصعوبة',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w800, color: _K.txtDark),
              textDirection: TextDirection.rtl),
          const SizedBox(height: 16),

          // بطاقات المستويات
          ...Difficulty.values.map((d) => _DifficultyCard(
            difficulty: d,
            onTap: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => PuzzleGameScreen(
                imagePath:  imagePath,
                difficulty: d,
                userId:     userId,
              )),
            ),
          )),
        ]),
      ),
    );
  }
}

// ─── بطاقة مستوى ──────────────────────────────────────────────────────────────
class _DifficultyCard extends StatefulWidget {
  final Difficulty   difficulty;
  final VoidCallback onTap;
  const _DifficultyCard({required this.difficulty, required this.onTap});

  @override
  State<_DifficultyCard> createState() => _DifficultyCardState();
}

class _DifficultyCardState extends State<_DifficultyCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.difficulty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp:   (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: _K.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: d.color.withOpacity(0.3), width: 1.5),
              boxShadow: [BoxShadow(
                  color: d.color.withOpacity(0.1),
                  blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // أيقونة تشغيل
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: d.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.play_arrow_rounded,
                        color: d.color, size: 22),
                  ),
                  // نص
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(d.label,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: _K.txtDark),
                          textDirection: TextDirection.rtl),
                    ],
                  ),
                  // شبكة توضيحية
                  SizedBox(
                    width: 36, height: 36,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: d.grid,
                          mainAxisSpacing: 1.5, crossAxisSpacing: 1.5),
                      itemCount: d.grid * d.grid,
                      itemBuilder: (_, __) => Container(
                        decoration: BoxDecoration(
                          color: d.color.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// شاشة اللعب
// ══════════════════════════════════════════════════════════════════════════════
class PuzzleGameScreen extends StatefulWidget {
  final String     imagePath;
  final Difficulty difficulty;
  final int        userId;

  const PuzzleGameScreen({
    super.key,
    required this.imagePath,
    required this.difficulty,
    required this.userId,
  });

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen>
    with TickerProviderStateMixin {

  // حالة اللعبة
  late List<_Piece> _pieces;    // الترتيب المخلوط (الصينية)
  int?  _selectedIdx;           // القطعة المختارة من الصينية
  // الخلايا الموضوعة: cellIndex → pieceCorrectIndex
  final Map<int, int> _board = {};
  int  _hintsLeft = 0;
  bool _hintVisible = false;
  Timer? _hintTimer;
  bool _won = false;

  // مؤقت
  final Stopwatch _sw = Stopwatch();
  Timer? _ticker;

  // Tutorial
  bool _tutVisible  = false;
  int  _tutStep     = 0; // 0=اختر قطعة, 1=ضعها

  // انيميشن
  late AnimationController _celebCtrl;
  late Animation<double>   _celebScale;
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  int get _grid  => widget.difficulty.grid;
  int get _total => _grid * _grid;

  // القطع غير الموضوعة
  List<_Piece> get _tray => _pieces.where((p) => !p.placed).toList();

  @override
  void initState() {
    super.initState();

    _hintsLeft = widget.difficulty.hintCount;
    _sw.start();
    _ticker = Timer.periodic(
        const Duration(seconds: 1), (_) { if (mounted && !_won) setState(() {}); });

    _celebCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _celebScale = CurvedAnimation(parent: _celebCtrl, curve: Curves.elasticOut);

    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 25),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0),  weight: 25),
    ]).animate(_shakeCtrl);

    _reset();
    _checkTutorial();
  }

  void _reset() {
    _pieces = List.generate(_total, (i) => _Piece(i));
    _pieces.shuffle(Random());
    _board.clear();
    _selectedIdx = null;
    _won         = false;
    _hintVisible = false;
    _hintsLeft   = widget.difficulty.hintCount;
    _sw.reset(); _sw.start();
    _celebCtrl.reset();
  }

  Future<void> _checkTutorial() async {
    final p = await SharedPreferences.getInstance();
    final shown = p.getBool('puzzle_tutorial_done') ?? false;
    if (!shown && mounted) setState(() { _tutVisible = true; _tutStep = 0; });
  }

  Future<void> _doneTutorial() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('puzzle_tutorial_done', true);
    if (mounted) setState(() => _tutVisible = false);
  }

  // ─── اختيار قطعة من الصينية ───────────────────────────────────────────────
  void _selectTrayPiece(int idx) {
    if (_won) return;
    setState(() => _selectedIdx = idx);
    if (_tutVisible && _tutStep == 0) {
      setState(() => _tutStep = 1);
    }
  }

  // ─── وضع القطعة في خلية اللوحة ───────────────────────────────────────────
  void _placeOnCell(int cellIndex) {
    if (_selectedIdx == null || _won) return;

    // الخلية مشغولة؟
    if (_board.containsKey(cellIndex)) {
      HapticFeedback.lightImpact();
      return;
    }

    final tray  = _tray;
    final piece = tray[_selectedIdx!];

    if (piece.correct == cellIndex) {
      // ✅ صحيح
      HapticFeedback.mediumImpact();
      setState(() {
        piece.placed    = true;
        _board[cellIndex] = piece.correct;
        _selectedIdx    = null;
      });
      if (_tutVisible) _doneTutorial();
      _checkWin();
    } else {
      // ❌ خطأ
      HapticFeedback.heavyImpact();
      _shakeCtrl.reset();
      _shakeCtrl.forward();
    }
  }

  void _checkWin() {
    if (_board.length == _total) {
      _sw.stop();
      _ticker?.cancel();
      setState(() => _won = true);
      _celebCtrl.forward();
    }
  }

  void _useHint() {
    if (_hintsLeft <= 0 || _hintVisible) return;
    setState(() { _hintVisible = true; _hintsLeft--; });
    _hintTimer?.cancel();
    _hintTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hintVisible = false);
    });
  }

  String get _time {
    final s = _sw.elapsed.inSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _ticker?.cancel();
    _celebCtrl.dispose();
    _shakeCtrl.dispose();
    _sw.stop();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            _buildTopBar(),
            const SizedBox(height: 4),
            Expanded(flex: 6, child: _buildBoard()),
            const SizedBox(height: 6),
            _buildTrayLabel(),
            SizedBox(height: 96, child: _buildTray()),
            const SizedBox(height: 10),
          ]),

          // Tutorial
          if (_tutVisible) _buildTutorial(),

          // Win
          if (_won) _buildWin(),
        ]),
      ),
    );
  }

  // ─── TopBar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(children: [
        // زر X للخروج
        GestureDetector(
          onTap: _showExitDialog,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _K.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _K.border),
            ),
            child: const Icon(Icons.close_rounded, color: _K.txtDark, size: 20),
          ),
        ),
        const SizedBox(width: 8),

        // مستوى الصعوبة + مؤقت
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tag(widget.difficulty.label, widget.difficulty.color),
              const SizedBox(width: 8),
              _tag('⏱ $_time', _K.purple),
            ],
          ),
        ),

        // زر التلميح (متوسط فقط)
        if (widget.difficulty == Difficulty.medium)
          GestureDetector(
            onTap: (_hintsLeft > 0 && !_hintVisible) ? _useHint : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _hintsLeft > 0
                    ? _K.gold.withOpacity(0.12)
                    : _K.border,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hintsLeft > 0
                      ? _K.gold.withOpacity(0.4)
                      : _K.border,
                ),
              ),
              child: Row(children: [
                Text('💡', style: TextStyle(
                    fontSize: 14,
                    color: _hintsLeft > 0 ? null : Colors.grey)),
                const SizedBox(width: 3),
                Text('$_hintsLeft',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13,
                        color: _hintsLeft > 0 ? _K.gold : Colors.grey)),
              ]),
            ),
          )
        else
          const SizedBox(width: 40),
      ]),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: TextStyle(
        color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  // ─── لوحة اللعب ────────────────────────────────────────────────────────────
Widget _buildBoard() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (ctx, box) {
        final size = box.maxWidth;
        return SizedBox(
          width: size, 
          height: size,
          child: Stack(
            children: [
              // 1. تعديل الخلفية الشفافة (Ghost Image)
              if (widget.difficulty.hasGhost || _hintVisible)
                Opacity(
                  opacity: _hintVisible ? 1.0 : 0.18,
                  child: Container(
                    // نستخدم مارجن بسيط لمطابقة حدود الشبكة الخارجية إذا كان هناك Border
                    margin: const EdgeInsets.all(1), 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.fill, // نستخدم fill ليتطابق مع منطق تقسيم القطع
                        cacheWidth: 400,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                ),

              // 2. الشبكة (GridView)
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                // تأكدي أن الـ padding هنا صفر لكي لا تبتعد القطع عن الخلفية
                padding: EdgeInsets.zero, 
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _grid,
                  // اجعلي المسافات صغيرة جداً (مثل 1.0) لتقليل الفجوات بين القطع والخلفية
                  mainAxisSpacing: 1.5, 
                  crossAxisSpacing: 1.5,
                ),
                itemCount: _total,
                itemBuilder: (_, cellIndex) {
                  final correctIdx = _board[cellIndex];
                  final empty      = correctIdx == null;
                  final canReceive = empty && _selectedIdx != null;

                  return GestureDetector(
                    onTap: () => _placeOnCell(cellIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        // تقليل عتامة اللون الأبيض للخلايا الفارغة لكي تظهر الخلفية بوضوح
                        color: empty ? Colors.white.withOpacity(0.2) : null,
                        border: Border.all(
                          color: canReceive
                              ? _K.purple.withOpacity(0.5)
                              : empty
                                  ? _K.border.withOpacity(0.3)
                                  : Colors.transparent,
                          width: canReceive ? 2 : 0.5,
                        ),
                      ),
                      child: empty
                          ? (canReceive 
                              ? const Center(child: Icon(Icons.add_rounded, color: Color(0x557C4DFF), size: 18))
                              : null)
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: _PieceImage(
                                imagePath:  widget.imagePath,
                                pieceIndex: correctIdx,
                                grid:       _grid,
                                boardPx:    size.toInt(),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      }),
    ),
  );
}
  // ─── تسمية القائمة ─────────────────────────────────────────────────────────
  Widget _buildTrayLabel() {
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 4),
      child: Text(
        _selectedIdx != null
            ? '👆 اختر مكاناً على اللوحة'
            : '👇 اختر قطعة',
        style: const TextStyle(
            color: _K.txtMid, fontSize: 12, fontWeight: FontWeight.w600),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // ─── قائمة القطع ────────────────────────────────────────────────────────────
  Widget _buildTray() {
    final tray = _tray;
    if (tray.isEmpty) return const SizedBox();

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: tray.length,
      itemBuilder: (_, i) {
        final sel = _selectedIdx == i;
        return AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) {
            return Transform.translate(
              offset: Offset(sel ? _shakeAnim.value : 0, 0),
              child: child,
            );
          },
          child: GestureDetector(
            onTap: () => _selectTrayPiece(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 80, height: 80,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel ? _K.purple : _K.border,
                  width: sel ? 2.5 : 1.5,
                ),
                boxShadow: sel
                    ? [BoxShadow(
                        color: _K.purple.withOpacity(0.3),
                        blurRadius: 10)]
                    : [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _PieceImage(
                  imagePath:  widget.imagePath,
                  pieceIndex: tray[i].correct,
                  grid:       _grid,
                  boardPx:    _grid * 80,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Tutorial ───────────────────────────────────────────────────────────────
  Widget _buildTutorial() {
  return GestureDetector(
    onTap: () {},
    child: Container(
      color: Colors.black45, // تقليل قتامة الخلفية السوداء قليلاً
      alignment: Alignment.center,
      child: Container(
        // تصغير الهوامش الجانبية لتصغير العرض الكلي
        margin: const EdgeInsets.symmetric(horizontal: 50), 
        // تقليل الحشوة الداخلية لتصغير الطول
        padding: const EdgeInsets.all(16), 
        decoration: BoxDecoration(
          // جعل الخلفية البيضاء شفافة بنسبة 90% (0.9)
          color: Colors.white.withOpacity(0.9), 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // تصغير حجم الإيموجي والعناوين
            const Text('🧩', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            const Text('كيف تلعب؟',
                style: TextStyle(
                    fontSize: 17, // تصغير الخط قليلاً
                    fontWeight: FontWeight.w900, 
                    color: _K.txtDark),
                textDirection: TextDirection.rtl),
            const SizedBox(height: 10),
            _tutStep == 0
                ? _tutBox('👇', 'اختر قطعة من القائمة بالأسفل', _K.purple)
                : _tutBox('👆', 'اضغط على مكانها في اللوحة', _K.teal),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity, 
              height: 40, // تقليل ارتفاع الزر
              child: ElevatedButton(
                onPressed: _tutStep == 0
                    ? () => setState(() => _tutStep = 1)
                    : _doneTutorial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _K.purple.withOpacity(0.9), // جعل الزر شفافاً قليلاً أيضاً
                  elevation: 0, // إلغاء الظل ليتناسب مع التصميم الشفاف
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _tutStep == 0 ? 'التالي ←' : 'هيا نلعب! 🎮',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, 
                      fontSize: 14),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _tutBox(String emoji, String text, Color color) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 26)),
      const SizedBox(width: 12),
      Expanded(child: Text(text,
          style: const TextStyle(fontSize: 13,
              color: _K.txtDark, height: 1.5),
          textDirection: TextDirection.rtl)),
    ]),
  );

  // ─── شاشة الفوز ─────────────────────────────────────────────────────────────
  Widget _buildWin() {
    return ScaleTransition(
      scale: _celebScale,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(
                color: _K.gold.withOpacity(0.25), blurRadius: 28)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Confetti(),
              const Text('🏆', style: TextStyle(fontSize: 58)),
              const SizedBox(height: 8),
              const Text('أحسنت يا ذكي! 🌟',
                  style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.w900, color: _K.txtDark),
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 4),
              Text('أتممت البزل في $_time',
                  style: const TextStyle(color: _K.txtMid, fontSize: 14),
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 22),
              Row(children: [
                Expanded(child: _winBtn(
                  label: '🔄 إعادة',
                  color: _K.teal,
                  light: true,
                  onTap: () => setState(() => _reset()),
                )),
                const SizedBox(width: 10),
                Expanded(child: _winBtn(
                  label: '🏠 الرئيسية',
                  color: _K.purple,
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HomeScreen(userId: widget.userId)),
                    (_) => false,
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _winBtn({
    required String    label,
    required Color     color,
    bool               light = false,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: light ? color.withOpacity(0.1) : color,
            borderRadius: BorderRadius.circular(14),
            border: light ? Border.all(color: color.withOpacity(0.35)) : null,
          ),
          child: Center(child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14,
                  color: light ? color : Colors.white),
              textDirection: TextDirection.rtl)),
        ),
      );

  // ─── ديالوج الخروج ──────────────────────────────────────────────────────────
  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⚠️', style: TextStyle(fontSize: 38)),
            const SizedBox(height: 10),
            const Text('هل تريد الخروج؟',
                style: TextStyle(fontSize: 17,
                    fontWeight: FontWeight.w800, color: _K.txtDark),
                textDirection: TextDirection.rtl),
            const SizedBox(height: 4),
            Text('ستفقد تقدمك في اللعبة',
                style: TextStyle(color: _K.txtMid, fontSize: 13),
                textDirection: TextDirection.rtl),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _winBtn(
                label: '🎮 متابعة',
                color: _K.purple,
                onTap: () => Navigator.pop(context),
              )),
              const SizedBox(width: 10),
              Expanded(child: _winBtn(
                label: '🏠 خروج',
                color: _K.orange,
                light: true,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => HomeScreen(userId: widget.userId)),
                    (_) => false,
                  );
                },
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ويدجت رسم قطعة البزل
// ══════════════════════════════════════════════════════════════════════════════
class _PieceImage extends StatelessWidget {
  final String imagePath;
  final int pieceIndex; 
  final int grid;       
  final int boardPx;    

  const _PieceImage({
    required this.imagePath,
    required this.pieceIndex,
    required this.grid,
    required this.boardPx,
  });

  @override
  Widget build(BuildContext context) {
    // 1. حساب الصف والعمود
    final int row = pieceIndex ~/ grid;
    final int col = pieceIndex % grid;

    // 2. حساب الإزاحة (تحويل رقم الصف والعمود إلى نسبة بين 0.0 و 1.0)
    final double xOffset = grid > 1 ? col / (grid - 1) : 0;
    final double yOffset = grid > 1 ? row / (grid - 1) : 0;

    return ClipRect( // يمنع تسرب أجزاء الصورة للخارج
      child: FractionallySizedBox(
        // نقوم بتكبير الصورة لتصبح بحجم اللوحة الكلية بالنسبة للمربع الصغير
        widthFactor: grid.toDouble(),
        heightFactor: grid.toDouble(),
        // نحدد أي جزء من الصورة الكبيرة سيظهر داخل هذا المربع
        alignment: FractionalOffset(xOffset, yOffset),
        child: Image.asset(
          imagePath,
          fit: BoxFit.fill, // نستخدم fill لضمان تطابق الأجزاء تماماً عند تجميعها
          cacheWidth: boardPx, // تحسين الأداء بناءً على عرض اللوحة
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// تأثير الاحتفال
// ══════════════════════════════════════════════════════════════════════════════
class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<_Dot>          _dots;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _dots = List.generate(16, (_) => _Dot(rng));
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54, width: double.infinity,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(_dots, _ctrl.value),
        ),
      ),
    );
  }
}

class _Dot {
  final double angle, speed, size;
  final Color  color;
  _Dot(Random r)
      : angle = r.nextDouble() * 2 * pi,
        speed = 0.4 + r.nextDouble() * 0.6,
        size  = 5 + r.nextDouble() * 9,
        color = [_K.gold, _K.purple, _K.pink, _K.teal, _K.orange][r.nextInt(5)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_Dot> dots;
  final double     t;
  _ConfettiPainter(this.dots, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final d in dots) {
      final p = (t * d.speed).clamp(0.0, 1.0);
      final x = size.width / 2 + cos(d.angle) * p * size.width * 0.46;
      final y = size.height / 2 + sin(d.angle) * p * size.height;
      canvas.drawCircle(
        Offset(x, y),
        d.size * (1 - p * 0.4),
        Paint()..color = d.color.withOpacity((1 - p).clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter o) => true;
}

// ─── زر الرجوع ─────────────────────────────────────────────────────────────
class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: _K.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _K.border),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: const Icon(Icons.close_rounded, color: _K.txtDark, size: 20),
      ),
    );
  }
}
