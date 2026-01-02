import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Core/apptext.dart';
import '../../Core/appColors.dart';

class SubmissionsPage extends StatefulWidget {
  final String assignmentId;
  final String? assignmentTitle;

  const SubmissionsPage({super.key, required this.assignmentId, this.assignmentTitle});

  @override
  State<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends State<SubmissionsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('assignment').doc(widget.assignmentId).get();
      if (!doc.exists) {
        setState(() {
          submissions = [];
          isLoading = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final raw = data['submissions'] as List<dynamic>? ?? [];

      List<Map<String, dynamic>> items = [];
      for (var item in raw) {
        try {
          final map = Map<String, dynamic>.from(item as Map);
          items.add(map);
        } catch (_) {}
      }

      // enrich with student username where available
      for (var s in items) {
        final sid = s['studentId'] as String?;
        if (sid != null) {
          try {
            final studentDoc = await FirebaseFirestore.instance.collection('students').doc(sid).get();
            if (studentDoc.exists && studentDoc.data() != null) {
              s['studentName'] = (studentDoc.data() as Map<String, dynamic>)['userName'] ?? sid;
            } else {
              s['studentName'] = sid;
            }
          } catch (_) {
            s['studentName'] = sid;
          }
        }
      }

      // load any existing grades map for quick access
      final gradesMap = (data['grades'] as Map<String, dynamic>?) ?? {};
      final feedbacksMap = (data['feedbacks'] as Map<String, dynamic>?) ?? {};

      for (var s in items) {
        final sid = s['studentId'] as String?;
        if (sid != null) {
          s['grade'] = gradesMap[sid];
          s['feedback'] = feedbacksMap[sid];
        }
      }

      setState(() {
        submissions = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        submissions = [];
        isLoading = false;
      });
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showGradeDialog(Map<String, dynamic> submission) async {
    final studentId = submission['studentId'] as String?;
    if (studentId == null) return;

    final TextEditingController gradeController = TextEditingController(text: submission['grade']?.toString() ?? '');
    final TextEditingController feedbackController = TextEditingController(text: submission['feedback']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Grade ${submission['studentName'] ?? studentId}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: gradeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Grade'),
            ),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(labelText: 'Feedback (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final grade = gradeController.text.trim();
              final feedback = feedbackController.text.trim();
              Navigator.pop(context);
              await _saveGrade(studentId, grade.isEmpty ? null : grade, feedback.isEmpty ? null : feedback);
              await _loadSubmissions();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveGrade(String studentId, String? grade, String? feedback) async {
    try {
      final updateData = <String, dynamic>{};
      if (grade != null) updateData['grades.$studentId'] = grade;
      if (feedback != null) updateData['feedbacks.$studentId'] = feedback;

      await FirebaseFirestore.instance.collection('assignment').doc(widget.assignmentId).set(updateData, SetOptions(merge: true));
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.assignmentTitle ?? 'Submissions')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : submissions.isEmpty
              ? const Center(child: Text('No submissions yet.'))
              : ListView.builder(
                  itemCount: submissions.length,
                  itemBuilder: (context, index) {
                    final s = submissions[index];
                    final studentName = s['studentName'] ?? s['studentId'] ?? 'Unknown';
                    final url = s['url'] ?? '';
                    final submittedOn = s['submittedOn'] != null
                        ? (s['submittedOn'] is Timestamp ? (s['submittedOn'] as Timestamp).toDate() : DateTime.tryParse(s['submittedOn'].toString()))
                        : null;

                    final existingGrade = s['grade'];
                    final existingFeedback = s['feedback'];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: ListTile(
                        title: Text(studentName, style: AppText.mainHeadingTextStyle()),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(submittedOn != null ? DateFormat.yMMMd().add_jm().format(submittedOn) : 'No timestamp'),
                            if (existingGrade != null) Text('Grade: $existingGrade'),
                            if (existingFeedback != null) Text('Feedback: $existingFeedback'),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: url.isNotEmpty ? () => _openUrl(url) : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.rate_review),
                              onPressed: () => _showGradeDialog(s),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
