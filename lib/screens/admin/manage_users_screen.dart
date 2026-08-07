
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qisasi_app/data/database/database_helper.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _db = DatabaseHelper.instance;

  final Color bgColor = const Color(0xffF7F8FC);
  final Color primary = const Color(0xff1E3A8A);

  Future<List<Map<String, dynamic>>> usersFuture = Future.value([]);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      activateAdmin();
    });
  }

  Future<void> activateAdmin() async {
    await _db.activateUser(1);
    loadData();
  }

  void loadData() {
    setState(() {
      usersFuture = _db.getUsersWithRoles();
    });
  }

  //==================== SNACKBAR ====================

  void showMsg(String text, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  //==================== ROLE ====================

  Color roleColor(String role) {
    switch (role) {
      case "admin":
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  String roleText(String role) {
    switch (role) {
      case "admin":
        return "مدير";
      default:
        return "طفل";
    }
  }

  //==================== STATUS ====================

  bool isActive(Map user) {
    return (user['IsActive'] ?? 1) == 1;
  }

  String statusText(bool active) {
    return active ? "مفعل" : "مجمد";
  }

  Color statusColor(bool active) {
    return active ? Colors.green : Colors.grey;
  }

  //==================== TOGGLE ====================

  Future<void> toggleUser(Map<String, dynamic> user) async {
    if (user['IsActive'] == 1) {
      await _db.freezeUser(user['UserID']);
      showMsg("تم تجميد الحساب", Colors.grey);
    } else {
      await _db.activateUser(user['UserID']);
      showMsg("تم تفعيل الحساب", Colors.green);
    }

    loadData();
  }

  //==================== DELETE ====================

  void confirmDelete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "تأكيد الحذف",
            style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
          ),
          content: Text(
            "هل تريد حذف ${user['Username']} ؟",
            style: GoogleFonts.tajawal(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("إلغاء", style: GoogleFonts.tajawal()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _db.deleteUser(user['UserID']);
                Navigator.pop(context);
                loadData();
                showMsg("تم حذف المستخدم", Colors.red);
              },
              child: Text(
                "حذف",
                style: GoogleFonts.tajawal(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //==================== INPUT STYLE ====================

  InputDecoration inputStyle(String text, IconData icon) {
    return InputDecoration(
      hintText: text,
      hintStyle: GoogleFonts.tajawal(
        fontSize: 14,
        color: Colors.grey[500],
      ),
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: const Color(0xffF7F8FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 1.3),
      ),
    );
  }

  //==================== ADD / EDIT ====================

  void showAddEditDialog({Map<String, dynamic>? user}) {
    final nameController =
        TextEditingController(text: user?['Username'] ?? '');

    final emailController =
        TextEditingController(text: user?['Email'] ?? '');

    final passwordController = TextEditingController();

    int roleId = user?['RoleName'] == "admin" ? 1 : 2;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 34,
                            backgroundColor: primary.withOpacity(.10),
                            child: Icon(
                              user == null
                                  ? Icons.person_add_alt_1_rounded
                                  : Icons.edit_rounded,
                              color: primary,
                              size: 30,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            user == null
                                ? "إضافة مستخدم"
                                : "تعديل المستخدم",
                            style: GoogleFonts.tajawal(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 22),

                        //================ NAME =================
                        TextFormField(
                          controller: nameController,
                          textAlign: TextAlign.right,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "أدخل الاسم";
                            }
                            return null;
                          },
                          decoration: inputStyle("اسم المستخدم", Icons.person),
                        ),

                        const SizedBox(height: 16),

                        //================ EMAIL =================
                        TextFormField(
                          controller: emailController,
                          textAlign: TextAlign.right,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return "أدخل الإيميل";
                            }

                            final emailRegex = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );

                            if (!emailRegex.hasMatch(v.trim())) {
                              return "صيغة الإيميل غير صحيحة";
                            }

                            return null;
                          },
                          decoration: inputStyle(
                            "البريد الإلكتروني",
                            Icons.email,
                          ),
                        ),

                        const SizedBox(height: 16),

                        //================ PASSWORD =================
                        TextFormField(
                          controller: passwordController,
                          textAlign: TextAlign.right,
                          obscureText: true,
                          decoration: inputStyle(
                            user == null
                                ? "كلمة المرور"
                                : "كلمة مرور جديدة (اختياري)",
                            Icons.lock,
                          ),
                        ),

                        const SizedBox(height: 16),

                        //================ ROLE =================
                        DropdownButtonFormField<int>(
                          value: roleId,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text("مدير")),
                            DropdownMenuItem(value: 2, child: Text("طفل")),
                          ],
                          onChanged: (v) {
                            setStateDialog(() {
                              roleId = v!;
                            });
                          },
                          decoration: inputStyle(
                            "الصلاحية",
                            Icons.admin_panel_settings,
                          ),
                        ),

                        const SizedBox(height: 24),

                        //================ BUTTONS =================
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                ),
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }

                                  final email = emailController.text.trim();
                                  final password =
                                      passwordController.text.trim();

                                  if (user == null) {
                                    if (password.isEmpty) {
                                      showMsg(
                                        "أدخل كلمة المرور",
                                        Colors.red,
                                      );
                                      return;
                                    }

                                    await _db.insertUserWithRole(
                                      username: nameController.text.trim(),
                                      email: email,
                                      password: password,
                                      roleId: roleId,
                                    );

                                    showMsg("تمت الإضافة", Colors.green);
                                  } else {
                                 await _db.updateUserWithRole(
                            userId: user['UserID'],
                        username: nameController.text.trim(),
                    email: email,
                    roleId: roleId,
                      password: password.trim().isEmpty
                     ? user['Password']
                         : password.trim(),
                              );

                                    showMsg("تم التعديل", Colors.blue);
                                  }

                                  Navigator.pop(context);
                                  loadData();
                                },
                                child: Text(
                                  "حفظ",
                                  style: GoogleFonts.tajawal(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  "إلغاء",
                                  style: GoogleFonts.tajawal(color: primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: primary,
          centerTitle: true,
          title: Text(
            "إدارة المستخدمين",
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        floatingActionButtonLocation:
            FloatingActionButtonLocation.startFloat,

        floatingActionButton: FloatingActionButton(
          backgroundColor: primary,
          onPressed: () => showAddEditDialog(),
          child: const Icon(Icons.add, color: Colors.white),
        ),

        body: FutureBuilder(
          future: usersFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                final role = u['RoleName'] ?? "child";
                final active = isActive(u);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            roleColor(role).withOpacity(.12),
                        child: Icon(
                          role == "admin"
                              ? Icons.manage_accounts_rounded
                              : Icons.face_rounded,
                          color: roleColor(role),
                        ),
                      ),
                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u['Username'],
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              u['Email'] ?? '',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        icon: Icon(
                          active
                              ? Icons.verified_user_rounded
                              : Icons.lock_rounded,
                          color: active ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => toggleUser(u),
                      ),

                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == "edit") {
                            showAddEditDialog(user: u);
                          }
                          if (value == "delete") {
                            confirmDelete(u);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: "edit",
                            child: Text("تعديل"),
                          ),
                          PopupMenuItem(
                            value: "delete",
                            child: Text("حذف"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}