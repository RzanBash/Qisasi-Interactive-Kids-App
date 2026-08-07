import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qisasi_app/data/database/database_helper.dart';

import 'add_story_screen.dart';
import 'story_details_screen.dart';
import 'edit_story_screen.dart';

class ManageStoriesScreen extends StatefulWidget {
  const ManageStoriesScreen({super.key});

  @override
  State<ManageStoriesScreen> createState() =>
      _ManageStoriesScreenState();
}

class _ManageStoriesScreenState
    extends State<ManageStoriesScreen> {
  final _dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _stories = [];
  bool _isLoading = true;

  final TextEditingController _searchController =
      TextEditingController();

  final Color primary = const Color(0xff1E3A8A);

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await DatabaseHelper.instance.fixStoriesData();
    await _loadStories();
  }

  Future<void> _loadStories() async {
    final data = await _dbHelper.getStoriesWithDetails();

    final sorted = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) => (a['StoryID'] as int)
          .compareTo(b['StoryID'] as int));

    if (!mounted) return;

    setState(() {
      _stories = sorted;
      _isLoading = false;
    });
  }

  void _filter(String value) async {
    final all = await _dbHelper.getStoriesWithDetails();

    final filtered = all.where((story) {
      final title = (story['Title'] ?? '')
          .toString()
          .toLowerCase();

      return title.contains(value.toLowerCase());
    }).toList();

    if (!mounted) return;

    setState(() {
      _stories = filtered;
    });
  }

  Future<void> _deleteStory(int id) async {
    await _dbHelper.deleteItem('Stories', 'StoryID', id);
    await _loadStories();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("تم حذف القصة")),
    );
  }

  // ================= IMAGE HANDLER =================
  Widget buildImage(String? image) {
    if (image == null || image.trim().isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image),
      );
    }

    // asset image
    if (image.startsWith('assets/')) {
      return Image.asset(image, fit: BoxFit.cover);
    }

    // file image (from phone)
    return Image.file(
      File(image),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image),
      ),
    );
  }

  Widget _card(Map<String, dynamic> story) {
    final image = story['CoverImage'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),

        leading: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 58,
                height: 58,
                child: buildImage(image),
              ),
            ),

            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "#${story['StoryID']}",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        title: Text(
          story['Title'] ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),

        subtitle: Text(
          story['isCustomized'] == 1 ? "مخصصة" : "جاهزة",
          textAlign: TextAlign.right,
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: story['isCustomized'] == 1
                ? Colors.orange
                : Colors.green,
          ),
        ),

        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'view':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        StoryDetailsScreen(story: story),
                  ),
                );
                break;

              case 'edit':
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        EditStoryScreen(story: story),
                  ),
                );

                if (result == true) {
                  _loadStories();
                }
                break;

              case 'delete':
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("تأكيد الحذف"),
                    content: const Text("هل أنتِ متأكدة؟"),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text("إلغاء"),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text("حذف"),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await _deleteStory(story['StoryID']);
                }
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'view', child: Text("عرض")),
            PopupMenuItem(value: 'edit', child: Text("تعديل")),
            PopupMenuItem(
              value: 'delete',
              child: Text("حذف",
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: AppBar(
          title: Text(
            "إدارة القصص",
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: "ابحث عن قصة...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const AddStoryScreen(),
                    ),
                  );

                  if (result == true) {
                    _loadStories();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  minimumSize:
                      const Size(double.infinity, 48),
                ),
                child: Text(
                  "إضافة قصة",
                  style: GoogleFonts.cairo(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _stories.length,
                      itemBuilder: (context, i) =>
                          _card(_stories[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}