import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/exam.dart';
import 'models/recording.dart';
import 'screens/login_screen.dart';
import 'screens/topic_feed_screen.dart';
import 'screens/history_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/topic_management_screen.dart';
import 'screens/ielts_speaking_screen.dart';
import 'screens/ielts_writing_screen.dart';
import 'screens/ielts_reading_screen.dart';
import 'screens/ielts_listening_screen.dart';
import 'services/api_service.dart';
import 'screens/exam_result_screen.dart';
import 'screens/full_exam_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Speaking Practice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _currentRole;
  int _currentUserTab = 0;
  int _currentAdminTab = 0;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final info = await ApiService.getUserInfo();
    final token = await ApiService.getToken();
    if (token != null && info['role'] != null && mounted) {
      setState(() => _currentRole = info['role']);
    }
  }

  void _handleRoleSelected(String role) {
    setState(() {
      _currentRole = role;
      _currentUserTab = 0;
      _currentAdminTab = 0;
    });
  }

  Future<void> _handleLogout() async {
    await ApiService.clearToken();
    setState(() {
      _currentRole = null;
      _currentUserTab = 0;
      _currentAdminTab = 0;
    });
  }

  void _handleSelectTopic(IeltsExam exam) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Luyện tập kỹ năng',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.gray900),
              ),
              const SizedBox(height: 8),
              const Text(
                'Chọn một kỹ năng IELTS bên dưới để bắt đầu bài thi mô phỏng.',
                style: TextStyle(fontSize: 14, color: AppColors.gray600),
              ),
              const SizedBox(height: 24),

              if (exam.sections.length > 1) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (context) => FullExamScreen(exam: exam)));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.star_rounded, color: Colors.white),
                    label: const Text(
                      'START FULL MOCK TEST',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('HOẶC LUYỆN TẬP TỪNG PHẦN', style: TextStyle(fontSize: 12, color: AppColors.gray400, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              // Skill list
              _SkillTile(
                icon: Icons.mic_rounded,
                title: 'Speaking',
                description: 'Luyện nói và nhận xét phát âm bởi AI',
                color: Colors.blue,
                visible: exam.sections.any((s) => s.skill == 'SPEAKING'),
                onTap: () {
                  final sec = exam.sections.firstWhere((s) => s.skill == 'SPEAKING');
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => IeltsSpeakingScreen(
                    questionId: sec.questions.isNotEmpty ? sec.questions.first.id : exam.id,
                    prompt: sec.questions.isNotEmpty ? sec.questions.first.questionText : 'Speaking Prompt',
                  )));
                },
              ),
              _SkillTile(
                icon: Icons.edit_note_rounded,
                title: 'Writing',
                description: 'Viết luận và chấm điểm ngữ pháp tự động',
                color: Colors.green,
                visible: exam.sections.any((s) => s.skill == 'WRITING'),
                onTap: () {
                  final sec = exam.sections.firstWhere((s) => s.skill == 'WRITING');
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => IeltsWritingScreen(
                    questionId: sec.questions.isNotEmpty ? sec.questions.first.id : exam.id,
                    prompt: sec.questions.isNotEmpty ? sec.questions.first.questionText : 'Writing Prompt',
                  )));
                },
              ),
              _SkillTile(
                icon: Icons.menu_book_rounded,
                title: 'Reading',
                description: 'Luyện đọc đoạn văn và trả lời câu hỏi',
                color: Colors.orange,
                visible: exam.sections.any((s) => s.skill == 'READING'),
                onTap: () {
                  final sec = exam.sections.firstWhere((s) => s.skill == 'READING');
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => IeltsReadingScreen(
                    examId: exam.id,
                    title: exam.title,
                    passage: sec.content['readingPassage'] ?? '',
                    questions: sec.questions.map((q) => q.toJson()).toList(),
                  )));
                },
              ),
              _SkillTile(
                icon: Icons.headphones_rounded,
                title: 'Listening',
                description: 'Nghe audio hội thoại và làm bài tập',
                color: Colors.deepPurple,
                visible: exam.sections.any((s) => s.skill == 'LISTENING'),
                onTap: () {
                  final sec = exam.sections.firstWhere((s) => s.skill == 'LISTENING');
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => IeltsListeningScreen(
                    examId: exam.id,
                    title: exam.title,
                    audioUrl: ApiService.getFullAudioUrl(sec.content['audioUrl']),
                    questions: sec.questions.map((q) => q.toJson()).toList(),
                  )));
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _handleViewRecording(Recording recording) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          resultData: {
            'transcript': recording.transcript,
            'feedback': recording.feedback.toJson(),
            'topicTitle': recording.topicTitle,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Login screen
    if (_currentRole == null) {
      return LoginScreen(
        onLoginSuccess: _handleRoleSelected,
      );
    }

    // User interface
    if (_currentRole == 'user') {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Speaking Practice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'User Mode',
                    style: TextStyle(fontSize: 11, color: AppColors.gray600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Text(
                'U',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Tabs
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.gray200),
                ),
              ),
              child: Row(
                children: [
                  _TabButton(
                    icon: Icons.book_outlined,
                    label: 'Topics',
                    isSelected: _currentUserTab == 0,
                    onTap: () => setState(() => _currentUserTab = 0),
                  ),
                  _TabButton(
                    icon: Icons.history,
                    label: 'Lịch sử',
                    isSelected: _currentUserTab == 1,
                    onTap: () => setState(() => _currentUserTab = 1),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: _currentUserTab == 0
                    ? TopicFeedScreen(onSelectTopic: _handleSelectTopic)
                    : HistoryScreen(onViewRecording: _handleViewRecording),
              ),
            ),
          ],
        ),
      );
    }

    // Admin interface
    if (_currentRole == 'admin') {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.secondary, Colors.pink],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Speaking Practice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Admin Panel',
                    style: TextStyle(fontSize: 11, color: AppColors.gray600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            CircleAvatar(
              backgroundColor: AppColors.secondary.withOpacity(0.1),
              child: const Text(
                'A',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Tabs
            Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.gray200),
                ),
              ),
              child: Row(
                children: [
                  _TabButton(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    isSelected: _currentAdminTab == 0,
                    onTap: () => setState(() => _currentAdminTab = 0),
                  ),
                  _TabButton(
                    icon: Icons.book_outlined,
                    label: 'Quản lý Topics',
                    isSelected: _currentAdminTab == 1,
                    onTap: () => setState(() => _currentAdminTab = 1),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 12 : 24),
                child: _currentAdminTab == 0
                    ? const AdminDashboardScreen()
                    : const TopicManagementScreen(),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.primary : AppColors.gray400,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool visible;
  final VoidCallback onTap;

  const _SkillTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.visible,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray200.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.gray900),
          ),
          subtitle: Text(
            description,
            style: const TextStyle(fontSize: 13, color: AppColors.gray600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray400),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: onTap,
        ),
      ),
    );
  }
}