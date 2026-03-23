import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'exam_result_screen.dart';

class IeltsReadingScreen extends StatefulWidget {
  final String examId;
  final String title;
  final String passage;
  final List<dynamic> questions; // Danh sách câu hỏi từ API
  final bool isPartOfFullExam;

  const IeltsReadingScreen({
    super.key,
    required this.examId,
    required this.title,
    required this.passage,
    required this.questions,
    this.isPartOfFullExam = false,
  });

  @override
  State<IeltsReadingScreen> createState() => _IeltsReadingScreenState();
}

class _IeltsReadingScreenState extends State<IeltsReadingScreen> {
  // Map lưu trữ đáp án của user. Key = questionId, Value = userAnswer (string)
  final Map<String, String> _userAnswers = {};
  bool _isSubmitting = false;

  Future<void> _submitAnswers() async {
    // Collect all answers
    final List<Map<String, String>> answersPayload = [];
    for (var q in widget.questions) {
      final qId = q['id'].toString();
      final answer = _userAnswers[qId] ?? '';
      answersPayload.add({
        'questionId': qId,
        'userAnswer': answer,
      });
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ApiService.submitObjective(widget.examId, answersPayload);
      if (mounted) {
        if (widget.isPartOfFullExam) {
          Navigator.pop(context, result);
        } else {
          // Thay vì pop, ta điều hướng sang màn hình kết quả chi tiết
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ExamResultScreen(resultData: result),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: AppColors.gray900, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.gray900),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Color(0xFFFFFFFF)],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: _buildPassageView(),
        ),
        const SizedBox(height: 16),
        Expanded(
          flex: 1,
          child: _buildQuestionsView(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildPassageView(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildQuestionsView(),
        ),
      ],
    );
  }

  Widget _buildPassageView() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.primaryBg.withOpacity(0.5),
                border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'READING PASSAGE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  widget.passage,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.8,
                    color: AppColors.gray800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsView() {
    return Container(
      color: Colors.transparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.quiz_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 16),
                Text(
                  'Questions (1 - ${widget.questions.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gray900,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.questions.length + 1, // +1 for submit button
              itemBuilder: (context, index) {
                if (index == widget.questions.length) {
                  return _buildSubmitButton();
                }
                final question = widget.questions[index];
                return _buildQuestionItem(question, index + 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(dynamic question, int questionNumber) {
    final qId = question['id'].toString();
    final qText = question['questionText'] ?? '';
    final qType = question['questionType'] ?? 'MULTIPLE_CHOICE'; // FILL_BLANK, MULTIPLE_CHOICE
    final content = question['content']; // options for MC

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
        border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$questionNumber',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      qText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.gray900,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (qType == 'FILL_BLANK')
              TextField(
                onChanged: (val) {
                  setState(() => _userAnswers[qId] = val);
                },
                decoration: InputDecoration(
                  hintText: 'Nhập câu trả lời của bạn',
                  filled: true,
                  fillColor: AppColors.gray50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.gray300),
                  ),
                ),
              )
            else if (qType == 'MULTIPLE_CHOICE' && content != null && content['options'] != null)
              ...List.generate(
                (content['options'] as List).length,
                (i) {
                  final option = content['options'][i].toString();
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _userAnswers[qId],
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _userAnswers[qId] = val);
                      }
                    },
                  );
                },
              )
            else
              // Fallback for simple testing if MC options aren't fully structured yet
              TextField(
                onChanged: (val) {
                  setState(() => _userAnswers[qId] = val);
                },
                decoration: const InputDecoration(hintText: 'A, B, C, or D'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _submitAnswers,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: _isSubmitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
              : const Icon(Icons.check_circle_rounded, color: AppColors.white),
          label: Text(
            _isSubmitting ? 'Đang nộp bài...' : 'Hoàn thành bài thi',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }
}
