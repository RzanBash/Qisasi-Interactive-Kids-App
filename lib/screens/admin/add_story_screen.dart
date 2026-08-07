import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qisasi_app/data/database/database_helper.dart';

class AddStoryScreen extends StatefulWidget {
  const AddStoryScreen({super.key});

  @override
  State<AddStoryScreen> createState() =>
      _AddStoryScreenState();
}

class _AddStoryScreenState
    extends State<AddStoryScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final titleController =
      TextEditingController();

  final contentController =
      TextEditingController();

  final picker = ImagePicker();

  int? selectedCharacter;
  int? selectedAnimal;
  int? selectedLocation;
  int? selectedMood;

  String? imagePath;

  bool _isPickingImage = false;

  // بالبداية فاضي
  bool? isCustomized;

  // 👇 مهم للأنيميشن الأول فقط
  bool firstSelectionDone = false;

  List<Map<String, dynamic>>
      characters = [];

  List<Map<String, dynamic>>
      animals = [];

  List<Map<String, dynamic>>
      locations = [];

  List<Map<String, dynamic>>
      moods = [];

  final Color bgColor =
      const Color(0xffF7F8FC);

  final Color primary =
      const Color(0xff1E3A8A);

  final Color dark =
      const Color(0xff111827);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final db =
        await DatabaseHelper.instance.database;

    characters =
        await db.query('Characters');

    animals =
        await db.query('Animals');

    locations =
        await db.query('Locations');

    moods =
        await db.query('Moods');

    setState(() {});
  }

  // ================= IMAGE =================

  Future<void> pickImage() async {
    if (_isPickingImage) return;

    _isPickingImage = true;

    try {
      final source =
          await showModalBottomSheet<
              ImageSource>(
        context: context,

        backgroundColor: Colors.white,

        shape:
            const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),

        builder: (_) {
          return SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.all(
                18,
              ),

              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Container(
                    width: 45,
                    height: 5,

                    decoration:
                        BoxDecoration(
                      color: Colors
                          .grey
                          .shade300,

                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  ListTile(
                    leading: Icon(
                      Icons
                          .photo_library_rounded,

                      color: primary,
                    ),

                    title: Text(
                      "اختيار من المعرض",

                      style:
                          GoogleFonts
                              .cairo(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    onTap: () {
                      Navigator.pop(
                        context,
                        ImageSource
                            .gallery,
                      );
                    },
                  ),

                  ListTile(
                    leading: Icon(
                      Icons
                          .camera_alt_rounded,

                      color: primary,
                    ),

                    title: Text(
                      "التقاط صورة",

                      style:
                          GoogleFonts
                              .cairo(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    onTap: () {
                      Navigator.pop(
                        context,
                        ImageSource
                            .camera,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      if (source == null) {
        _isPickingImage = false;
        return;
      }

      final XFile? file =
          await picker.pickImage(
        source: source,
      );

      if (file != null && mounted) {
        setState(() {
          imagePath = file.path;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    _isPickingImage = false;
  }

  // ================= SAVE =================

  Future<void> saveStory() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    final db =
        await DatabaseHelper.instance.database;

    if (isCustomized == false) {
      await db.insert('Stories', {
        'Title':
            titleController.text,

        'Content':
            contentController.text,

        'CoverImage':
            imagePath ?? '',

        'UserID': 1,

        'LocationID': 1,

        'MoodID': 1,

        'isCustomized': 0,
      });
    } else {
      int storyId =
          await db.insert('Stories', {
        'Title':
            titleController.text,

        'Content':
            contentController.text,

        'CoverImage':
            imagePath ?? '',

        'UserID': 1,

        'LocationID':
            selectedLocation,

        'MoodID':
            selectedMood,

        'isCustomized': 1,
      });

      await db.insert(
        'StoryCharacters',
        {
          'StoryID': storyId,
          'CharacterID':
              selectedCharacter,
        },
      );

      await db.insert(
        'StoryAnimals',
        {
          'StoryID': storyId,
          'AnimalID':
              selectedAnimal,
        },
      );
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        backgroundColor: primary,

        content: Text(
          "تم إضافة القصة بنجاح 🎉",

          style:
              GoogleFonts.cairo(
            color: Colors.white,
          ),
        ),
      ),
    );

    Future.delayed(
      const Duration(
          milliseconds: 700),
      () {
        Navigator.pop(
          context,
          true,
        );
      },
    );
  }

  // ================= STYLE =================

  InputDecoration fieldStyle(
    String text,
    IconData icon,
  ) {
    return InputDecoration(
      labelText: text,

      labelStyle:
          GoogleFonts.cairo(
        color: dark,
      ),

      prefixIcon:
          Icon(icon, color: primary),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide:
            BorderSide.none,
      ),
    );
  }

  // ================= DROPDOWN =================

  Widget dropField({
    required String hint,
    required IconData icon,
    required int? value,
    required List<
            Map<String, dynamic>>
        data,
    required String idKey,
    required String textKey,
    required Function(int?)
        onChanged,
  }) {
    return DropdownButtonFormField<
        int>(
      initialValue: value,

      decoration:
          fieldStyle(hint, icon),

      items: data.map((item) {
        return DropdownMenuItem<int>(
          value: item[idKey],

          child: Text(
            item[textKey],

            style:
                GoogleFonts.cairo(),
          ),
        );
      }).toList(),

      onChanged: onChanged,
    );
  }

  // ================= TYPE CARD =================

  Widget typeCard({
    required String title,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,

        child: AnimatedContainer(
          duration:
              const Duration(
            milliseconds: 400,
          ),

          curve:
              Curves.easeInOut,

          padding:
              const EdgeInsets.all(
            20,
          ),

          decoration: BoxDecoration(
            color: selected
                ? primary
                : Colors.white,

            borderRadius:
                BorderRadius.circular(
              26,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.06),

                blurRadius: 18,

                offset:
                    const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              Icon(
                icon,

                size: 50,

                color: selected
                    ? Colors.white
                    : primary,
              ),

              const SizedBox(
                height: 12,
              ),

              Text(
                title,

                style:
                    GoogleFonts.cairo(
                  color: selected
                      ? Colors.white
                      : dark,

                  fontWeight:
                      FontWeight.bold,

                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.rtl,

      child: Scaffold(
        backgroundColor: bgColor,

        appBar: AppBar(
          title: Text(
            "إضافة قصة",

            style:
                GoogleFonts.cairo(
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          centerTitle: true,

          elevation: 0,

          backgroundColor:
              Colors.transparent,

          foregroundColor: dark,
        ),

        body: SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            16,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              children: [

                // ================= الكاردات =================

                AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 950,
                  ),

                  curve:
                      Curves.easeInOutCubic,

                  height:
                      firstSelectionDone
                          ? 140
                          : MediaQuery.of(
                                      context)
                                  .size
                                  .height *
                              0.68,

                  alignment:
                      firstSelectionDone
                          ? Alignment
                              .topCenter
                          : Alignment
                              .center,

                  child: Row(
                    children: [
                      typeCard(
                        title:
                            "قصة جاهزة",

                        icon: Icons
                            .menu_book_rounded,

                        selected:
                            isCustomized ==
                                false,

                        onTap: () {
                          setState(() {

                            isCustomized =
                                false;

                            // 👇 أول مرة فقط
                            if (!firstSelectionDone) {
                              firstSelectionDone =
                                  true;
                            }
                          });
                        },
                      ),

                      const SizedBox(
                        width: 14,
                      ),

                      typeCard(
                        title:
                            "قصة مخصصة",

                        icon: Icons
                            .auto_awesome,

                        selected:
                            isCustomized ==
                                true,

                        onTap: () {
                          setState(() {

                            isCustomized =
                                true;

                            // 👇 أول مرة فقط
                            if (!firstSelectionDone) {
                              firstSelectionDone =
                                  true;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // ================= الفورم =================

                if (firstSelectionDone)
                  AnimatedOpacity(
                    duration:
                        const Duration(
                      milliseconds: 700,
                    ),

                    opacity: 1,

                    child:
                        AnimatedSlide(
                      duration:
                          const Duration(
                        milliseconds:
                            850,
                      ),

                      curve: Curves
                          .easeOutCubic,

                      offset:
                          Offset.zero,

                      child: Column(
                        children: [

                          // ================= IMAGE =================

                          GestureDetector(
                            onTap:
                                pickImage,

                            child:
                                Container(
                              height:
                                  190,

                              width: double
                                  .infinity,

                              decoration:
                                  BoxDecoration(
                                color: Colors
                                    .white,

                                borderRadius:
                                    BorderRadius.circular(
                                  24,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors
                                        .black
                                        .withOpacity(
                                            0.04),

                                    blurRadius:
                                        15,
                                  ),
                                ],
                              ),

                              child:
                                  imagePath ==
                                          null
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,

                                          children: [
                                            Icon(
                                              Icons.add_a_photo_rounded,

                                              size:
                                                  55,

                                              color:
                                                  primary,
                                            ),

                                            const SizedBox(
                                              height:
                                                  10,
                                            ),

                                            Text(
                                              "إضافة صورة للقصة",

                                              style:
                                                  GoogleFonts.cairo(
                                                color:
                                                    dark,

                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )

                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(
                                            24,
                                          ),

                                          child:
                                              Image.file(
                                            File(
                                              imagePath!,
                                            ),

                                            fit:
                                                BoxFit.cover,

                                            width:
                                                double.infinity,
                                          ),
                                        ),
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          // ================= FORM =================

                          Container(
                            padding:
                                const EdgeInsets.all(
                              18,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,

                              borderRadius:
                                  BorderRadius.circular(
                                24,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors
                                      .black
                                      .withOpacity(
                                          0.04),

                                  blurRadius:
                                      15,
                                ),
                              ],
                            ),

                            child:
                                Column(
                              children: [

                                TextFormField(
                                  controller:
                                      titleController,

                                  style:
                                      GoogleFonts.cairo(),

                                  decoration:
                                      fieldStyle(
                                    "عنوان القصة",

                                    Icons.title,
                                  ),

                                  validator:
                                      (v) =>
                                          v!.isEmpty
                                              ? "مطلوب"
                                              : null,
                                ),

                                const SizedBox(
                                  height:
                                      14,
                                ),

                                TextFormField(
                                  controller:
                                      contentController,

                                  maxLines:
                                      5,

                                  style:
                                      GoogleFonts.cairo(),

                                  decoration:
                                      fieldStyle(
                                    "محتوى القصة",

                                    Icons.menu_book,
                                  ),

                                  validator:
                                      (v) =>
                                          v!.isEmpty
                                              ? "مطلوب"
                                              : null,
                                ),

                                const SizedBox(
                                  height:
                                      14,
                                ),

                                if (isCustomized ==
                                    true) ...[
                                  dropField(
                                    hint:
                                        "الشخصية",

                                    icon:
                                        Icons.person,

                                    value:
                                        selectedCharacter,

                                    data:
                                        characters,

                                    idKey:
                                        "CharacterID",

                                    textKey:
                                        "CharacterName",

                                    onChanged:
                                        (v) =>
                                            setState(
                                      () {
                                        selectedCharacter =
                                            v;
                                      },
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        12,
                                  ),

                                  dropField(
                                    hint:
                                        "الحيوان",

                                    icon:
                                        Icons.pets,

                                    value:
                                        selectedAnimal,

                                    data:
                                        animals,

                                    idKey:
                                        "AnimalID",

                                    textKey:
                                        "AnimalName",

                                    onChanged:
                                        (v) =>
                                            setState(
                                      () {
                                        selectedAnimal =
                                            v;
                                      },
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        12,
                                  ),

                                  dropField(
                                    hint:
                                        "الموقع",

                                    icon:
                                        Icons.place,

                                    value:
                                        selectedLocation,

                                    data:
                                        locations,

                                    idKey:
                                        "LocationID",

                                    textKey:
                                        "LocationName",

                                    onChanged:
                                        (v) =>
                                            setState(
                                      () {
                                        selectedLocation =
                                            v;
                                      },
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        12,
                                  ),

                                  dropField(
                                    hint:
                                        "المود",

                                    icon: Icons
                                        .emoji_emotions,

                                    value:
                                        selectedMood,

                                    data:
                                        moods,

                                    idKey:
                                        "MoodID",

                                    textKey:
                                        "MoodName",

                                    onChanged:
                                        (v) =>
                                            setState(
                                      () {
                                        selectedMood =
                                            v;
                                      },
                                    ),
                                  ),

                                  const SizedBox(
                                    height:
                                        14,
                                  ),
                                ],

                                SizedBox(
                                  width:
                                      double.infinity,

                                  height:
                                      54,

                                  child:
                                      ElevatedButton(
                                    onPressed:
                                        saveStory,

                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          primary,

                                      elevation:
                                          0,

                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                      ),
                                    ),

                                    child:
                                        Text(
                                      "حفظ القصة",

                                      style:
                                          GoogleFonts.cairo(
                                        color:
                                            Colors.white,

                                        fontWeight:
                                            FontWeight.bold,

                                        fontSize:
                                            16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}