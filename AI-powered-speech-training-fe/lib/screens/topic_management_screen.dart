import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'exam_editor_screen.dart';

class TopicManagementScreen extends StatefulWidget {
  const TopicManagementScreen({super.key});

  @override
  State<TopicManagementScreen> createState() => _TopicManagementScreenState();
}

class _TopicManagementScreenState extends State<TopicManagementScreen> {
  late Future<List<IeltsExam>> _examsFuture;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  void _loadExams() {
    _examsFuture = ApiService.getExams().then((data) =>
        data.map((json) => IeltsExam.fromJson(json as Map<String, dynamic>)).toList());
  }

  void _navigateToEditor([IeltsExam? exam]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamEditorScreen(exam: exam),
      ),
    );
    if (result == true) {
      setState(() => _loadExams());
    }
  }

  void _deleteExam(IeltsExam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Bài Thi'),
        content: Text('Bạn có chắc muốn xóa bài thi "${exam.title}"? Thao tác này sẽ xóa toàn bộ số câu hỏi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.deleteExam(exam.id);
                setState(() => _loadExams());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Đã xóa bài thi'), backgroundColor: AppColors.success),
                  );
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
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quản lý Đề Thi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tạo và quản lý các Đề thi IELTS 4 kỹ năng',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
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
                      onPressed: () => _navigateToEditor(),
                      icon: const Icon(Icons.add, color: AppColors.white),
                      label: const Text('Tạo Đề Mới', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý Đề Thi',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tạo và quản lý các Đề thi IELTS 4 kỹ năng',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
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
                      onPressed: () => _navigateToEditor(),
                      icon: const Icon(Icons.add, color: AppColors.white),
                      label: const Text('Tạo Đề Mới', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 24),

        // Exams List
        Expanded(
          child: FutureBuilder<List<IeltsExam>>(
            future: _examsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _loadExams()),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              final exams = snapshot.data ?? [];
              if (exams.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.book_outlined, size: 64, color: AppColors.gray300),
                      const SizedBox(height: 16),
                      const Text('Chưa có đề thi nào. Hãy tạo đề thi đầu tiên!',
                          style: TextStyle(fontSize: 16, color: AppColors.gray500)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo Đề Mới'),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(() => _loadExams()),
                child: ListView.separated(
                  itemCount: exams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return _ExamManagementCard(
                      exam: exam,
                      onEdit: () => _navigateToEditor(exam),
                      onDelete: () => _deleteExam(exam),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ExamManagementCard extends StatelessWidget {
  final IeltsExam exam;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExamManagementCard({
    required this.exam,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // Safety check cho ngày tạo
    String dateStr = '';
    if (exam.createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(exam.createdAt);
        dateStr = DateFormat('dd-MM-yyyy').format(date);
      } catch (_) {}
    }

    return Container(
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
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Text(
                            exam.title,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.advancedBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              exam.type,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.advancedColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bao gồm ${exam.sections.length} phần thi kỹ năng',
                        style: const TextStyle(fontSize: 14, color: AppColors.gray600),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                    color: AppColors.error,
                    tooltip: 'Xóa',
                  ),
                ]
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: exam.sections
                  .map((sec) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: AppColors.success),
                            const SizedBox(width: 4),
                            Text(
                              '${sec.skill} (${sec.questions.length} câu hỏi)',
                              style: const TextStyle(fontSize: 12, color: AppColors.gray700),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tạo ngày: $dateStr', style: const TextStyle(fontSize: 12, color: AppColors.gray500)),
                if (isMobile)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        color: AppColors.error,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
