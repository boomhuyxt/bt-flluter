import 'package:flutter/material.dart';
import '../TemperatureConverterScreen.dart';
import '../UnitConverterScreen.dart';

class ConvertersTabScreen extends StatefulWidget {
  final int initialIndex;
  const ConvertersTabScreen({super.key, this.initialIndex = 0});

  @override
  State<ConvertersTabScreen> createState() => _ConvertersTabScreenState();
}

class _ConvertersTabScreenState extends State<ConvertersTabScreen>
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
          'Công Cụ Quy Đổi',
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
              icon: Icon(Icons.thermostat),
              text: 'Nhiệt độ',
            ),
            Tab(
              icon: Icon(Icons.straighten),
              text: 'Đơn vị đo',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TemperatureConverterScreen(isEmbedded: true),
          UnitConverterScreen(isEmbedded: true),
        ],
      ),
    );
  }
}
