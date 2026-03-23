import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  final Function(String) onRoleSelected;

  const RoleSelectionScreen({
    super.key,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFF6FF),
              Color(0xFFFFFFFF),
            ],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header
                  Icon(
                    Icons.mic_rounded,
                    size: isMobile ? 48 : 64,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: isMobile ? 8 : 16),
                  Text(
                    'AI Speaking Practice',
                    style: TextStyle(
                      fontSize: isMobile ? 28 : 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Luyện nói và nhận đánh giá từ AI',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 18,
                      color: AppColors.gray600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 24 : 48),

                  // Role Cards
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 600;
                        if (isWide) {
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: _RoleCard(
                                    icon: Icons.person_rounded,
                                    iconColor: AppColors.primary,
                                    iconBgColor: AppColors.primary.withOpacity(0.1),
                                    title: 'User',
                                    description: 'Luyện tập speaking với các topic được giao và nhận feedback từ AI',
                                    features: const [
                                      '✓ Chọn topics luyện tập',
                                      '✓ Ghi âm và nhận AI feedback',
                                      '✓ Xem lịch sử và theo dõi tiến độ',
                                      '✓ Đánh giá chi tiết từng kỹ năng',
                                    ],
                                    buttonText: 'Bắt đầu với User',
                                    onTap: () => onRoleSelected('user'),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: _RoleCard(
                                    icon: Icons.settings_rounded,
                                    iconColor: AppColors.secondary,
                                    iconBgColor: AppColors.secondary.withOpacity(0.1),
                                    title: 'Admin',
                                    description: 'Quản lý topics, theo dõi hoạt động và hiệu suất của users',
                                    features: const [
                                      '✓ Tạo và quản lý topics',
                                      '✓ Dashboard thống kê',
                                      '✓ Theo dõi hiệu suất users',
                                      '✓ Phân tích xu hướng học tập',
                                    ],
                                    buttonText: 'Bắt đầu với Admin',
                                    onTap: () => onRoleSelected('admin'),
                                    isOutlined: true,
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // Mobile layout
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RoleCard(
                                icon: Icons.person_rounded,
                                iconColor: AppColors.primary,
                                iconBgColor: AppColors.primary.withOpacity(0.1),
                                title: 'User',
                                description: 'Luyện tập speaking với các topic được giao và nhận feedback từ AI',
                                features: const [
                                  '✓ Chọn topics luyện tập',
                                  '✓ Ghi âm và nhận AI feedback',
                                  '✓ Xem lịch sử và theo dõi tiến độ',
                                  '✓ Đánh giá chi tiết từng kỹ năng',
                                ],
                                buttonText: 'Bắt đầu với User',
                                onTap: () => onRoleSelected('user'),
                              ),
                              const SizedBox(height: 24),
                              _RoleCard(
                                icon: Icons.settings_rounded,
                                iconColor: AppColors.secondary,
                                iconBgColor: AppColors.secondary.withOpacity(0.1),
                                title: 'Admin',
                                description: 'Quản lý topics, theo dõi hoạt động và hiệu suất của users',
                                features: const [
                                  '✓ Tạo và quản lý topics',
                                  '✓ Dashboard thống kê',
                                  '✓ Theo dõi hiệu suất users',
                                  '✓ Phân tích xu hướng học tập',
                                ],
                                buttonText: 'Bắt đầu với Admin',
                                onTap: () => onRoleSelected('admin'),
                                isOutlined: true,
                              ),
                            ],
                          );
                        }
                      },
                    ),
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

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String description;
  final List<String> features;
  final String buttonText;
  final VoidCallback onTap;
  final bool isOutlined;

  const _RoleCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.description,
    required this.features,
    required this.buttonText,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? widget.iconColor.withOpacity(0.5) : Colors.transparent,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withOpacity(_isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 12 : 8),
                spreadRadius: _isHovered ? 2 : 0,
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: isMobile ? 56 : 72,
                height: isMobile ? 56 : 72,
                decoration: BoxDecoration(
                  color: widget.iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: isMobile ? 28 : 36,
                  color: widget.iconColor,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: isMobile ? 22 : 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                widget.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.gray600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Features
              ...widget.features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray600,
                      ),
                    ),
                  )),
              const SizedBox(height: 24),

              // Button
              Container(
                width: double.infinity,
                decoration: widget.isOutlined ? null : BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [widget.iconColor.withOpacity(0.7), widget.iconColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.iconColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: widget.isOutlined
                    ? OutlinedButton(
                        onPressed: widget.onTap,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: widget.iconColor, width: 1.5),
                          foregroundColor: widget.iconColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          widget.buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          widget.buttonText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
