import 'dart:async';
import 'package:flutter/material.dart';

class LapItem {
  final int index;
  final Duration lapTime;
  final Duration totalTime;

  LapItem({
    required this.index,
    required this.lapTime,
    required this.totalTime,
  });

  String get formattedLapTime => StopwatchService.formatDuration(lapTime);
  String get formattedTotalTime => StopwatchService.formatDuration(totalTime);
}

class StopwatchService extends ChangeNotifier {
  static final StopwatchService instance = StopwatchService._();

  StopwatchService._();

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  final List<LapItem> _laps = [];
  Duration _lastLapTotal = Duration.zero;

  bool get isRunning => _stopwatch.isRunning;
  Duration get elapsed => _stopwatch.elapsed;
  List<LapItem> get laps => List.unmodifiable(_laps.reversed);

  void start() {
    if (!_stopwatch.isRunning) {
      _stopwatch.start();
      _ticker = Timer.periodic(const Duration(milliseconds: 30), (_) {
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void pause() {
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
      notifyListeners();
    }
  }

  Duration pauseAndSaveMilestone() {
    final currentTotal = _stopwatch.elapsed;
    if (_stopwatch.isRunning) {
      _stopwatch.stop();
      _ticker?.cancel();
    }

    if (currentTotal > Duration.zero) {
      final lapDuration = currentTotal - _lastLapTotal;
      _lastLapTotal = currentTotal;

      _laps.add(LapItem(
        index: _laps.length + 1,
        lapTime: lapDuration,
        totalTime: currentTotal,
      ));
    }
    notifyListeners();
    return currentTotal;
  }

  void reset() {
    _stopwatch.reset();
    _ticker?.cancel();
    _laps.clear();
    _lastLapTotal = Duration.zero;
    notifyListeners();
  }

  void recordLap() {
    if (_stopwatch.isRunning) {
      final currentTotal = _stopwatch.elapsed;
      final lapDuration = currentTotal - _lastLapTotal;
      _lastLapTotal = currentTotal;

      _laps.add(LapItem(
        index: _laps.length + 1,
        lapTime: lapDuration,
        totalTime: currentTotal,
      ));
      notifyListeners();
    }
  }

  static String formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final hundreds = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '$hours:$minutes:$seconds.$hundreds';
    }
    return '$minutes:$seconds.$hundreds';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
