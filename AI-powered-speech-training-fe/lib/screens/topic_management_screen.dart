import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/topic.dart';
import '../theme/app_theme.dart';

class TopicManagementScreen extends StatefulWidget {
  const TopicManagementScreen({super.key});

  @override
  State<TopicManagementScreen> createState() => _TopicManagementScreenState();
}

class _TopicManagementScreenState extends State<TopicManagementScreen> {
  // Mock data
  final List<Topic> _topics = [
    Topic(
      id: '1',
      title: 'Travel and Tourism',
      prompt: 'Discuss your travel experiences and favorite destinations',
      level: TopicLevel.intermediate,
      tags: ['IELTS', 'Daily'],
      questions: [
        'What is your favorite place to visit?',
        'How do you usually plan your trips?',
        'What makes a destination worth visiting?',
      ],
      duration: '5-7 phút',
      createdAt: '2026-01-15',
    ),
    Topic(
      id: '2',
      title: 'Job Interview Preparation',
      prompt: 'Practice common job interview questions and scenarios',
      level: TopicLevel.advanced,
      tags: ['Interview', 'Professional'],
      questions: [
        'Tell me about yourself',
        'What are your strengths and weaknesses?',
        'Where do you see yourself in 5 years?',
      ],
      duration: '3-5 phút',
      createdAt: '2026-01-14',
    ),
  ];

  void _showTopicDialog({Topic? topic}) {
    showDialog(
      context: context,
      builder: (context) => _TopicDialog(
        topic: topic,
        onSave: (newTopic) {
          setState(() {
            if (topic != null) {
              final index = _topics.indexWhere((t) => t.id == topic.id);
              if (index != -1) {
                _topics[index] = newTopic;
              }
            } else {
              _topics.add(newTopic);
            }
          });
        },
      ),
    );
  }

  void _deleteTopic(Topic topic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Topic'),
        content: Text('Bạn có chắc muốn xóa topic "${topic.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _topics.removeWhere((t) => t.id == topic.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa topic')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
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
                    'Quản lý Topics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tạo và quản lý các chủ đề luyện nói',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showTopicDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo Topic mới'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
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
                          'Quản lý Topics',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray900,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tạo và quản lý các chủ đề luyện nói',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showTopicDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Topic mới'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 24),

        // Topics List
        Expanded(
          child: ListView.separated(
            itemCount: _topics.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final topic = _topics[index];
              return _TopicManagementCard(
                topic: topic,
                onEdit: () => _showTopicDialog(topic: topic),
                onDelete: () => _deleteTopic(topic),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopicManagementCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TopicManagementCard({
    required this.topic,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _levelColor {
    switch (topic.level) {
      case TopicLevel.beginner:
        return AppColors.beginnerColor;
      case TopicLevel.intermediate:
        return AppColors.intermediateColor;
      case TopicLevel.advanced:
        return AppColors.advancedColor;
    }
  }

  Color get _levelBgColor {
    switch (topic.level) {
      case TopicLevel.beginner:
        return AppColors.beginnerBg;
      case TopicLevel.intermediate:
        return AppColors.intermediateBg;
      case TopicLevel.advanced:
        return AppColors.advancedBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final date = DateTime.parse(topic.createdAt);
    final dateStr = DateFormat('dd-MM-yyyy').format(date);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                            topic.title,
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _levelBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              topic.level.displayName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _levelColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topic.prompt,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.gray600,
                        ),
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

            // Tags
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: topic.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tag,
                              size: 14,
                              color: AppColors.gray600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Questions
            const Text(
              'Câu hỏi gợi ý:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray900,
              ),
            ),
            const SizedBox(height: 8),
            ...topic.questions.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.key + 1}.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.gray600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.gray600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tạo ngày: $dateStr',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray500,
                  ),
                ),
                if (isMobile)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: onDelete,
                        color: AppColors.error,
                        tooltip: 'Xóa',
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

class _TopicDialog extends StatefulWidget {
  final Topic? topic;
  final Function(Topic) onSave;

  const _TopicDialog({
    this.topic,
    required this.onSave,
  });

  @override
  State<_TopicDialog> createState() => _TopicDialogState();
}

class _TopicDialogState extends State<_TopicDialog> {
  late TextEditingController _titleController;
  late TextEditingController _promptController;
  late TopicLevel _selectedLevel;
  late List<String> _tags;
  late List<String> _questions;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic?.title ?? '');
    _promptController = TextEditingController(text: widget.topic?.prompt ?? '');
    _selectedLevel = widget.topic?.level ?? TopicLevel.beginner;
    _tags = widget.topic?.tags.toList() ?? [];
    _questions = widget.topic?.questions.toList() ?? ['', '', ''];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.topic == null ? 'Tạo Topic mới' : 'Chỉnh sửa Topic'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề *',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả *',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TopicLevel>(
                initialValue: _selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'Level *',
                ),
                items: TopicLevel.values
                    .map((level) => DropdownMenuItem(
                          value: level,
                          child: Text(level.displayName),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedLevel = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Tags (phân cách bằng dấu phẩy)',
                style: TextStyle(fontSize: 12, color: AppColors.gray600),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'IELTS, Daily, Professional...',
                ),
                onChanged: (value) {
                  _tags = value
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();
                },
                controller: TextEditingController(text: _tags.join(', ')),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty ||
                _promptController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
              );
              return;
            }

            final newTopic = Topic(
              id: widget.topic?.id ?? DateTime.now().toString(),
              title: _titleController.text,
              prompt: _promptController.text,
              level: _selectedLevel,
              tags: _tags,
              questions: _questions.where((q) => q.isNotEmpty).toList(),
              duration: '5-7 phút',
              createdAt:
                  widget.topic?.createdAt ?? DateTime.now().toIso8601String(),
            );

            widget.onSave(newTopic);
            Navigator.pop(context);
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _promptController.dispose();
    super.dispose();
  }
}
