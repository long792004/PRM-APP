import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class IeltsReadingScreen extends StatefulWidget {
  final String examId;
  final String title;
  final String passage;
  final List<dynamic> questions; // Danh sách câu hỏi từ API

  const IeltsReadingScreen({
    super.key,
    required this.examId,
    required this.title,
    required this.passage,
    required this.questions,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nộp bài thành công! Bạn đúng ${result['correctCount']}/${result['totalQuestions']} câu (Band: ${result['bandScore']}).'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, result);
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
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: AppColors.gray900)),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.gray900),
        elevation: 1,
      ),
      backgroundColor: AppColors.gray50,
      body: SafeArea(
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  // Trên Mobile, dùng Column hoặc CustomScrollView (dọc)
  // Ở đây chia tỷ lệ màn hình trên dưới bằng Expanded
  Widget _buildMobileLayout() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: _buildPassageView(),
        ),
        const Divider(height: 1, thickness: 2, color: AppColors.gray300),
        Expanded(
          flex: 1,
          child: _buildQuestionsView(),
        ),
      ],
    );
  }

  // Trên Desktop (màn to) nên chia đôi màn hình ngang
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildPassageView(),
        ),
        const VerticalDivider(width: 1, thickness: 2, color: AppColors.gray300),
        Expanded(
          flex: 1,
          child: _buildQuestionsView(),
        ),
      ],
    );
  }

  Widget _buildPassageView() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'READING PASSAGE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.passage,
              style: const TextStyle(
                fontSize: 16,
                height: 1.8,
                color: AppColors.gray900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsView() {
    return Container(
      color: AppColors.gray50,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(bottom: BorderSide(color: AppColors.gray200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Questions (1 - ${widget.questions.length})',
                  style: const TextStyle(
                    fontSize: 16,
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
              itemCount: widget.questions.length + 1, // +1 cho Button Nộp bài ở cuối
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.gray200),
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
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitAnswers,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: _isSubmitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
            : const Icon(Icons.check_circle_outline, color: AppColors.white),
        label: Text(
          _isSubmitting ? 'Đang nộp bài...' : 'Hoàn thành bài thi',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
