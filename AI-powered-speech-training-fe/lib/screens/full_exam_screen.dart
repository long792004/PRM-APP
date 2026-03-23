import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import 'ielts_listening_screen.dart';
import 'ielts_reading_screen.dart';
import 'ielts_writing_screen.dart';
import 'ielts_speaking_screen.dart';
import 'exam_result_screen.dart';
import '../services/api_service.dart';

class FullExamScreen extends StatefulWidget {
  final IeltsExam exam;

  const FullExamScreen({super.key, required this.exam});

  @override
  State<FullExamScreen> createState() => _FullExamScreenState();
}

class _FullExamScreenState extends State<FullExamScreen> {
  int _currentSectionIndex = 0;
  final Map<String, dynamic> _allResults = {};
  bool _isCompleted = false;

  List<ExamSection> get _sections => widget.exam.sections;

  void _startNextSection() async {
    if (_currentSectionIndex >= _sections.length) {
      setState(() => _isCompleted = true);
      return;
    }

    final section = _sections[_currentSectionIndex];
    dynamic result;

    if (section.skill == 'LISTENING') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IeltsListeningScreen(
            examId: widget.exam.id,
            title: widget.exam.title,
            audioUrl: ApiService.getFullAudioUrl(section.content['audioUrl']),
            questions: section.questions.map((q) => q.toJson()).toList(),
            isPartOfFullExam: true,
          ),
        ),
      );
    } else if (section.skill == 'READING') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IeltsReadingScreen(
            examId: widget.exam.id,
            title: widget.exam.title,
            passage: section.content['readingPassage'] ?? '',
            questions: section.questions.map((q) => q.toJson()).toList(),
            isPartOfFullExam: true,
          ),
        ),
      );
    } else if (section.skill == 'WRITING') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IeltsWritingScreen(
            questionId: section.questions.isNotEmpty ? section.questions.first.id : widget.exam.id,
            prompt: section.questions.isNotEmpty ? section.questions.first.questionText : 'Writing Prompt',
            isPartOfFullExam: true,
          ),
        ),
      );
    } else if (section.skill == 'SPEAKING') {
      result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IeltsSpeakingScreen(
            questionId: section.questions.isNotEmpty ? section.questions.first.id : widget.exam.id,
            prompt: section.questions.isNotEmpty ? section.questions.first.questionText : 'Speaking Prompt',
            isPartOfFullExam: true,
          ),
        ),
      );
    }

    if (result != null) {
      _allResults[section.skill] = result;
      setState(() {
        _currentSectionIndex++;
      });
      _startNextSection();
    }
  }

  double _calculateOverallBand() {
    if (_allResults.isEmpty) return 0;
    double sum = 0;
    _allResults.forEach((key, value) {
      final feedback = value['feedback'];
      if (feedback != null && feedback['overall'] != null) {
        sum += (feedback['overall'] as num).toDouble();
      }
    });
    return (sum / _allResults.length * 2).roundToDouble() / 2; // Làm tròn tới 0.5
  }

  @override
  Widget build(BuildContext context) {
    if (_isCompleted) {
      return ExamResultScreen(
        resultData: {
          'topicTitle': '${widget.exam.title} (Full Mock Test)',
          'transcript': 'Bạn đã hoàn thành bài thi 4 kỹ năng.',
          'feedback': {
            'overall': _calculateOverallBand(),
            'fullExamResults': _allResults,
          }
        },
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 24),
                  Text(
                    widget.exam.title,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn đang bắt đầu bài thi Mock Test đầy đủ. Vui lòng hoàn thành tất cả các phần thi để nhận điểm tổng kết.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  LinearProgressIndicator(
                    value: _currentSectionIndex / _sections.length,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Phần ${_currentSectionIndex + 1} / ${_sections.length}: ${_sections[_currentSectionIndex].skill}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _startNextSection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('BẮT ĐẦU NGAY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
