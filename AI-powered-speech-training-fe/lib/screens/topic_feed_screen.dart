import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class TopicFeedScreen extends StatefulWidget {
  final Function(IeltsExam) onSelectTopic;

  const TopicFeedScreen({
    super.key,
    required this.onSelectTopic,
  });

  @override
  State<TopicFeedScreen> createState() => _TopicFeedScreenState();
}

class _TopicFeedScreenState extends State<TopicFeedScreen> {
  final TextEditingController _searchController = TextEditingController();
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

  List<IeltsExam> _filterExams(List<IeltsExam> exams) {
    return exams.where((exam) {
      if (_searchController.text.isNotEmpty) {
        return exam.title
            .toLowerCase()
            .contains(_searchController.text.toLowerCase());
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text(
          'Chọn Đề Thi Luyện Tập',
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: AppColors.gray900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chọn một bộ đề thi mô phỏng để bắt đầu đánh giá kỹ năng của bạn',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 24),

        // Search
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm đề thi...',
            prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.gray400),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 24),

        // Exams Grid
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
                      Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() => _loadExams()),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                );
              }
              final filtered = _filterExams(snapshot.data ?? []);
              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'Không tìm thấy đề thi nào',
                    style: TextStyle(fontSize: 16, color: AppColors.gray500),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => setState(() => _loadExams()),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: isMobile ? 0.8 : 1.2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final exam = filtered[index];
                    return _ExamCard(
                      exam: exam,
                      onTap: () => widget.onSelectTopic(exam),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _ExamCard extends StatelessWidget {
  final IeltsExam exam;
  final VoidCallback onTap;

  const _ExamCard({
    required this.exam,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sections = exam.sections;
    final totalQuestions = sections.fold<int>(0, (sum, sec) => sum + sec.questions.length);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Type
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      exam.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      exam.type,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                'Bộ đề thi gồm ${sections.length} bài thi thành phần.\nVui lòng nhấn Bắt đầu để vào thi.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: sections.map((sec) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 12, color: AppColors.gray600),
                      const SizedBox(width: 4),
                      Text(
                        sec.skill,
                        style: const TextStyle(fontSize: 11, color: AppColors.gray600),
                      ),
                    ],
                  ),
                )).toList(),
              ),
              
              const Spacer(),
              const Divider(),
              const SizedBox(height: 8),

              // Footer
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.gray500),
                      const SizedBox(width: 4),
                      Text(
                        '$totalQuestions câu hỏi',
                        style: const TextStyle(fontSize: 12, color: AppColors.gray600),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Bắt đầu làm bài', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
