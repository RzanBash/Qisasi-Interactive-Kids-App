import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:qisasi_app/data/database/database_helper.dart';

class EditStoryScreen extends StatefulWidget {
  final Map<String, dynamic> story;

  const EditStoryScreen({
    super.key,
    required this.story,
  });

  @override
  State<EditStoryScreen> createState() =>
      _EditStoryScreenState();
}

class _EditStoryScreenState
    extends State<EditStoryScreen> {
  final dbHelper = DatabaseHelper.instance;

  late TextEditingController titleController;

  File? selectedImage;

  final Color bgColor =
      const Color(0xffF7F8FC);

  final Color primary =
      const Color(0xff1E3A8A);

  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(
      text: widget.story['Title'],
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final XFile? image =
        await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image != null) {
      setState(() {
        selectedImage =
            File(image.path);
      });
    }
  }

  Future<void> saveStory() async {
    final db =
        await dbHelper.database;

    String imagePath =
        widget.story['CoverImage'];

    if (selectedImage != null) {
      imagePath =
          selectedImage!.path;
    }

    await db.update(
      "Stories",
      {
        "Title":
            titleController.text,
        "CoverImage":
            imagePath,
      },
      where: "StoryID = ?",
      whereArgs: [
        widget.story['StoryID']
      ],
    );

    if (mounted) {
      ScaffoldMessenger.of(
              context)
          .showSnackBar(
        SnackBar(
          content: Text(
            "تم حفظ التعديلات",
            style:
                GoogleFonts.cairo(),
          ),
        ),
      );

      Navigator.pop(
          context, true);
    }
  }

  Widget buildImage() {
    if (selectedImage != null) {
      return Image.file(
        selectedImage!,
        fit: BoxFit.cover,
      );
    }

    final oldImage =
        widget.story['CoverImage'];

    if (oldImage != null &&
        oldImage
            .toString()
            .isNotEmpty) {
      if (oldImage
          .toString()
          .startsWith(
              "assets/")) {
        return Image.asset(
          oldImage,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(oldImage),
          fit: BoxFit.cover,
        );
      }
    }

    return const Icon(
      Icons.image,
      size: 50,
      color: Colors.grey,
    );
  }

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
          bgColor,

      appBar: AppBar(
        backgroundColor:
            Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme:
            IconThemeData(
          color: primary,
        ),
        title: Text(
          "تعديل القصة",
          style:
              GoogleFonts.cairo(
            color: primary,
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
                20),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 220,
                width:
                    double.infinity,
                decoration:
                    BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(
                          24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors
                          .black
                          .withOpacity(
                              .05),
                      blurRadius:
                          18,
                    ),
                  ],
                ),
                clipBehavior:
                    Clip.antiAlias,
                child: buildImage(),
              ),
            ),

            const SizedBox(
                height: 14),

            Text(
              "اضغط على الصورة لتغييرها",
              style:
                  GoogleFonts.cairo(
                color:
                    Colors.grey,
              ),
            ),

            const SizedBox(
                height: 25),

            TextField(
              controller:
                  titleController,
              style:
                  GoogleFonts.cairo(),
              decoration:
                  InputDecoration(
                labelText:
                    "عنوان القصة",
                labelStyle:
                    GoogleFonts.cairo(),
                filled: true,
                fillColor:
                    Colors.white,
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                          18),
                  borderSide:
                      BorderSide.none,
                ),
              ),
            ),

            const SizedBox(
                height: 30),

            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  ElevatedButton(
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      primary,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                            18),
                  ),
                ),
                onPressed:
                    saveStory,
                child: Text(
                  "حفظ التعديلات",
                  style:
                      GoogleFonts.cairo(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight
                            .bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}