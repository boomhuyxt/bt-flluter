import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMember {
  final String name;
  final String studentId;
  final String role;
  final String department;
  final String phone;
  final String email;
  final String contribution;
  final String avatarEmoji;
  final List<Color> cardGradient;

  const TeamMember({
    required this.name,
    required this.studentId,
    required this.role,
    required this.department,
    required this.phone,
    required this.email,
    required this.contribution,
    required this.avatarEmoji,
    required this.cardGradient,
  });
}

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key});

  static const List<TeamMember> teamMembers = [
    TeamMember(
      name: 'Diệp Gia Huy',
      studentId: '2180601234',
      role: 'Trưởng Nhóm & Lập Trình Viên Chính',
      department: 'Khoa Công Nghệ Thông Tin',
      phone: '0987654321',
      email: 'diepgiahuy@gmail.com',
      contribution:
          '• Thiết kế kiến trúc tổng thể ứng dụng & BottomNavigationBar\n'
          '• Tích hợp Google ML Kit Translation (Text, Voice STT, OCR ảnh, Camera Realtime)\n'
          '• Xây dựng hệ thống báo thức bằng giọng nói đa ngôn ngữ\n'
          '• Tích hợp url_launcher gọi điện & mở app YouTube',
      avatarEmoji: '👨‍💻',
      cardGradient: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    ),
    TeamMember(
      name: 'Nguyễn Văn Bình',
      studentId: '2180602345',
      role: 'Phát Triển Giao Diện (UI/UX) & Kiểm Thử',
      department: 'Khoa Công Nghệ Thông Tin',
      phone: '0912345678',
      email: 'nguyenvanbinh@gmail.com',
      contribution:
          '• Thiết kế giao diện Light/Dark Mode theo Material 3\n'
          '• Xây dựng màn hình SplashScreen hiệu ứng nhịp thở và tiến trình nạp\n'
          '• Phát triển module Chuyển đổi nhiệt độ & Đơn vị đo lường đa năng\n'
          '• Viết bộ kiểm thử Unit Tests và tích hợp CI/CD',
      avatarEmoji: '🎨',
      cardGradient: [Color(0xFF0284C7), Color(0xFF0D9488)],
    ),
    TeamMember(
      name: 'Trần Thị Mai',
      studentId: '2180603456',
      role: 'Phát Triển Tiện Ích Đa Phương Tiện',
      department: 'Khoa Công Nghệ Thông Tin',
      phone: '0978123456',
      email: 'tranthimai@gmail.com',
      contribution:
          '• Tích hợp trình phát video YouTube Player trực tiếp\n'
          '• Xây dựng đồng hồ báo thức âm thanh và đồng hồ bấm giờ thể thao lưu vòng lap\n'
          '• Thu thập cơ sở dữ liệu mẫu câu giao tiếp thông dụng đa ngôn ngữ\n'
          '• Soạn thảo tài liệu báo cáo kỹ thuật đồ án',
      avatarEmoji: '👩‍💻',
      cardGradient: [Color(0xFFD97706), Color(0xFFEA580C)],
    ),
  ];

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  Future<void> _callMember(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gọi điện đến $phone: $e')),
        );
      }
    }
  }

  Future<void> _emailMember(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(uri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể gửi mail đến $email: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups, size: 24),
            SizedBox(width: 8),
            Text(
              'Thông Tin Nhóm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // Header Instruction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'DANH SÁCH THÀNH VIÊN (${GroupInfoScreen.teamMembers.length})',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.swipe, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Vuốt để xem',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Swipeable Carousel PageView
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: GroupInfoScreen.teamMembers.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final member = GroupInfoScreen.teamMembers[index];

                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double scale = 1.0;
                    if (_pageController.position.haveDimensions) {
                      final page = _pageController.page ?? 0.0;
                      scale = (1 - ((page - index).abs() * 0.06)).clamp(0.9, 1.0);
                    }
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 40 : 15),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Member Avatar with Gradient Banner
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: member.cardGradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.white.withAlpha(50),
                                  child: Text(
                                    member.avatarEmoji,
                                    style: const TextStyle(fontSize: 34),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'MSSV: ${member.studentId}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        member.department,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white60,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.stars, color: theme.colorScheme.primary, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    member.role,
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contributions
                          const Text(
                            'NHIỆM VỤ ĐÃ HOÀN THÀNH:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              member.contribution,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contact Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.call, size: 18, color: Colors.green),
                                  label: const Text('Gọi điện', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _callMember(member.phone),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.email, size: 18, color: Colors.blue),
                                  label: const Text('Email', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _emailMember(member.email),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Pagination Dots & Arrow Controls
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: _currentPage > 0
                      ? () => _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
                ...List.generate(GroupInfoScreen.teamMembers.length, (index) {
                  final isSelected = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.grey[400],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  onPressed: _currentPage < GroupInfoScreen.teamMembers.length - 1
                      ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          )
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
