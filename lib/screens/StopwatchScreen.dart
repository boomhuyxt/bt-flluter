import 'package:flutter/material.dart';
import '../services/stopwatch_service.dart';

const Color emeraldColor = Color(0xFF059669);
const Color emeraldAccentColor = Color(0xFF10B981);

class StopwatchScreen extends StatefulWidget {
  final bool isEmbedded;
  const StopwatchScreen({super.key, this.isEmbedded = false});

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  final StopwatchService _stopwatch = StopwatchService.instance;

  @override
  void initState() {
    super.initState();
    _stopwatch.addListener(_onUpdate);
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stopwatch.removeListener(_onUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isRunning = _stopwatch.isRunning;
    final elapsed = _stopwatch.elapsed;
    final laps = _stopwatch.laps;

    // Find fastest and slowest lap
    Duration? minLap;
    Duration? maxLap;
    if (laps.length >= 2) {
      minLap = laps.map((l) => l.lapTime).reduce((a, b) => a < b ? a : b);
      maxLap = laps.map((l) => l.lapTime).reduce((a, b) => a > b ? a : b);
    }

    final minutes = (elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final hundreds = ((elapsed.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    final hours = elapsed.inHours > 0 ? '${elapsed.inHours.toString().padLeft(2, '0')}:' : '';

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Đồng hồ bấm giờ'),
            ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          // Digital Timer Display
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: isRunning
                      ? emeraldAccentColor
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFA7F3D0)),
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isRunning ? emeraldColor : Colors.teal).withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRunning ? 'ĐANG CHẠY' : (elapsed > Duration.zero ? 'TẠM DỪNG' : 'SẴN SÀNG'),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: isRunning ? Colors.green : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (hours.isNotEmpty)
                        Text(
                          hours,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '.$hundreds',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.tealAccent : Colors.teal[800],
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (laps.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Đã lưu ${laps.length} mốc',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.tealAccent : Colors.teal[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Control Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Lap / Reset button
                // Lap Button (when running)
                if (isRunning)
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    iconSize: 26,
                    tooltip: 'Ghi mốc (Lap)',
                    onPressed: () => _stopwatch.recordLap(),
                    icon: const Icon(Icons.flag),
                  )
                else
                  const SizedBox(width: 58),

                // Main Start / Stop Button
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: isRunning ? Colors.redAccent : emeraldColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                  ),
                  iconSize: 34,
                  tooltip: isRunning ? 'Dừng & Lưu mốc' : 'Bắt đầu',
                  onPressed: () {
                    if (isRunning) {
                      _stopwatch.pauseAndSaveMilestone();
                    } else {
                      _stopwatch.start();
                    }
                  },
                  icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                ),

                // Reset Button (when paused with time > 0)
                if (!isRunning && elapsed > Duration.zero)
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    iconSize: 26,
                    tooltip: 'Đặt lại về 0',
                    onPressed: () => _stopwatch.reset(),
                    icon: const Icon(Icons.refresh),
                  )
                else
                  const SizedBox(width: 58),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Saved Milestones (Laps) Header & List
          if (laps.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MỐC THỜI GIAN ĐÃ LƯU (${laps.length})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _stopwatch.reset(),
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Xóa tất cả', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: laps.length,
                itemBuilder: (context, index) {
                  final lap = laps[index];
                  final isFastest = minLap != null && lap.lapTime == minLap;
                  final isSlowest = maxLap != null && lap.lapTime == maxLap;

                  Color? highlightColor;
                  if (isFastest) highlightColor = Colors.green;
                  if (isSlowest) highlightColor = Colors.red;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: highlightColor?.withAlpha(30) ??
                                  (isDark ? Colors.grey[800] : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Mốc #${lap.index}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: highlightColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isFastest)
                            const Text('Nhanh nhất ⚡', style: TextStyle(fontSize: 11, color: Colors.green))
                          else if (isSlowest)
                            const Text('Chậm nhất ⏳', style: TextStyle(fontSize: 11, color: Colors.red)),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                lap.formattedTotalTime,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: highlightColor,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              Text(
                                'Thời gian vòng: ${lap.formattedLapTime}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            const Spacer(),
            Icon(Icons.timer_outlined, size: 54, color: Colors.grey.withAlpha(80)),
            const SizedBox(height: 8),
            Text(
              'Nói "Bắt đầu" để chạy • Nói "Dừng" để lưu mốc',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const Spacer(),
          ],
        ],
      ),
    );
  }
}
