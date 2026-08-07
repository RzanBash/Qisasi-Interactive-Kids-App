import 'package:flutter/material.dart';
import '../data/database/database_helper.dart';
import '../engine/story_engine.dart';
import 'story_view_screen.dart';

class CustomizeScreen extends StatefulWidget {
  final int userId;
  const CustomizeScreen({super.key, required this.userId});

  @override
  State<CustomizeScreen> createState() => _CustomizeScreenState();
}

class _CustomizeScreenState extends State<CustomizeScreen> {
  int _step = 0;
  static const int _totalSteps = 4;

  late PageController _pageController;
  int? _selectedCharacterId, _selectedAnimalId, _selectedLocationId, _selectedMoodId;
  String? _selCharPath, _selAnimalPath, _selLocPath, _selMoodPath;

  // متغيرات لحفظ الأسماء المختارة ديناميكياً لعرضها في البطاقة
  String? _selCharName, _selAnimalName, _selLocName, _selMoodName;

  List<Map<String, dynamic>> _characters = [], _animals = [], _locations = [], _moods = [];
  bool _loading = true, _searching = false;

  // ألوان مبهجة ومناسبة للخلفية الفاتحة
  static const _stepColors = [
    Color(0xFF6C63FF), // بنفسجي ناعم
    Color(0xFF00BFA6), // تركواز
    Color(0xFF3F8CFF), // أزرق سماوي
    Color(0xFFFF9F43), // برتقالي دافئ
  ];

  static const _stepTitles = [
    'من تريد أن يكون بطل القصة؟',
    'اختر الحيوان الذي سيظهر معك',
    'اختر المكان الذي ستبدأ فيه القصة',
    'اختر كيف سيكون شكل القصة',
  ];

  // نصوص الخطوات الافتراضية للبطاقة في حال عدم الاختيار بعد
  static const _stepLabels = ['البطل', 'الحيوان', 'المكان', 'نوع القصة'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.55);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final db = await DatabaseHelper.instance.database;
    final data = await Future.wait([
      db.query('Characters'),
      db.query('Animals'),
      db.query('Locations'),
      db.query('Moods'),
    ]);
    
