import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class PersonalProfileScreen extends StatefulWidget {
  const PersonalProfileScreen({super.key});

  @override
  State<PersonalProfileScreen> createState() => _PersonalProfileScreenState();
}

class _PersonalProfileScreenState extends State<PersonalProfileScreen> {
  String _configuredPhoneNumber = '0987654321';
  final String _configuredUserName = 'Nguyễn Văn A';
  final String _configuredStudentId = '20210001';
  final String _configuredEmail = 'sinhvien@hutech.edu.vn';

  /// 1. Gọi điện đến SĐT được cài đặt (url_launcher - 3.5đ)
  Future<void> _makePhoneCall() async {
    final cleanPhone = _configuredPhoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri callUri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      final canCall = await canLaunchUrl(callUri);
      if (canCall) {
        await launchUrl(callUri);
      } else {
        // Fallback for Windows desktop or simulator
        await launchUrl(callUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể kích hoạt cuộc gọi đến $_configuredPhoneNumber: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 2. Gọi tới app YouTube (url_launcher - 3.5đ)
  Future<void> _openYouTubeApp() async {
    // Try launching YouTube app via native scheme first
    final Uri appUri = Uri.parse('vnd.youtube://');
    final Uri webUri = Uri.parse('https://www.youtube.com');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể mở ứng dụng YouTube: $err'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Dialog tùy chỉnh số điện thoại cài đặt
  void _editPhoneNumberDialog() {
    final controller = TextEditingController(text: _configuredPhoneNumber);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cài đặt số điện thoại'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Số điện thoại gọi nhanh',
            prefixIcon: Icon(Icons.phone),
            hintText: 'Nhập SĐT (VD: 0912345678)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty) {
                setState(() {
                  _configuredPhoneNumber = newPhone;
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã cập nhật số điện thoại: $newPhone'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thông Tin Cá Nhân',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 40 : 20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white.withAlpha(40),
                        child: const CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, size: 52, color: Color(0xFF4F46E5)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _configuredUserName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MSSV: $_configuredStudentId • $_configuredEmail',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ Thành viên nhóm phát triển ứng dụng',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Phone Calling (url_launcher - 3.5đ)
            Text(
              'GỌI ĐIỆN THOẠI (URL_LAUNCHER)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.phone_in_talk, color: Colors.green, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Số điện thoại cài sẵn',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                _configuredPhoneNumber,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Đổi số', style: TextStyle(fontSize: 12)),
                        onPressed: _editPhoneNumberDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Call Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.call, size: 22),
                    label: Text(
                      'Gọi ngay đến $_configuredPhoneNumber (url_launcher)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _makePhoneCall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Open YouTube App (url_launcher - 3.5đ)
            Text(
              'TRUY CẬP YOUTUBE (URL_LAUNCHER)',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.smart_display, color: Colors.red, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ứng dụng YouTube',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Kích hoạt mở trực tiếp app YouTube chính thức trên điện thoại',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Open YouTube App Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.play_arrow, size: 24),
                    label: const Text(
                      'Gọi tới app YouTube (vnd.youtube://)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: _openYouTubeApp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: App Settings & Appearance
            Text(
              'GIAO DIỆN & CÀI ĐẶT',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Chế độ Tối (Dark Mode)'),
                    subtitle: Text(
                      isDark ? 'Giao diện tối giúp dịu mắt ban đêm' : 'Giao diện sáng hiện đại',
                      style: const TextStyle(fontSize: 12),
                    ),
                    secondary: Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? Colors.amber : Colors.indigo,
                    ),
                    value: isDark,
                    onChanged: (val) {
                      ThemeNotifier.instance.toggleTheme();
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Phiên bản ứng dụng'),
                    subtitle: const Text('diepgihuy123 v1.0.0+1 • Flutter 3.44', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
