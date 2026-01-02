import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_config.dart';

class AIService {
  /// Toggle to true while debugging to get extra console logs.
  static const bool _debug = true;

  /// Common request timeout
  static const Duration _requestTimeout = Duration(seconds: 25);

  /// Small retry attempts for transient errors
  static const int _maxRetries = 2;

  /// Public: generate lecture (outline, details, quiz) for a topic
  /// Returns a Map with keys: 'outline' (List<String>), 'details' (Map<String,dynamic>),
  /// 'quiz' (List<Map<String,dynamic>>).
  /// This function is defensive and will return a valid Map even on partial failure.
  static Future<Map<String, dynamic>> generateLecture(String topic) async {
    final prompt = '''
You are an expert teacher and curriculum author. Your task is to generate a comprehensive, detailed, and educational lecture based on the following input (which may be a topic or raw content): "$topic".

Produce ONLY valid JSON and nothing else.

The JSON MUST have these keys:

{
  "outline": ["Section title 1", "Section title 2", ...], // at least 5 items
  "details": {
     "0": { 
       "title": "Section title 1", 
       "summary": "A detailed 3-5 sentence paragraph introducing the section.", 
       "bullets": ["detailed bullet point 1", "detailed bullet point 2", "..."], 
       "examples": ["realistic example or code snippet"], 
       "code": "optional code snippet as string (no backticks)" 
     },
     "1": { ... }
  },
  "quiz": [ { "question":"...", "options":["a","b","c","d"], "answerIndex": 1 }, ... ]
}

Requirements:
- **Content Quality**: The content must be FACTUAL, EDUCATIONAL, and DETAILED. Do not use generic placeholders like "Content goes here". Actually teach the subject.
- **Input Handling**: If the input is a topic, generate a lecture on that topic. If the input is raw text, structure it into a lecture.
- **Structure**: 
    - `summary`: A clear, informative paragraph (3-5 sentences) explaining the section concepts in depth.
    - `bullets`: 3-6 detailed teaching points. Each bullet should be a complete thought.
    - `examples`: At least one concrete example or scenario.
    - `code`: If the topic is technical, provide a relevant code snippet.
- **Quiz**: Generate 3-5 challenging multiple-choice questions testing understanding of the generated content.
- **Format**: Return ONLY valid JSON. Ensure all strings are properly escaped. Do not include markdown formatting (like ```json).

If the model cannot fulfill everything, return the best possible JSON with the keys you can produce.
''';

    // Build request body compatible with modern Gemini-style generative endpoints.
    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      // generationConfig may vary by endpoint; using a simple nested config name for compatibility
      "generationConfig": {
        "temperature": 0.2,
        "maxOutputTokens": 4000,
      }, // Increased tokens for detailed content
    };

    // NOTE: API endpoints and model names vary by account and API version.
    // We attempt a v1beta2 call; if the API returns non-200 (404 etc) we fall back to a local generator.
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta2/models/gemini-1.0:generate';
    final url = Uri.parse('$endpoint?key=$GEMINI_API_KEY');

