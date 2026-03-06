import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/topic.dart';
import 'models/recording.dart';
import 'screens/login_screen.dart';
import 'screens/topic_feed_screen.dart';
import 'screens/history_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/topic_management_screen.dart';

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

  void _handleRoleSelected(String role) {
    setState(() {
      _currentRole = role;
      _currentUserTab = 0;
      _currentAdminTab = 0;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentRole = null;
      _currentUserTab = 0;
      _currentAdminTab = 0;
    });
  }

  void _handleSelectTopic(Topic topic) {
    // Navigate to practice screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(topic.title),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mic_rounded,
                  size: 100,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Practice Screen',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  topic.title,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleViewRecording(Recording recording) {
    // Navigate to feedback screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(recording.topicTitle),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.feedback_rounded,
                  size: 100,
                  color: AppColors.success,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Feedback View',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  recording.topicTitle,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Overall Score: ${recording.feedback.overall}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quay lại'),
                ),
              ],
            ),
          ),
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: isMobile ? 18 : 24,
                color: isSelected ? AppColors.primary : AppColors.gray600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.primary : AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}