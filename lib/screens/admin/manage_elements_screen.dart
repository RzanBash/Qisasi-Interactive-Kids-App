import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qisasi_app/data/database/database_helper.dart';

class ManageElementsScreen extends StatefulWidget {
  const ManageElementsScreen({super.key});

  @override
  State<ManageElementsScreen> createState() =>
      _ManageElementsScreenState();
}

class _ManageElementsScreenState extends State<ManageElementsScreen> {
  final _dbHelper = DatabaseHelper.instance;

  final Color bgColor = const Color(0xffF7F8FC);
  final Color primary = const Color(0xff1E3A8A);
  final Color dark = const Color(0xff111827);

  late Future<List<Map<String, dynamic>>> charactersFuture;
  late Future<List<Map<String, dynamic>>> locationsFuture;
  late Future<List<Map<String, dynamic>>> moodsFuture;
  late Future<List<Map<String, dynamic>>> animalsFuture;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() {
    charactersFuture = _dbHelper.getAll("Characters");
    locationsFuture = _dbHelper.getAll("Locations");
    moodsFuture = _dbHelper.getAll("Moods");
    animalsFuture = _dbHelper.getAll("Animals");
  }

  void showMessage(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.cairo(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void showAddDialog(String table, String nameCol, String title) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          "إضافة $title",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.cairo(),
          decoration: InputDecoration(
            hintText: "اكتب الاسم",
            hintStyle: GoogleFonts.cairo(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إلغاء",
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _dbHelper.insertItem(table, {
                  nameCol: controller.text,
                });

                Navigator.pop(context);
                setState(() => loadData());

                showMessage("تمت الإضافة بنجاح", Colors.green);
              }
            },
            child: Text(
              "حفظ",
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> confirmDelete(String table, String idCol, int id) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          "تأكيد الحذف",
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "هل أنت متأكد من حذف العنصر؟",
          style: GoogleFonts.cairo(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "إلغاء",
              style: GoogleFonts.cairo(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);

              await _dbHelper.deleteItem(table, idCol, id);
              setState(() => loadData());

              showMessage("تم الحذف", Colors.red);
            },
            child: Text(
              "حذف",
              style: GoogleFonts.cairo(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: bgColor,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: dark,
          title: Text(
            "إدارة العناصر",
            style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: primary,
            labelColor: primary,
            unselectedLabelColor: Colors.grey,
            labelStyle: GoogleFonts.cairo(),
            tabs: const [
              Tab(text: "Characters"),
              Tab(text: "Locations"),
              Tab(text: "Moods"),
              Tab(text: "Animals"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            buildPage(charactersFuture, "CharacterID", "CharacterName", "Characters"),
            buildPage(locationsFuture, "LocationID", "LocationName", "Locations"),
            buildPage(moodsFuture, "MoodID", "MoodName", "Moods"),
            buildPage(animalsFuture, "AnimalID", "AnimalName", "Animals"),
          ],
        ),
      ),
    );
  }

  Widget buildPage(
    Future<List<Map<String, dynamic>>> future,
    String idCol,
    String nameCol,
    String table,
  ) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data!;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    table,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      showAddDialog(table, nameCol, table);
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      "إضافة",
                      style: GoogleFonts.cairo(color: Colors.white),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              items[i][nameCol],
                              style: GoogleFonts.cairo(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: dark,
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              confirmDelete(
                                table,
                                idCol,
                                items[i][idCol],
                              );
                            },
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}