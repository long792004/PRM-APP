import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ExamEditorScreen extends StatefulWidget {
  final IeltsExam? exam;

  const ExamEditorScreen({super.key, this.exam});

  @override
  State<ExamEditorScreen> createState() => _ExamEditorScreenState();
}

class _ExamEditorScreenState extends State<ExamEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late String _examType;
  
  List<Map<String, dynamic>> _sections = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.exam?.title ?? '');
    _examType = widget.exam?.type ?? 'MOCK_TEST';

    if (widget.exam != null) {
      _sections = widget.exam!.sections.map((sec) {
        return {
          'skill': sec.skill,
          'content': Map<String, dynamic>.from(sec.content),
          'questions': sec.questions.map((q) => {
            'questionText': q.questionText,
            'questionType': q.questionType,
            'correctAnswers': q.correctAnswers != null ? (q.correctAnswers as List).join(', ') : '',
            'content': {
              ...q.content ?? {},
              'options': q.content?['options'] ?? ['', '', '', ''],
            },
          }).toList(),
        };
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addSection() {
    setState(() {
      _sections.add({
        'skill': 'READING',
        'content': {'readingPassage': '', 'audioUrl': ''},
        'questions': [],
      });
    });
  }

  void _addQuestion(int sectionIndex) {
    setState(() {
      _sections[sectionIndex]['questions'].add({
        'questionText': '',
        'questionType': 'MULTIPLE_CHOICE',
        'correctAnswers': '',
        'content': {'options': ['', '', '', '']},
      });
    });
  }

  void _saveExam() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Xử lý list format options -> correctAnswers list
    final formattedSections = _sections.map((sec) {
      return {
        'skill': sec['skill'],
        'content': sec['content'],
        'questions': (sec['questions'] as List).map((q) {
          final qType = q['questionType'];
          List<String>? correctAnswers;
          if (qType == 'MULTIPLE_CHOICE' || qType == 'FILL_BLANK') {
            correctAnswers = (q['correctAnswers'] as String)
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }

          Map<String, dynamic>? content;
          if (qType == 'MULTIPLE_CHOICE' && q['content']?['options'] != null) {
            content = {
              'options': (q['content']['options'] as List)
                .map((e) => e.toString().trim())
                .where((e) => e.isNotEmpty)
                .toList()
            };
          }

          return {
            'questionText': q['questionText'],
            'questionType': qType,
            'correctAnswers': correctAnswers,
            'content': content,
          };
        }).toList(),
      };
    }).toList();

    final payload = {
      'title': _titleController.text,
      'type': _examType,
      'sections': formattedSections,
    };

    try {
      if (widget.exam == null) {
        await ApiService.createExam(payload);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã tạo Đề thi mới'), backgroundColor: AppColors.success),
          );
        }
      } else {
        await ApiService.updateExam(widget.exam!.id, payload);
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Đã cập nhật Đề thi'), backgroundColor: AppColors.success),
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam == null ? 'Tạo Đề Thi Mới' : 'Sửa Đề Thi'),
        actions: [
          TextButton.icon(
            onPressed: _saveExam,
            icon: const Icon(Icons.save, color: AppColors.primary),
            label: const Text('Lưu Đề Thi', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Thông tin chung
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Thông Tin Đề Thi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Tên Đề Thi *'),
                      validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên đề thi' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _examType,
                      decoration: const InputDecoration(labelText: 'Loại Đề Thi'),
                      items: const [
                        DropdownMenuItem(value: 'MOCK_TEST', child: Text('Mock Test (Thi thử)')),
                        DropdownMenuItem(value: 'PRACTICE', child: Text('Practice (Luyện tập)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _examType = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Các phần thi (Sections)
             const Text('Phần Thi (Sections)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),
             
             ..._sections.asMap().entries.map((entry) {
                int secIndex = entry.key;
                var sec = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Section ${secIndex + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () {
                                setState(() {
                                  _sections.removeAt(secIndex);
                                });
                              },
                            )
                          ],
                        ),
                        DropdownButtonFormField<String>(
                          value: sec['skill'],
                          decoration: const InputDecoration(labelText: 'Kỹ Năng (Skill)'),
                          items: const [
                            DropdownMenuItem(value: 'READING', child: Text('READING')),
                            DropdownMenuItem(value: 'LISTENING', child: Text('LISTENING')),
                            DropdownMenuItem(value: 'WRITING', child: Text('WRITING')),
                            DropdownMenuItem(value: 'SPEAKING', child: Text('SPEAKING')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => sec['skill'] = val);
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Content phụ thuộc vào Skill
                        if (sec['skill'] == 'READING') 
                          TextFormField(
                            initialValue: sec['content']['readingPassage'],
                            decoration: const InputDecoration(labelText: 'Reading Passage (Văn bản đoạn đọc) *', alignLabelWithHint: true),
                            maxLines: 6,
                            onChanged: (val) => sec['content']['readingPassage'] = val,
                          ),
                        if (sec['skill'] == 'LISTENING') 
                          TextFormField(
                            initialValue: sec['content']['audioUrl'],
                            decoration: const InputDecoration(labelText: 'Audio URL (Link file ghi âm nguoibanho.mp3) *'),
                            onChanged: (val) => sec['content']['audioUrl'] = val,
                          ),
                          
                        const SizedBox(height: 24),
                        const Text('Danh sách Câu Hỏi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        
                        // Questions
                        ...(sec['questions'] as List).asMap().entries.map((qEntry) {
                          int qIndex = qEntry.key;
                          var q = qEntry.value;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                               border: Border.all(color: AppColors.gray200),
                               borderRadius: BorderRadius.circular(8)
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: q['questionText'],
                                        decoration: InputDecoration(labelText: 'Nội dung câu hỏi ${qIndex + 1} *'),
                                        onChanged: (val) => q['questionText'] = val,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, color: AppColors.error),
                                      onPressed: () {
                                        setState(() {
                                          (sec['questions'] as List).removeAt(qIndex);
                                        });
                                      },
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: q['questionType'],
                                  decoration: const InputDecoration(labelText: 'Loại câu hỏi'),
                                  items: const [
                                    DropdownMenuItem(value: 'MULTIPLE_CHOICE', child: Text('Trắc Nghiệm (MULTIPLE_CHOICE)')),
                                    DropdownMenuItem(value: 'FILL_BLANK', child: Text('Điền Từ (FILL_BLANK)')),
                                    DropdownMenuItem(value: 'ESSAY', child: Text('Viết Luận (ESSAY)')),
                                    DropdownMenuItem(value: 'SPEAKING_PROMPT', child: Text('Đề Nói (SPEAKING_PROMPT)')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => q['questionType'] = val);
                                  },
                                ),
                                const SizedBox(height: 12),
                                // Options cho trắc nghiệm
                                if (q['questionType'] == 'MULTIPLE_CHOICE')
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Các lựa chọn (Options):', style: TextStyle(fontSize: 12, color: AppColors.gray600)),
                                      ...(q['content']['options'] as List).asMap().entries.map((optEntry) {
                                        return TextFormField(
                                          initialValue: optEntry.value,
                                          decoration: InputDecoration(labelText: 'Option ${optEntry.key + 1}', isDense: true),
                                          onChanged: (val) => q['content']['options'][optEntry.key] = val,
                                        );
                                      }),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                // Đáp án đúng (cho trắc nghiệm và điền từ)
                                if (q['questionType'] == 'MULTIPLE_CHOICE' || q['questionType'] == 'FILL_BLANK')
                                  TextFormField(
                                    initialValue: q['correctAnswers'],
                                    decoration: const InputDecoration(labelText: 'Đáp án đúng (phân cách bằng dấu phẩy) *'),
                                    onChanged: (val) => q['correctAnswers'] = val,
                                  ),
                              ],
                            ),
                          );
                        }),
                        
                        OutlinedButton.icon(
                          onPressed: () => _addQuestion(secIndex),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm Câu Hỏi'),
                        )
                      ],
                    ),
                  ),
                );
             }),
             
             // Nút thêm Section mới
             ElevatedButton.icon(
              onPressed: _addSection,
              icon: const Icon(Icons.add_circle),
              label: const Text('Thêm Section / Kỹ Năng Mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gray200,
                foregroundColor: AppColors.gray900,
                padding: const EdgeInsets.symmetric(vertical: 20)
              ),
             ),
             const SizedBox(height: 24),
             
             // Nút Lưu bự ở dưới cùng
             ElevatedButton(
               onPressed: _saveExam,
               style: ElevatedButton.styleFrom(
                 backgroundColor: AppColors.primary,
                 foregroundColor: AppColors.white,
                 padding: const EdgeInsets.symmetric(vertical: 20)
               ),
               child: Text(
                 widget.exam == null ? 'TẠO MỚI ĐỀ THI' : 'CẬP NHẬT ĐỀ THI',
                 style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
               ),
             ),
             const SizedBox(height: 100), // padding bottom
          ],
        ),
      ),
    );
  }
}
