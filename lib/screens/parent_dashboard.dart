import 'package:flutter/material.dart';
import 'package:qisasi_app/data/database/database_helper.dart';

class ParentDashboardScreen extends StatefulWidget {
  final int userId;
  const ParentDashboardScreen({super.key, required this.userId});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen>
    with TickerProviderStateMixin {
  final DatabaseHelper _db = DatabaseHelper.instance;
  Map<String, dynamic>? _child;
  Map<String, dynamic>? _lastActivity;
  Map<String, dynamic> _summary = {'totalStoriesRead': 0, 'totalSeconds': 0};
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  List<Map<String, dynamic>> _characterStats = [];
  List<Map<String, dynamic>> _locationStats = [];
  List<Map<String, dynamic>> _moodStats = [];
  List<Map<String, dynamic>> _animalStats = []; // ✅ جديد: إحصائيات الحيوان
  bool _isChartsLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color _primary = Color(0xFF6C5CE7);
  static const Color _secondary = Color(0xFFA29BFE);
  static const Color _accent = Color(0xFFFDCB6E);
  static const Color _success = Color(0xFF00B894);
  static const Color _info = Color(0xFF0984E3);
  static const Color _warning = Color(0xFFE17055);
  static const Color _white = Color(0xFFFFFFFF);

  static const LinearGradient _bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F0FE), Color(0xFFF5F0FF)],
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final child = await _db.getUserById(widget.userId);

    if (child != null) {
      _child = child;

      _lastActivity = await _db.getLastActivityForChild(child['UserID']);
      _activities = await _db.getAllActivitiesForChild(child['UserID']);

      final summary = await _db.getChildSummary(child['UserID']);
      _summary['totalStoriesRead'] = summary['totalStoriesRead'];
      _summary['totalSeconds'] = await _db.getTotalReadingTime(child['UserID']);

      _characterStats = await _db.getCharacterStats(child['UserID']);
      _locationStats = await _db.getLocationStats(child['UserID']);
      _moodStats = await _db.getMoodStats(child['UserID']);
      _animalStats = await _db.getAnimalStats(child['UserID']); // ✅ جديد
    }

    setState(() {
      _isLoading = false;
      _isChartsLoading = false;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0 ثانية';

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    final List<String> parts = [];

    if (hours > 0) {
      parts.add('$hours ساعة');
    }
    if (minutes > 0) {
      parts.add('$minutes دقيقة');
    }
    if (seconds > 0) {
      parts.add('$seconds ثانية');
    }

    if (parts.isEmpty) return '0 ثانية';

    if (parts.length == 1) return parts[0];
    if (parts.length == 2) return '${parts[0]} و ${parts[1]}';
    return '${parts[0]} و ${parts[1]} و ${parts[2]}';
  }

  String _formatDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) return 'تاريخ غير معروف';
    try {
      final date = DateTime.parse(dateTimeString);
      final localDate = date.toLocal();

      final year = localDate.year;
      final month = localDate.month.toString().padLeft(2, '0');
      final day = localDate.day.toString().padLeft(2, '0');

      int hour12 = localDate.hour % 12;
      if (hour12 == 0) hour12 = 12;
      final hour = hour12.toString().padLeft(2, '0');
      final minute = localDate.minute.toString().padLeft(2, '0');
      final amPm = localDate.hour < 12 ? 'ص' : 'م';

      return '$year-$month-$day $hour:$minute $amPm';
    } catch (e) {
      return dateTimeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: _bgGradient),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _secondary],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.family_restroom,
                            color: _white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'لوحة تحكم الوالدين',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _primary,
                                ),
                              ),
                              Text(
                                ' تابع تقدم أطفالك في القراءة 🌟',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: _primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: CircularProgressIndicator(
                                    color: _primary,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  '✨ جاري تحميل البيانات ✨',
                                  style: TextStyle(color: _primary),
                                ),
                              ],
                            ),
                          )
                        : _child == null
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                _buildChildCard(),
                                const SizedBox(height: 20),
                              ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: _white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: _primary.withOpacity(0.15), blurRadius: 30),
              ],
            ),
            child: const Icon(Icons.people_outline, size: 70, color: _primary),
          ),
          const SizedBox(height: 24),
          const Text(
            '👶 لا يوجد طفل مرتبط بهذا الحساب',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChildCard() {
    final totalSeconds = _summary['totalSeconds'] ?? 0;

    final childName = _child?['Username'] ?? 'الطفل';
    final childAvatar = _child?['Avatar'] ?? '🧒';
    final childAge = _child?['Age'] ?? 'غير محدد';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primary.withOpacity(0.08),
                  _secondary.withOpacity(0.04),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(35),
                topRight: Radius.circular(35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _secondary, _accent],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      childAvatar,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        childName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 4),
                            Text(
                              'العمر: $childAge سنوات',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromARGB(255, 24, 23, 22),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_info.withOpacity(0.1), _info.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _info.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _info.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: _info,
                          size: 28,
                        ),
                      ),
                      const Text(
                        'القصص المقروءة',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        '${_summary['totalStoriesRead'] ?? 0}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _info,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _buildReadingTimeCard(totalSeconds),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _warning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _warning.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'آخر نشاط',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_lastActivity != null)
                        Text(
                          '📖 ${_lastActivity!['StoryTitle'] ?? 'عنوان غير معروف'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        )
                      else
                        const Text(
                          'لا يوجد نشاط بعد، شجع طفلك على قراءة أول قصة! 📚',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.right,
                        ),
                      if (_lastActivity != null &&
                          _lastActivity!['LogDate'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 11,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(
                                  _lastActivity!['LogDate'].toString(),
                                ),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _showActivityLog(childName),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 5,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'عرض سجل النشاطات كاملاً',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildChartsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTimeCard(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_success.withOpacity(0.1), _success.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _success.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.timer_rounded, color: _success, size: 40),
          const SizedBox(height: 12),
          const Text(
            'وقت القراءة',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hours > 0) _buildTimeUnit('$hours', 'ساعة'),
              if (minutes > 0) _buildTimeUnit('$minutes', 'دقيقة'),
              if (seconds > 0 || (hours == 0 && minutes == 0))
                _buildTimeUnit('$seconds', 'ثانية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String unit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _success.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _success,
            ),
          ),
          Text(unit, style: const TextStyle(fontSize: 12, color: _success)),
        ],
      ),
    );
  }

  void _showActivityLog(String childName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _secondary],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.list_alt, color: _white, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'سجل نشاطات $childName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _white,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_activities.length}',
                              style: const TextStyle(
                                color: _white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _activities.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'لا توجد نشاطات مسجلة',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: _activities.length,
                              itemBuilder: (context, index) {
                                final act = _activities[index];
                                final logDate =
                                    act['LogDate']?.toString() ?? '';
                                final durationSeconds = act['Duration'] ?? 0;
                                final durationFormatted = _formatDuration(
                                  durationSeconds,
                                );

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: _white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [_primary, _secondary],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: _white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      act['StoryTitle'] ?? 'عنوان غير معروف',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 12,
                                              color: _info,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDateTime(logDate),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: _info,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (durationSeconds > 0)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.timer,
                                                size: 12,
                                                color: _warning,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                durationFormatted,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: _warning,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _success.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: _success,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'مقروءة',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: _success,
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChartsSection() {
    if (_isChartsLoading) {
      return Column(
        children: [
          _buildChartLoadingCard('البطل المفضل'),
          const SizedBox(height: 12),
          _buildChartLoadingCard('الحيوان المفضل'), // ✅ جديد
          const SizedBox(height: 12),
          _buildChartLoadingCard('المكان المفضل'),
          const SizedBox(height: 12),
          _buildChartLoadingCard('المود المفضل'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.bar_chart, color: _primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'التحليلات والإحصائيات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatChartCard(
          title: '🏆 البطل المفضل',
          data: _characterStats,
          color: _warning,
          valueKey: 'CharacterName',
          countKey: 'count',
        ),
        const SizedBox(height: 10),
        _buildStatChartCard(
          title: '🐾 الحيوان المفضل', // ✅ جديد
          data: _animalStats,
          color: _accent,
          valueKey: 'AnimalName',
          countKey: 'count',
        ),
        const SizedBox(height: 10),
        _buildStatChartCard(
          title: '📍 المكان المفضل',
          data: _locationStats,
          color: _info,
          valueKey: 'LocationName',
          countKey: 'count',
        ),
        const SizedBox(height: 10),
        _buildStatChartCard(
          title: '🎭 المود المفضل',
          data: _moodStats,
          color: _success,
          valueKey: 'MoodName',
          countKey: 'count',
        ),
      ],
    );
  }

  Widget _buildChartLoadingCard(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.show_chart, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 6),
                const LinearProgressIndicator(color: _primary, minHeight: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChartCard({
    required String title,
    required List<Map<String, dynamic>> data,
    required Color color,
    required String valueKey,
    required String countKey,
  }) {
    if (data.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.insights, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'لا توجد بيانات كافية بعد',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    textAlign: TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final maxCount = data
        .map((e) => e[countKey] as int)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.leaderboard, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${data.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...data.map((item) {
            final name = item[valueKey] ?? 'غير محدد';
            final count = item[countKey] as int;
            final percentage = maxCount > 0 ? (count / maxCount) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: color.withOpacity(0.1),
                      color: color,
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
