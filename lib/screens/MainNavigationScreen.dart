import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../HomeScreen.dart';
import 'TranslatorScreen.dart';
import 'AlarmClockScreen.dart';
import 'GroupInfoScreen.dart';
import 'PersonalProfileScreen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    if (index >= 0 && index < 5) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Widget> screens = [
      HomeScreen(onSelectTab: switchTab),
      const TranslatorScreen(),
      const AlarmClockScreen(),
      const GroupInfoScreen(),
      const PersonalProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 15),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          elevation: 4,
          backgroundColor: theme.cardTheme.color,
          indicatorColor: theme.colorScheme.primary.withAlpha(isDark ? 60 : 35),
          onDestinationSelected: (index) {
            switchTab(index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: theme.colorScheme.primary),
              label: 'Trang chủ',
            ),
            NavigationDestination(
              icon: const Icon(Icons.g_translate_outlined),
              selectedIcon: Icon(Icons.g_translate, color: theme.colorScheme.primary),
              label: 'Dịch thuật',
            ),
            NavigationDestination(
              icon: const Icon(Icons.alarm_outlined),
              selectedIcon: Icon(Icons.alarm, color: theme.colorScheme.primary),
              label: 'Báo thức',
            ),
            NavigationDestination(
              icon: const Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups, color: theme.colorScheme.primary),
              label: 'Nhóm',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }
}
