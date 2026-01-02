import 'package:flutter/material.dart';
import 'package:stem_vault/Core/appColors.dart';
import 'package:stem_vault/Core/apptext.dart';

class MyQuizzesScreen extends StatelessWidget {
  const MyQuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> quizzes = [
      {
        "title": "Hashing",
        "subject": "Hashing",
        "date": "2025-12-27",
        "questions": "1 QUestion",
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Created Quizzes", style: AppText.mainHeadingTextStyle()),
        centerTitle: true,
      ),
      body:
          quizzes.isEmpty
              ? Center(
                child: Text(
                  "No quizzes created yet.",
                  style: AppText.mainSubHeadingTextStyle(),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: quizzes.length,
                itemBuilder: (context, index) {
                  final quiz = quizzes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.bgColor,
                        child: const Icon(Icons.quiz, color: Colors.white),
                      ),
                      title: Text(
                        quiz["title"]!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Subject: ${quiz["subject"]}"),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  quiz["date"]!,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  quiz["questions"]!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        // Placeholder for quiz details or editing
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Selected: ${quiz['title']}")),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
