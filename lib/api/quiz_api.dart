import 'dart:convert';
import 'package:http/http.dart' as http;

class QuizLevelDto {
  final int id;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isLocked;

  QuizLevelDto({
    required this.id,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.isLocked,
  });

  factory QuizLevelDto.fromJson(Map<String, dynamic> json) => QuizLevelDto(
        id: (json["id"] as num).toInt(),
        name: (json["name"] ?? "").toString(),
        description: json["description"]?.toString(),
        sortOrder: (json["sort_order"] as num).toInt(),
        isLocked: json["is_locked"] == true,
      );
}

class StartQuizResponseDto {
  final int attemptId;
  final int totalQuestions;

  StartQuizResponseDto({required this.attemptId, required this.totalQuestions});

  factory StartQuizResponseDto.fromJson(Map<String, dynamic> json) =>
      StartQuizResponseDto(
        attemptId: (json["attempt_id"] as num).toInt(),
        totalQuestions: (json["total_questions"] as num).toInt(),
      );
}

class QuizOptionDto {
  final int id;
  final String? label;
  final String text;

  QuizOptionDto({required this.id, this.label, required this.text});

  factory QuizOptionDto.fromJson(Map<String, dynamic> json) => QuizOptionDto(
        id: (json["id"] as num).toInt(),
        label: json["label"]?.toString(),
        text: (json["text"] ?? "").toString(),
      );
}

class QuizQuestionDto {
  final int attemptId;
  final int? questionId;
  final String? questionText;
  final List<QuizOptionDto> options;
  final int index;
  final int total;
  final bool isFinished;

  QuizQuestionDto({
    required this.attemptId,
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.index,
    required this.total,
    required this.isFinished,
  });

  factory QuizQuestionDto.fromJson(Map<String, dynamic> json) => QuizQuestionDto(
        attemptId: (json["attempt_id"] as num).toInt(),
        questionId: json["question_id"] == null ? null : (json["question_id"] as num).toInt(),
        questionText: json["question_text"]?.toString(),
        options: (json["options"] as List)
            .map((e) => QuizOptionDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        index: (json["index"] as num).toInt(),
        total: (json["total"] as num).toInt(),
        isFinished: json["is_finished"] == true,
      );
}

class AnswerResponseDto {
  final bool isCorrect;
  final int correctCount;
  final int answeredCount;
  final int total;
  final int score;
  final String? explanation;
  final bool isFinished;

  AnswerResponseDto({
    required this.isCorrect,
    required this.correctCount,
    required this.answeredCount,
    required this.total,
    required this.score,
    this.explanation,
    required this.isFinished,
  });

  factory AnswerResponseDto.fromJson(Map<String, dynamic> json) => AnswerResponseDto(
        isCorrect: json["is_correct"] == true,
        correctCount: (json["correct_count"] as num).toInt(),
        answeredCount: (json["answered_count"] as num).toInt(),
        total: (json["total"] as num).toInt(),
        score: (json["score"] as num).toInt(),
        explanation: json["explanation"]?.toString(),
        isFinished: json["is_finished"] == true,
      );
}

class FinishAttemptResponseDto {
  final String status; // completed / abandoned / in_progress (harusnya tidak lagi)
  final int score;
  final int correctCount;
  final int totalQuestions;

  FinishAttemptResponseDto({
    required this.status,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
  });

  factory FinishAttemptResponseDto.fromJson(Map<String, dynamic> json) => FinishAttemptResponseDto(
        status: (json["status"] ?? "").toString(),
        score: (json["score"] as num).toInt(),
        correctCount: (json["correct_count"] as num).toInt(),
        totalQuestions: (json["total_questions"] as num).toInt(),
      );
}

class HistoryItemDto {
  final int attemptId;
  final int levelId;
  final String levelName;
  final String status;
  final int score;
  final int correctCount;
  final int totalQuestions;
  final String startedAt;
  final String? finishedAt;

  HistoryItemDto({
    required this.attemptId,
    required this.levelId,
    required this.levelName,
    required this.status,
    required this.score,
    required this.correctCount,
    required this.totalQuestions,
    required this.startedAt,
    this.finishedAt,
  });

  factory HistoryItemDto.fromJson(Map<String, dynamic> json) => HistoryItemDto(
        attemptId: (json["attempt_id"] as num).toInt(),
        levelId: (json["level_id"] as num).toInt(),
        levelName: (json["level_name"] ?? "").toString(),
        status: (json["status"] ?? "").toString(),
        score: (json["score"] as num).toInt(),
        correctCount: (json["correct_count"] as num).toInt(),
        totalQuestions: (json["total_questions"] as num).toInt(),
        startedAt: (json["started_at"] ?? "").toString(),
        finishedAt: json["finished_at"]?.toString(),
      );
}

class QuizApi {
  static const String baseUrl = "http://10.0.2.2:8000";
  final http.Client _client;
  QuizApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<QuizLevelDto>> levels({required String userKey}) async {
    final uri = Uri.parse("$baseUrl/quiz/levels").replace(queryParameters: {
      "user_key": userKey,
    });

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception("GET /quiz/levels failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data["items"] as List).cast<Map<String, dynamic>>();
    return items.map(QuizLevelDto.fromJson).toList();
  }

  Future<StartQuizResponseDto> start({
    required String userKey,
    required int levelId,
  }) async {
    final uri = Uri.parse("$baseUrl/quiz/start");
    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_key": userKey, "level_id": levelId}),
    );

    if (res.statusCode != 200) {
      throw Exception("POST /quiz/start failed: ${res.statusCode} ${res.body}");
    }

    return StartQuizResponseDto.fromJson(jsonDecode(res.body));
  }

  Future<QuizQuestionDto> nextQuestion({
    required String userKey,
    required int attemptId,
  }) async {
    final uri = Uri.parse("$baseUrl/quiz/$attemptId/question").replace(queryParameters: {
      "user_key": userKey,
    });

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception("GET /quiz/$attemptId/question failed: ${res.statusCode} ${res.body}");
    }

    return QuizQuestionDto.fromJson(jsonDecode(res.body));
  }

  Future<AnswerResponseDto> answer({
    required String userKey,
    required int attemptId,
    required int selectedOptionId,
  }) async {
    final uri = Uri.parse("$baseUrl/quiz/$attemptId/answer");
    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_key": userKey, "selected_option_id": selectedOptionId}),
    );

    if (res.statusCode != 200) {
      throw Exception("POST /quiz/$attemptId/answer failed: ${res.statusCode} ${res.body}");
    }

    return AnswerResponseDto.fromJson(jsonDecode(res.body));
  }

  // ✅ baru: tutup attempt ketika user keluar
  Future<FinishAttemptResponseDto> finishAttempt({
    required String userKey,
    required int attemptId,
  }) async {
    final uri = Uri.parse("$baseUrl/quiz/$attemptId/finish");
    final res = await _client.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_key": userKey}),
    );

    if (res.statusCode != 200) {
      throw Exception("POST /quiz/$attemptId/finish failed: ${res.statusCode} ${res.body}");
    }

    return FinishAttemptResponseDto.fromJson(jsonDecode(res.body));
  }

  Future<List<HistoryItemDto>> history({required String userKey}) async {
    final uri = Uri.parse("$baseUrl/quiz/history").replace(queryParameters: {
      "user_key": userKey,
    });

    final res = await _client.get(uri);
    if (res.statusCode != 200) {
      throw Exception("GET /quiz/history failed: ${res.statusCode} ${res.body}");
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data["items"] as List).cast<Map<String, dynamic>>();
    return items.map(HistoryItemDto.fromJson).toList();
  }
}
