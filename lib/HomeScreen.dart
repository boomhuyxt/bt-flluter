import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'TemperatureConverterScreen.dart';
import 'UnitConverterScreen.dart';
import 'screens/YouTubePlayerScreen.dart';
import 'screens/AlarmClockScreen.dart';
import 'screens/StopwatchScreen.dart';
import 'screens/TranslatorScreen.dart';
import 'screens/GroupInfoScreen.dart';
import 'screens/PersonalProfileScreen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int>? onSelectTab;
  const HomeScreen({super.key, this.onSelectTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> features = [
      {
        'title': 'Google ML Kit Translate',
        'subtitle': 'Dịch Text (7đ) • Giọng nói STT (9đ) • Ảnh OCR (10đ) • Camera Realtime',
        'icon': Icons.g_translate,
        'gradient': isDark
            ? [const Color(0xFF1D4ED8), const Color(0xFF3B82F6)]
            : [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
        'iconColor': Colors.white,
        'tabIndex': 1,
        'screen': const TranslatorScreen(),
      },
      {
        'title': 'Báo thức giọng nói (STT)',
        'subtitle': 'Đặt báo thức bằng giọng nói đa ngôn ngữ (5đ) • Đồng bộ Android',
        'icon': Icons.alarm,
        'gradient': isDark
            ? [const Color(0xFFB45309), const Color(0xFFD97706)]
            : [const Color(0xFFD97706), const Color(0xFFFBBF24)],
        'iconColor': Colors.white,
        'tabIndex': 2,
        'screen': const AlarmClockScreen(),
      },
      {
        'title': 'Thông tin nhóm đồ án',
        'subtitle': 'Lướt xem hồ sơ thành viên, ảnh đại diện, vai trò & đóng góp (Mục 6)',
        'icon': Icons.groups,
        'gradient': isDark
            ? [const Color(0xFF4C1D95), const Color(0xFF6D28D9)]
            : [const Color(0xFF6D28D9), const Color(0xFF8B5CF6)],
        'iconColor': Colors.white,
        'tabIndex': 3,
        'screen': const GroupInfoScreen(),
      },
      {
        'title': 'Giao diện Cá nhân',
        'subtitle': 'Gọi điện SĐT cài đặt (url_launcher) • Gọi tới app YouTube (3.5đ)',
        'icon': Icons.person,
        'gradient': isDark
            ? [const Color(0xFF065F46), const Color(0xFF059669)]
            : [const Color(0xFF059669), const Color(0xFF10B981)],
        'iconColor': Colors.white,
        'tabIndex': 4,
        'screen': const PersonalProfileScreen(),
      },
      {
        'title': 'Chuyển đổi nhiệt độ',
        'subtitle': 'Quy đổi 2 chiều °C ⇄ °F, K (VD: 10°F = -12.22°C)',
        'icon': Icons.thermostat,
        'gradient': isDark
            ? [const Color(0xFFC2410C), const Color(0xFFEA580C)]
            : [const Color(0xFFEA580C), const Color(0xFFFB923C)],
        'iconColor': Colors.white,
        'screen': const TemperatureConverterScreen(),
      },
      {
        'title': 'Chuyển đổi đơn vị đo',
        'subtitle': 'Chiều dài, Khối lượng, Dung tích (VD: 10 m = 32.81 ft)',
        'icon': Icons.straighten,
        'gradient': isDark
            ? [const Color(0xFF0369A1), const Color(0xFF0284C7)]
            : [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
        'iconColor': Colors.white,
        'screen': const UnitConverterScreen(),
      },
      {
        'title': 'Xem video YouTube tích hợp',
        'subtitle': 'Nhập link/ID YouTube và phát video trực tiếp trong app',
        'icon': Icons.smart_display,
        'gradient': isDark
            ? [const Color(0xFF991B1B), const Color(0xFFDC2626)]
            : [const Color(0xFFDC2626), const Color(0xFFEF4444)],
        'iconColor': Colors.white,
        'screen': const YouTubePlayerScreen(),
      },
      {
        'title': 'Đồng hồ bấm giờ thể thao',
        'subtitle': 'Đo mili-giây, ghi vòng Lap, phân tích nhanh nhất/chậm nhất',
        'icon': Icons.timer,
        'gradient': isDark
            ? [const Color(0xFF047857), const Color(0xFF059669)]
            : [const Color(0xFF059669), const Color(0xFF34D399)],
        'iconColor': Colors.white,
        'screen': const StopwatchScreen(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.dashboard_customize, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Ứng Dụng Đa Năng',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Chuyển sang Chế độ Sáng' : 'Chuyển sang Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.amber : theme.colorScheme.primary,
            ),
            onPressed: () {
              ThemeNotifier.instance.toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Welcome Banner
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
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF4F46E5)).withAlpha(50),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isDark ? '🌙 Chế độ Tối (Dark Mode)' : '☀️ Chế độ Sáng (Light Mode)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Bộ Công Cụ Tiện Ích Đồ Án (10đ + Điểm cộng)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Google ML Kit Translate (Text, Voice, OCR, Realtime) • Báo thức STT • Gọi điện url_launcher • Info nhóm',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section Header
            Row(
              children: [
                const Icon(Icons.apps, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Chọn chức năng để sử dụng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Grid of Feature Buttons / Cards
            ...features.map((item) {
              final List<Color> gradientColors = item['gradient'] as List<Color>;
              final Widget destination = item['screen'] as Widget;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      if (onSelectTab != null && item.containsKey('tabIndex')) {
                        onSelectTab!(item['tabIndex'] as int);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => destination),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 30 : 10),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Icon with colored gradient background
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: gradientColors[0].withAlpha(80),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Titles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Chevron / Action indicator
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
