import 'dart:io';
import 'package:flutter/material.dart';

class StoryDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> story;

  const StoryDetailsScreen({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    const Color darkBrown = Color(0xFF4C423A);
    const Color bgGradientStart = Color.fromARGB(255, 222, 181, 21);

    final imagePath = (story['CoverImage'] ?? '').toString().trim();
    final hasImage = imagePath.isNotEmpty;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBrown),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGradientStart, Colors.white, Colors.white],
            stops: [0.0, 0.4, 1.0],
          ),
        ),

        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            top: 100,
            bottom: 40,
            left: 25,
            right: 25,
          ),

          child: Column(
            children: [
              // ================= COVER IMAGE =================
              Center(
                child: Container(
                  height: 320,
                  width: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      )
                    ],
                    color: Colors.grey.shade200,
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: hasImage
                        ? (imagePath.startsWith('assets/')
                            ? Image.asset(
                                imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.image,
                                    size: 60,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : Image.file(
                                File(imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: Colors.grey,
                                  );
                                },
                              ))
                        : const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ================= TITLE =================
              Text(
                story['Title'] ?? 'عنوان القصة',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: darkBrown,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 40),

              // ================= CONTENT =================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                    )
                  ],
                  border: Border.all(color: Colors.grey.withOpacity(0.05)),
                ),

                child: Text(
                  story['Content'] ?? '',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: darkBrown.withOpacity(0.85),
                    fontSize: 19,
                    height: 1.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}