    // attempt call with small retry loop
    http.Response? resp;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (_debug)
          print(
            '[AIService] generateLecture: POST attempt ${attempt + 1} -> $url',
          );
        final futureResp = http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_requestTimeout);
        resp = await futureResp;
        if (resp.statusCode == 200) break; // success
        // for 4xx/5xx allow retry for transient (5xx) or break for client errors (4xx)
        if (resp.statusCode >= 500 && attempt < _maxRetries) {
          if (_debug)
            print('[AIService] server error ${resp.statusCode}, retrying...');
          await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
          continue;
        }
        // non-retriable
        break;
      } on TimeoutException catch (te) {
        if (_debug) print('[AIService] Timeout: $te');
        if (attempt == _maxRetries) rethrow;
      } catch (e) {
        if (_debug) print('[AIService] Network error: $e');
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300));
      }
    }

    if (resp == null) {
      // failed to get any response
      if (_debug) print('[AIService] No response from API');
      return _emptyLectureResult();
    }

    if (resp.statusCode != 200) {
      // Log but avoid printing the key; show endpoint and status
      try {
        print(
          '[AIService] generateLecture: API returned ${resp.statusCode} for endpoint $endpoint',
        );
        print('[AIService] Response body: ${resp.body}');
      } catch (_) {}
      // Fall back to a simple local generator so UI remains usable
      print(
        '[AIService] Attempting local fallback lecture generation for topic: $topic',
      );
      return _localFallbackLecture(topic);
    }

    final bodyStr = resp.body;
    if (_debug) print('[AIService] Raw response: ${_truncate(bodyStr, 500)}');

    // Try to parse JSON from many possible response shapes
    final extractedText = _extractTextFromResponseJson(bodyStr);
    if (_debug)
      print(
        '[AIService] Extracted text (first 500 chars): ${_truncate(extractedText, 500)}',
      );

    // Attempt to parse JSON object from extractedText
    final parsed = _attemptParseJsonObjectFromText(extractedText);
    if (parsed != null) {
      // Ensure keys exist and types normalized
      return _normalizeLectureResult(parsed);
    }

    // If we couldn't parse structured JSON, attempt heuristic parsing (outline from numbered lists).
    return _tryParseLectureFromRaw(extractedText);
  }

  /// Public: generate quiz (array of MCQs)
  static Future<List<Map<String, dynamic>>> generateQuiz(
    String topic,
    int count,
  ) async {
    final prompt =
        'Create $count multiple choice questions for the topic: "$topic". Return valid JSON array with objects {question, options:[..], answerIndex} and nothing else.';
    final body = {
      "contents": [
        {
          "parts": [
            {"text": prompt},
          ],
        },
      ],
      "generationConfig": {"temperature": 0.2, "maxOutputTokens": 800},
    };

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$GEMINI_API_KEY',
    );

    http.Response? resp;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        if (_debug)
          print('[AIService] generateQuiz: POST attempt ${attempt + 1}');
        resp = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_requestTimeout);
        if (resp.statusCode == 200) break;
        if (resp.statusCode >= 500 && attempt < _maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * (attempt + 1)));
          continue;
        }
        break;
      } on TimeoutException catch (te) {
        if (_debug) print('[AIService] Timeout (quiz): $te');
        if (attempt == _maxRetries) rethrow;
      } catch (e) {
        if (_debug) print('[AIService] Network error (quiz): $e');
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 200));
      }
    }

    if (resp == null) return _localFallbackQuiz(topic, count);
    if (resp.statusCode != 200) {
      if (_debug)
        print('[AIService] Quiz API returned ${resp.statusCode}: ${resp.body}');
      return _localFallbackQuiz(topic, count);
    }

    final bodyStr = resp.body;
    if (_debug) print('[AIService] Quiz raw: ${_truncate(bodyStr, 500)}');

    final extractedText = _extractTextFromResponseJson(bodyStr);
    final parsed = _attemptParseJsonStructure(extractedText);
    if (parsed is List) {
      // ensure list of map
      try {
        return List<Map<String, dynamic>>.from(
          parsed.map((e) => Map<String, dynamic>.from(e)),
        );
      } catch (_) {
        // fallback
      }
    }

    // Final attempt: parse JSON directly from text
    final asJson = _attemptParseJsonObjectFromText(extractedText);
    if (asJson != null) {
      // maybe the model returned { "quiz": [...] }
      if (asJson.containsKey('quiz') && asJson['quiz'] is List) {
        try {
          return List<Map<String, dynamic>>.from(
            asJson['quiz'].map((e) => Map<String, dynamic>.from(e)),
          );
        } catch (_) {}
      }
    }

    return _localFallbackQuiz(topic, count);
  }

  // ------------------------- Helper utilities -------------------------

  static Map<String, dynamic> _emptyLectureResult() {
    return {
      'outline': <String>[],
      'details':
          <String, dynamic>{}, // Changed to dynamic to hold structured data
      'quiz': <Map<String, dynamic>>[],
    };
  }

  static String _truncate(String s, int len) {
    if (s.length <= len) return s;
    return s.substring(0, len) + '...';
  }

  /// Normalize parsed object to expected shape (outline List<String>, details Map<String,dynamic>, quiz List<Map>)
  static Map<String, dynamic> _normalizeLectureResult(
    Map<String, dynamic> raw,
  ) {
    final out = <String>[];
    final details =
        <String, dynamic>{}; // Changed to dynamic to hold structured data
    final quizList = <Map<String, dynamic>>[];

    // Outline normalization
    try {
      final rawOutline = raw['outline'];
      if (rawOutline is List) {
        for (var item in rawOutline) {
          if (item == null) continue;
          out.add(item.toString());
        }
      } else if (rawOutline is String) {
        // maybe newline separated
        out.addAll(
          rawOutline
              .split(RegExp(r'\r?\n'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty),
        );
      }
    } catch (_) {}

    // Details normalization - KEY FIX: Preserve structured data
    try {
      final rawDetails = raw['details'];
      if (rawDetails is Map) {
        rawDetails.forEach((k, v) {
          if (v != null && v is Map) {
            // Preserve the structured detail object
            details[k.toString()] = v;
          } else if (v != null) {
            // Fallback: if it's not a Map, store as string
            details[k.toString()] = v.toString();
          }
        });
      }
    } catch (e) {
      if (_debug) print('[AIService] Error normalizing details: $e');
    }

    // Quiz normalization
    try {
      final rawQuiz = raw['quiz'];
      if (rawQuiz is List) {
        for (var q in rawQuiz) {
          if (q is Map) {
            final m = <String, dynamic>{};
            q.forEach((k, v) => m[k.toString()] = v);
            quizList.add(m);
          }
        }
      }
    } catch (_) {}

    return {'outline': out, 'details': details, 'quiz': quizList};
  }

  /// Attempt to extract the textual generated content from common Gemini / other shapes
  static String _extractTextFromResponseJson(String bodyStr) {
    try {
      final parsed = jsonDecode(bodyStr);
      // Try a sequence of known shapes
      // 1) parsed['candidates'][0]['content']['parts'][0]['text']
      if (parsed is Map) {
        try {
          final cand = parsed['candidates'];
          if (cand is List && cand.isNotEmpty) {
            final first = cand[0];
            // modern shape: content.parts[].text
            if (first is Map) {
              final content = first['content'];
              if (content is Map) {
                final parts = content['parts'];
                if (parts is List && parts.isNotEmpty) {
                  final p0 = parts[0];
                  if (p0 is Map && p0['text'] != null) {
                    return p0['text'].toString();
                  } else if (p0 is String) {
                    return p0;
                  }
                }
              }
              // older shapes: first['content'] might be string
              if (first['content'] is String) return first['content'];
              // sometimes the response nests an 'output' or 'message'
              if (first['output'] != null) {
                final out = first['output'];
                if (out is String) return out;
                if (out is Map && out['text'] != null)
                  return out['text'].toString();
              }
            }
          }
        } catch (_) {}
        // 2) parsed['candidates'][0]['output'][0]['content'][0]['text']
        try {
          final cands = parsed['candidates'];
          if (cands is List && cands.isNotEmpty && cands[0] is Map) {
            final o = cands[0]['output'];
            if (o is List && o.isNotEmpty && o[0] is Map) {
              final cont = o[0]['content'];
              if (cont is List &&
                  cont.isNotEmpty &&
                  cont[0] is Map &&
                  cont[0]['text'] != null) {
                return cont[0]['text'].toString();
              }
            }
          }
        } catch (_) {}
        // 3) parsed['output'] or parsed['result'] or parsed['candidates'][0].toString()
        if (parsed['output'] != null) {
          final out = parsed['output'];
          if (out is String) return out;
          if (out is Map && out['text'] != null) return out['text'].toString();
        }
        if (parsed['result'] != null) return parsed['result'].toString();
      }
      // Last resort: return full body
      return bodyStr;
    } catch (e) {
      if (_debug)
        print(
          '[AIService] _extractTextFromResponseJson: jsonDecode failed, returning raw body. Error: $e',
        );
      return bodyStr;
    }
  }

  /// Attempts to parse a JSON structure directly from free text.
  /// If text contains a JSON object (first {...} ...matching}), return parsed Map.
  static Map<String, dynamic>? _attemptParseJsonObjectFromText(String text) {
    // Quick attempt: whole text is JSON
    try {
      final maybe = jsonDecode(text);
      if (maybe is Map<String, dynamic>) return maybe;
      if (maybe is List) return {'quiz': maybe};
    } catch (_) {}

    // Find first {...} JSON block using bracket balancing to allow nested objects.
    final start = text.indexOf('{');
    if (start == -1) return null;

    int braceCount = 0;
    for (int i = start; i < text.length; i++) {
      final ch = text[i];
      if (ch == '{') braceCount++;
      if (ch == '}') braceCount--;
      if (braceCount == 0) {
        final candidate = text.substring(start, i + 1);
        try {
          final parsed = jsonDecode(candidate);
          if (parsed is Map<String, dynamic>) return parsed;
        } catch (e) {
          // try trimming non-JSON characters often present like leading/trailing backticks
          final cleaned = candidate.replaceAll(
            RegExp(r'^[`"\s]+|[`"\s]+\$'),
            '',
          );
          try {
            final parsed2 = jsonDecode(cleaned);
            if (parsed2 is Map<String, dynamic>) return parsed2;
          } catch (_) {}
        }
        break;
      }
    }

    // Try to find array [...], maybe quiz-only responses
    final arrStart = text.indexOf('[');
    if (arrStart != -1) {
      int arrCount = 0;
      for (int i = arrStart; i < text.length; i++) {
        final ch = text[i];
        if (ch == '[') arrCount++;
        if (ch == ']') arrCount--;
        if (arrCount == 0) {
          final candidate = text.substring(arrStart, i + 1);
          try {
            final parsed = jsonDecode(candidate);
            if (parsed is List) return {'quiz': parsed};
          } catch (_) {}
          break;
        }
      }
    }

    return null;
  }

  /// A bit more permissive: returns any decoded JSON (Map or List) or null.
  static dynamic _attemptParseJsonStructure(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {}
    // else try to extract object
    return _attemptParseJsonObjectFromText(text);
  }

  /// If we couldn't parse clean JSON, try a simple heuristic to extract outline & details
  static Map<String, dynamic> _tryParseLectureFromRaw(String rawText) {
    if (_debug) print('[AIService] Attempting heuristic parse from raw text');

    final lines = rawText.split(RegExp(r'\r?\n'));
    final outline = <String>[];
    final details = <String, dynamic>{}; // Changed to dynamic
    int currentIndex = -1;
    final buffer = StringBuffer();

    final listPattern = RegExp(
      r'^(?:\d+\.\s*|\d+\)\s*|[-*+]\s+|#{1,3}\s*)(.+)$',
    );

    for (var line in lines) {
      final trimmed = line.trim();
      final m = listPattern.firstMatch(trimmed);
      if (m != null) {
        // save previous
        if (currentIndex >= 0) {
          details['$currentIndex'] = buffer.toString().trim();
          buffer.clear();
        }
        final title = m.group(1)?.trim() ?? trimmed;
        outline.add(title);
        currentIndex = outline.length - 1;
      } else if (trimmed.isNotEmpty) {
        if (currentIndex == -1) {
          // possible heading line
          if (trimmed.length < 90 && trimmed.split(' ').length <= 10) {
            outline.add(trimmed);
            currentIndex = outline.length - 1;
          }
        } else {
          buffer.writeln(line);
        }
      }
    }

    if (currentIndex >= 0) details['$currentIndex'] = buffer.toString().trim();

    // Ensure at least something exists; if not, return empty but include quiz if present in raw text
    final quizFromText = <Map<String, dynamic>>[];
    // try to find any JSON array representing quiz
    final maybe = _attemptParseJsonObjectFromText(rawText);
    if (maybe != null && maybe.containsKey('quiz') && maybe['quiz'] is List) {
      try {
        for (var q in maybe['quiz']) {
          if (q is Map) quizFromText.add(Map<String, dynamic>.from(q));
        }
      } catch (_) {}
    }

    return {'outline': outline, 'details': details, 'quiz': quizFromText};
  }

  /// Local simple fallback quiz generator
  static List<Map<String, dynamic>> _localFallbackQuiz(
    String topic,
    int count,
  ) {
    final qs = <Map<String, dynamic>>[];
    for (int i = 0; i < count; i++) {
      qs.add({
        'question':
            'Question ${i + 1}: Which statement about "$topic" is correct?',
        'options': [
          'Option A: A key fact about $topic.',
          'Option B: Another fact about $topic.',
          'Option C: A common misconception about $topic.',
          'Option D: An unrelated statement.',
        ],
        'answerIndex': 0,
      });
    }
    return qs;
  }

  // Local simple fallback lecture generator to provide a minimal valid shape with structured details
  static Map<String, dynamic> _localFallbackLecture(String topic) {
    final outline = <String>[
      'Introduction to $topic',
      'Key concepts of $topic',
      'Important examples and applications',
      'Common pitfalls and misconceptions',
      'Summary and next steps',
    ];

    final details = <String, dynamic>{};
    for (var i = 0; i < outline.length; i++) {
      details['$i'] = {
        'title': outline[i],
        'summary':
            'This section provides a comprehensive overview of ${outline[i].toLowerCase()}. It covers the essential concepts and practical applications that will help you understand this topic better.',
        'bullets': [
          'Key point 1 about ${topic.toLowerCase()}',
          'Important concept 2 related to ${topic.toLowerCase()}',
          'Practical application 3 of ${topic.toLowerCase()}',
          'Useful tip 4 for working with ${topic.toLowerCase()}',
        ],
        'examples': ['Example demonstrating ${topic.toLowerCase()} concepts'],
        'code':
            i == 2
                ? '// Sample code for $topic\nfunction example() {\n  return "Hello $topic";\n}'
                : '',
      };
    }

    // include a small quiz using the existing fallback quiz generator
    final quiz = _localFallbackQuiz(topic, 3);

    return {'outline': outline, 'details': details, 'quiz': quiz};
  }
}
