import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stem_vault/Data/AI/ai_service.dart';
import 'package:stem_vault/Data/Cloudinary/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class AILectureGeneratorPage extends StatefulWidget {
  final String cid;
  const AILectureGeneratorPage({Key? key, required this.cid}) : super(key: key);

  @override
  State<AILectureGeneratorPage> createState() => _AILectureGeneratorPageState();
}

class _AILectureGeneratorPageState extends State<AILectureGeneratorPage> {
  final TextEditingController _topicController = TextEditingController();
  bool loading = false;
  List<String> outline = [];
  Map<String, dynamic> details = {};
  List<Map<String, dynamic>> quiz = [];
  Map<int, String> saveStatus = {};
  bool isSaving = false;
  int savedCount = 0;

  Future<void> _generate() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) return;
    setState(() {
      loading = true;
      outline = [];
      details = {};
      quiz = [];
    });

    try {
      final res = await AIService.generateLecture(topic);
      setState(() {
        outline = List<String>.from(res['outline'] ?? []);
        details = Map<String, dynamic>.from(res['details'] ?? {});
        quiz = List<Map<String, dynamic>>.from(res['quiz'] ?? []);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  String _formatContentForPdf(String title, dynamic contentData) {
    final buffer = StringBuffer();
    buffer.writeln(title.toUpperCase());
    buffer.writeln('=' * title.length);
    buffer.writeln();

    if (contentData is Map) {
      if (contentData['summary'] != null) {
        buffer.writeln('SUMMARY:');
        buffer.writeln(contentData['summary']);
        buffer.writeln();
      }
      if (contentData['bullets'] != null && contentData['bullets'] is List) {
        buffer.writeln('KEY POINTS:');
        for (var b in contentData['bullets']) {
          buffer.writeln('• $b');
        }
        buffer.writeln();
      }
      if (contentData['examples'] != null && contentData['examples'] is List) {
        buffer.writeln('EXAMPLES:');
        for (var e in contentData['examples']) {
          buffer.writeln('- $e');
        }
        buffer.writeln();
      }
      if (contentData['code'] != null &&
          contentData['code'].toString().isNotEmpty) {
        buffer.writeln('CODE / SNIPPET:');
        buffer.writeln(contentData['code']);
        buffer.writeln();
      }
    } else {
      buffer.writeln(contentData.toString());
    }
    return buffer.toString();
  }

  Future<File> _createPdf(String title, dynamic contentData) async {
    final dir = await getTemporaryDirectory();
    final safeTitle = title.replaceAll(RegExp(r"[^a-zA-Z0-9_]"), '_');
    final file = File('${dir.path}/$safeTitle.txt');

    final formattedContent = _formatContentForPdf(title, contentData);

    final generated =
        StringBuffer()
          ..writeln(formattedContent)
          ..writeln('Generated: ${DateFormat.yMMMd().format(DateTime.now())}');
    await file.writeAsString(generated.toString());
    return file;
  }

  Future<void> _saveToFirestore() async {
    if (outline.isEmpty) return;

    final choice = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Save Generated Resources'),
            content: const Text('Save all content as PDF resources?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, 'all'),
                child: const Text('Save All'),
              ),
            ],
          ),
    );

    if (choice == null || choice == 'cancel') return;

    saveStatus = {for (int i = 0; i < outline.length; i++) i: 'pending'};
    setState(() {
      isSaving = true;
      savedCount = 0;
    });

    try {
      for (int i = 0; i < outline.length; i++) {
        await _saveLectureAtIndex(i);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Save completed')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _saveLectureAtIndex(int i) async {
    setState(() => saveStatus[i] = 'saving');
    final title = outline[i];
    final contentData = details['$i'];

    try {
      final pdfFile = await _createPdf(title, contentData);
      String pdfUrl = '';

      try {
        pdfUrl = await CloudinaryService.uploadFile(
          pdfFile,
          resourceType: 'raw',
        );
      } catch (_) {}

      final newDocRef =
          FirebaseFirestore.instance.collection('course_resources').doc();
      final newId = newDocRef.id;

      await newDocRef.set({
        'cid': widget.cid,
        'rid': newId,
        'title': title,
        'description': 'AI Generated Resource',
        'url': pdfUrl,
        'type': 'pdf',
        'createdAt': Timestamp.now(),
      });

      // Update course to include this resource ID if needed, or just query by cid
      // For now, we will query by cid in the UI, but let's add to array just in case
      final courseQuery =
          await FirebaseFirestore.instance
              .collection('courses')
              .where('cid', isEqualTo: widget.cid)
              .get();

      for (var cdoc in courseQuery.docs) {
        await cdoc.reference.update({
          'resources': FieldValue.arrayUnion([newId]),
        });
      }

      setState(() {
        saveStatus[i] = 'saved';
        savedCount++;
      });
    } catch (e) {
      setState(() => saveStatus[i] = 'failed');
      print("Error saving resource: $e");
    }
  }

  Future<void> _generateQuizOnly() async {
    if (_topicController.text.trim().isEmpty) return;
    setState(() => loading = true);

    try {
      final q = await AIService.generateQuiz(_topicController.text.trim(), 5);
      setState(() => quiz = q);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Quiz failed: $e')));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget _buildContentDisplay(dynamic contentData) {
    if (contentData == null) return const Text("No details generated.");

    if (contentData is String) return Text(contentData);

    if (contentData is Map) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contentData['summary'] != null) ...[
            Text(
              "Summary",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            Text(contentData['summary'].toString()),
            SizedBox(height: 8),
          ],
          if (contentData['bullets'] != null &&
              contentData['bullets'] is List) ...[
            Text(
              "Key Points",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            ...((contentData['bullets'] as List).map(
              (b) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(b.toString())),
                  ],
                ),
              ),
            )),
            SizedBox(height: 8),
          ],
          if (contentData['examples'] != null &&
              contentData['examples'] is List) ...[
            Text(
              "Examples",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            ...((contentData['examples'] as List).map(
              (e) => Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Text("- $e"),
              ),
            )),
            SizedBox(height: 8),
          ],
          if (contentData['code'] != null &&
              contentData['code'].toString().isNotEmpty) ...[
            Text(
              "Code / Snippet",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                contentData['code'].toString(),
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      );
    }
    return Text(contentData.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Lecture Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: "Topic",
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () => _topicController.clear(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : _generate,
                    child:
                        loading
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text("Generate Outline & Content"),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: loading ? null : _generateQuizOnly,
                  child: const Text("Quiz"),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (outline.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: outline.length,
                itemBuilder: (context, index) {
                  final title = outline[index];
                  final contentData = details['$index'];
                  final status = saveStatus[index] ?? 'pending';

                  Color statusColor =
                      {
                        "pending": Colors.grey,
                        "saving": Colors.orange,
                        "saved": Colors.green,
                        "failed": Colors.red,
                        "skipped": Colors.blueGrey,
                      }[status]!;

                  return Card(
                    child: ExpansionTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(title)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContentDisplay(contentData),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _saveLectureAtIndex(index),
                                    child: const Text("Save as Resource"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            if (isSaving) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value:
                    outline.isNotEmpty ? (savedCount / outline.length) : null,
              ),
              const SizedBox(height: 8),
              Text("Saving $savedCount / ${outline.length}"),
            ],

            if (quiz.isNotEmpty) ...[
              const Divider(),
              const Text(
                "Generated Quiz",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quiz.length,
                itemBuilder: (context, i) {
                  final q = quiz[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            q["question"] ?? "",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          ...((q["options"] ?? []) as List).map(
                            (o) => Text("- $o"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  outline.isNotEmpty && !loading ? _saveToFirestore : null,
              child: const Text("Approve & Save All to Course Resources"),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
