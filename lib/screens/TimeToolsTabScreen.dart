import 'package:flutter/material.dart';
import 'AlarmClockScreen.dart';
import 'StopwatchScreen.dart';

class TimeToolsTabScreen extends StatefulWidget {
  final int initialIndex;
  const TimeToolsTabScreen({super.key, this.initialIndex = 0});

  @override
  State<TimeToolsTabScreen> createState() => _TimeToolsTabScreenState();
}

class _TimeToolsTabScreenState extends State<TimeToolsTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đồng Hồ & Bấm Giờ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.alarm),
              text: 'Báo thức',
            ),
            Tab(
              icon: Icon(Icons.timer),
              text: 'Bấm giờ',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AlarmClockScreen(isEmbedded: true),
          StopwatchScreen(isEmbedded: true),
        ],
      ),
    );
  }
}