    if (mounted) {
      setState(() {
        _characters = data[0];
        _animals = data[1];
        _locations = data[2];
        _moods = data[3];
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getCurrentList() => [_characters, _animals, _locations, _moods][_step];

  void _onElementSelected(Map<String, dynamic> item) {
    final idKey = ['CharacterID', 'AnimalID', 'LocationID', 'MoodID'][_step];
    final nameKey = ['CharacterName', 'AnimalName', 'LocationName', 'MoodName'][_step];
    
    final id = item[idKey] as int;
    final path = item['ImagePath'] as String;
    final name = item[nameKey] as String;

    setState(() {
      if (_step == 0) { 
        _selectedCharacterId = id; 
        _selCharPath = path; 
        _selCharName = name; 
      }
      else if (_step == 1) { 
        _selectedAnimalId = id; 
        _selAnimalPath = path; 
        _selAnimalName = name; 
      }
      else if (_step == 2) { 
        _selectedLocationId = id; 
        _selLocPath = path; 
        _selLocName = name; 
      }
      else { 
        _selectedMoodId = id; 
        _selMoodPath = path; 
        _selMoodName = name; 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC), 
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
      );
    }
    
    final currentList = _getCurrentList();
    final stepColor = _stepColors[_step];

    return Scaffold( 
      backgroundColor: const Color(0xFFF7F9FC), 
      body: SafeArea(
        child: Column(
          children: [
            _buildCleanAppBar(), // البار العلوي النظيف والمتغير الألوان
            Expanded(
              child: _searching 
                  ? _buildSearching() 
                  : _buildStageWithButtons(currentList, stepColor),
            ),
            _buildBottomControls(stepColor),
          ],
        ),
      ),
    );
  }

Widget _buildCleanAppBar() {
  final stepColor = _stepColors[_step]; // جلب لون الخطوة الحالية لكارد السؤال

  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 10) {
          Navigator.pop(context);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // إضافة أنيميشن ناعم لتغيير التدرج بين الخطوات
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          // استخدام التدرج اللوني (Gradient) من الأعلى إلى الأسفل ديناميكياً
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              stepColor,                            // اللون الأساسي في الأعلى
              stepColor.withValues(alpha: 0.75),   // درجة أفتح وأنعم من نفس اللون في الأسفل
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: stepColor.withValues(alpha: 0.25), // ظل ناعم متناسق مع لون الكارد
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // لضمان توسيط محتويات الـ Column أفقياً
          mainAxisAlignment: MainAxisAlignment.center,   // لضمان التوسيط عمودياً
          children: [
            // مؤشر السحب بلون أبيض شفاف ليناسب التدرج الملون الجديد
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(height: 12),
            
            // نص السؤال مستقر في المنتصف تماماً وبكل أناقة
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                width: double.infinity,
                alignment: Alignment.center, // توسيط النص بداخل الحاوية
                child: Text(
                  _stepTitles[_step],
                  key: ValueKey<int>(_step),
                  textAlign: TextAlign.center, // توسيط النص نفسه
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900, 
                    color: Colors.white, // النص باللون الأبيض ليكون واضحاً فوق التدرج
                    height: 1.3,
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

  Widget _buildStageWithButtons(List<Map<String, dynamic>> items, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: items.length,
          physics: const NeverScrollableScrollPhysics(), 
          clipBehavior: Clip.none,
          itemBuilder: (context, index) {
            final item = items[index];
            final id = item[['CharacterID', 'AnimalID', 'LocationID', 'MoodID'][_step]];
            bool isSelected = false;
            if (_step == 0) {
              isSelected = _selectedCharacterId == id;
            } else if (_step == 1) {
              isSelected = _selectedAnimalId == id;
            } else if (_step == 2) {
              isSelected = _selectedLocationId == id;
            } else {
              isSelected = _selectedMoodId == id;
            }

            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 0.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                }
                double scale = (1 - (value.abs() * 0.35)).clamp(0.65, 1.0);
                return Transform.scale(
                  scale: isSelected && value.abs() < 0.1 ? 1.15 : scale,
                  child: _buildStageElement(item, isSelected, color, value.abs() < 0.2),
                );
              },
            );
          },
        ),
        _buildNavArrow(Icons.chevron_left_rounded, Alignment.centerLeft, () {
          int prev = _pageController.page!.round() - 1;
          if (prev >= 0) {
            _pageController.jumpToPage(prev);
          }
        }),
        _buildNavArrow(Icons.chevron_right_rounded, Alignment.centerRight, () {
          int next = _pageController.page!.round() + 1;
          if (next < items.length) {
            _pageController.jumpToPage(next);
          }
        }),
      ],
    );
  }

