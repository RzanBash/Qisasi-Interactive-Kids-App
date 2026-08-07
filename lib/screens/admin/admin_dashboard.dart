import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:qisasi_app/data/database/database_helper.dart';


import 'package:qisasi_app/screens/login_screen.dart'; 

import 'manage_stories_screen.dart';
import 'manage_elements_screen.dart';
import 'manage_users_screen.dart';

// ================= ROOT DASHBOARD =================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int index = 0;

  final List<Widget> pages = const [
    DashboardHome(),
    ManageStoriesScreen(),
    ManageElementsScreen(),
    ManageUsersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffF6F8FC),

        body: IndexedStack(
          index: index,
          children: pages,
        ),

        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 25,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xff1E3A8A),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle:
                GoogleFonts.cairo(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: "الرئيسية"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.menu_book), label: "القصص"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.widgets), label: "العناصر"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people), label: "المستخدمين"),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= DASHBOARD HOME =================
class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final db = DatabaseHelper.instance;

  int users = 0;
  int stories = 0;
  int elements = 0;
  int activeUsers = 0;
  int frozenUsers = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final database = await db.database;

    users = Sqflite.firstIntValue(
          await database.rawQuery("SELECT COUNT(*) FROM Users"),
        ) ??
        0;

    stories = Sqflite.firstIntValue(
          await database.rawQuery("SELECT COUNT(*) FROM Stories"),
        ) ??
        0;

    final chars = Sqflite.firstIntValue(
          await database.rawQuery("SELECT COUNT(*) FROM Characters"),
        ) ??
        0;

    final loc = Sqflite.firstIntValue(
          await database.rawQuery("SELECT COUNT(*) FROM Locations"),
        ) ??
        0;

    final moods = Sqflite.firstIntValue(
          await database.rawQuery("SELECT COUNT(*) FROM Moods"),
        ) ??
        0;

    final animals = Sqflite.firstIntValue(
          await database.rawQuery("SELECT COUNT(*) FROM Animals"),
        ) ??
        0;

    activeUsers = Sqflite.firstIntValue(
          await database.rawQuery(
              "SELECT COUNT(*) FROM Users WHERE IsActive=1"),
        ) ??
        0;

    frozenUsers = Sqflite.firstIntValue(
          await database.rawQuery(
              "SELECT COUNT(*) FROM Users WHERE IsActive=0"),
        ) ??
        0;

    if (!mounted) return;

    setState(() {
      elements = chars + loc + moods + animals;
    });
  }

 @override
Widget build(BuildContext context) {
  return SafeArea(
    child: RefreshIndicator(
      onRefresh: loadData,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [

          // ================= HEADER =================
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 22, 45, 106),
                  Color.fromARGB(255, 67, 117, 198),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              textDirection: TextDirection.ltr,
              children: [

                // 🔴 الأيقونة (يسار)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // 🟦 النص (يمين)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "لوحة التحكم",
                          style: GoogleFonts.cairo(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 254, 254),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "إدارة شاملة للتطبيق، مع عرض مباشر للإحصائيات والأداء",
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================= CARDS =================
          _tile("المستخدمين", users, Icons.people, Colors.blue),
          _tile("القصص", stories, Icons.menu_book, const Color.fromARGB(255, 150, 17, 150)),
          _tile("العناصر", elements, Icons.widgets, Colors.orange),
          _tile("الحسابات المغعلة", activeUsers, Icons.verified_user, const Color.fromARGB(255, 6, 152, 84)),
          _tile("الحسابات المجمدة", frozenUsers, Icons.lock, Colors.grey),
        ],
      ),
    ),
  );
}
  // ================= TILE =================
Widget _tile(String title, int value, IconData icon, Color color) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
   child: Row(
  textDirection: TextDirection.ltr,
  children: [

    Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    ),

    const SizedBox(width: 12),

 Expanded(
  child: Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: "$title: ",
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        TextSpan(
          text: value.toString(),
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    ),
    textAlign: TextAlign.right,
  ),
),
  ],
),
  );
}
}
