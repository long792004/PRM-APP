class IeltsExam {
  final String id;
  final String title;
  final String type;
  final List<ExamSection> sections;
  final String createdAt;

  IeltsExam({
    required this.id,
    required this.title,
    required this.type,
    required this.sections,
    required this.createdAt,
  });

  factory IeltsExam.fromJson(Map<String, dynamic> json) {
    return IeltsExam(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'MOCK_TEST',
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => ExamSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'sections': sections.map((e) => e.toJson()).toList(),
      'createdAt': createdAt,
    };
  }
}

class ExamSection {
  final String id;
  final String skill; // 'LISTENING', 'READING', 'WRITING', 'SPEAKING'
  final Map<String, dynamic> content;
  final List<ExamQuestion> questions;

  ExamSection({
    required this.id,
    required this.skill,
    required this.content,
    required this.questions,
  });

  factory ExamSection.fromJson(Map<String, dynamic> json) {
    return ExamSection(
      id: json['id'] ?? '',
      skill: json['skill'] ?? '',
      content: json['content'] as Map<String, dynamic>? ?? {},
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill,
      'content': content,
      'questions': questions.map((e) => e.toJson()).toList(),
    };
  }
}

class ExamQuestion {
  final String id;
  final String questionText;
  final String questionType; // 'MULTIPLE_CHOICE', 'FILL_BLANK', 'ESSAY', 'SPEAKING_PROMPT'
  final dynamic correctAnswers; // List<String> or null
  final Map<String, dynamic>? content; // e.g., {'options': ['A', 'B', 'C', 'D']}

  ExamQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    this.correctAnswers,
    this.content,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] ?? '',
      questionText: json['questionText'] ?? '',
      questionType: json['questionType'] ?? '',
      correctAnswers: json['correctAnswers'],
      content: json['content'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionText': questionText,
      'questionType': questionType,
      'correctAnswers': correctAnswers,
      'content': content,
    };
  }
}