  Widget _buildStageElement(Map<String, dynamic> item, bool isSelected, Color color, bool isCenter) {
    final nameKey = ['CharacterName', 'AnimalName', 'LocationName', 'MoodName'][_step];
    final String name = item[nameKey];

    return GestureDetector(
      onTap: () => _onElementSelected(item),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, 
        children: [
          // 1. اسم العنصر في الأعلى
          Text(
            name,
            style: TextStyle(
              fontSize: isSelected && isCenter ? 22 : 16,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2D3748), 
              shadows: [
                Shadow(color: color.withValues(alpha: 0.2), blurRadius: 10), 
              ],
            ),
          ),
          
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected && isCenter)
                Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 40, spreadRadius: 5)],
                  ),
                ),
             
              Image.asset(
                item['ImagePath'], 
                height: MediaQuery.of(context).size.height * 0.38, 
                fit: BoxFit.contain,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavArrow(IconData icon, Alignment align, VoidCallback onTap) {
    return Align(
      alignment: align,
      child: IconButton(
        icon: Icon(icon, color: Colors.black.withValues(alpha: 0.24), size: 60), 
        onPressed: onTap,
      ),
    );
  }

  Widget _buildBottomControls(Color stepColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCurrentStoryCard(stepColor),
        const SizedBox(height: 8),
        _buildNextButton(stepColor),
        const SizedBox(height: 16), 
      ],
    );
  }

  Widget _buildCurrentStoryCard(Color accent) {
    final List<_StorySlot> slots = [
      _StorySlot(label: _selCharName ?? 'البطل',     path: _selCharPath,   icon: Icons.person_rounded),
      _StorySlot(label: _selAnimalName ?? 'الحيوان', path: _selAnimalPath, icon: Icons.pets_rounded),
      _StorySlot(label: _selLocName   ?? 'المكان',  path: _selLocPath,   icon: Icons.home_rounded),
      _StorySlot(label: _selMoodName  ?? 'نوع القصة', path: _selMoodPath, icon: Icons.menu_book_rounded),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end, 
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('قصتي الحالية',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: slots.asMap().entries.map((e) {
              final idx  = e.key;
              final slot = e.value;
              final hasValue = slot.path != null;
              final isCurrentStep = _step == idx;

              bool isClickable = idx <= _step || (idx == _step + 1 && _canProceed) || hasValue;

              return GestureDetector(
                onTap: isClickable ? () {
                  setState(() {
                    _step = idx;
                  });
                  _pageController.jumpToPage(0); 
                } : null,
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasValue ? Colors.transparent : Colors.grey.shade50,
                            border: Border.all(
                              color: isCurrentStep ? accent : (hasValue ? accent.withValues(alpha: 0.5) : Colors.grey.shade300),
                              width: isCurrentStep ? 2.5 : 1.5,
                            ),
                          ),
                          child: hasValue
                              ? ClipOval(child: Image.asset(slot.path!, fit: BoxFit.contain))
                              : Icon(slot.icon, color: Colors.grey.shade400, size: 22),
                        ),
                        if (idx < 3)
                          Positioned(
                            right: -18, top: 14,
                            child: Row(children: [
                              _dot(hasValue ? accent : Colors.grey.shade300),
                              const SizedBox(width: 2),
                              _dot(hasValue ? accent : Colors.grey.shade300),
                            ]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasValue ? slot.label : _stepLabels[idx],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
                        color: hasValue ? accent : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 4, height: 4,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildNextButton(Color btnColor) {
    final isLast = _step == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedOpacity(
        opacity: _canProceed ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 250),
        child: GestureDetector(
          onTap: _canProceed ? _nextStep : null,
          child: Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              color: btnColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: _canProceed
                  ? [BoxShadow(color: btnColor.withValues(alpha: 0.3), blurRadius: 18, offset: const Offset(0, 6))]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
               
                Text(
                  isLast ? 'اصنع قصتي' : 'التالي',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
               
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canProceed => [_selectedCharacterId, _selectedAnimalId, _selectedLocationId, _selectedMoodId][_step] != null;

  void _nextStep() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      _pageController.jumpToPage(0);
    } else { 
      _findStory(); 
    }
  }

  Future<void> _findStory() async {
    setState(() => _searching = true);
    final story = await StoryEngine().findBestStory(
      moodId: _selectedMoodId!, 
      locationId: _selectedLocationId!, 
      characterId: _selectedCharacterId, 
      animalId: _selectedAnimalId
    );
    setState(() => _searching = false);
    if (story == null) return;
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(
        builder: (_) => StoryViewScreen(
          story: story, 
          userId: widget.userId, 
          characterId: _selectedCharacterId, 
          animalId: _selectedAnimalId, 
          locationId: _selectedLocationId!, 
          moodId: _selectedMoodId!
        )
      )
    );
  }

  Widget _buildSearching() => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
}

class _StorySlot {
  final String   label;
  final String?  path;
  final IconData icon;
  const _StorySlot({required this.label, required this.path, required this.icon});
}