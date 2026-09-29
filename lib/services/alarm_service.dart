import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlarmItem {
  final String id;
  TimeOfDay time;
  String label;
  bool isEnabled;

  AlarmItem({
    required this.id,
    required this.time,
    this.label = 'Báo thức',
    this.isEnabled = true,
  });

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class AlarmService extends ChangeNotifier {
  static final AlarmService instance = AlarmService._();

  AlarmService._() {
    _initTimer();
  }

  final List<AlarmItem> _alarms = [
    AlarmItem(
      id: '1',
      time: const TimeOfDay(hour: 7, minute: 0),
      label: 'Thức dậy buổi sáng',
      isEnabled: false,
    ),
    AlarmItem(
      id: '2',
      time: const TimeOfDay(hour: 12, minute: 30),
      label: 'Ăn trưa & nghỉ ngơi',
      isEnabled: false,
    ),
  ];

  AudioPlayer? _audioPlayer;
  AudioPlayer get audioPlayer => _audioPlayer ??= AudioPlayer();

  Timer? _timer;
  AlarmItem? _ringingAlarm;
  bool _isRinging = false;
  int _lastTriggeredMinute = -1;

  List<AlarmItem> get alarms => List.unmodifiable(_alarms);
  AlarmItem? get ringingAlarm => _ringingAlarm;
  bool get isRinging => _isRinging;

  void _initTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  void _checkAlarms() {
    final now = DateTime.now();
    final currentMinute = now.hour * 60 + now.minute;

    if (_lastTriggeredMinute == currentMinute) {
      return; // Already triggered this minute
    }

    for (final alarm in _alarms) {
      if (alarm.isEnabled) {
        if (alarm.time.hour == now.hour && alarm.time.minute == now.minute) {
          _lastTriggeredMinute = currentMinute;
          triggerAlarm(alarm);
          break;
        }
      }
    }
  }

  void addAlarm(TimeOfDay time, {String label = 'Báo thức'}) {
    final newAlarm = AlarmItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: time,
      label: label.isEmpty ? 'Báo thức' : label,
      isEnabled: true,
    );
    _alarms.add(newAlarm);
    _alarms.sort((a, b) => (a.time.hour * 60 + a.time.minute).compareTo(b.time.hour * 60 + b.time.minute));
    notifyListeners();
  }

  void toggleAlarm(String id, bool isEnabled) {
    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      _alarms[index].isEnabled = isEnabled;
      notifyListeners();
    }
  }

  void removeAlarm(String id) {
    _alarms.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> triggerAlarm(AlarmItem alarm) async {
    _ringingAlarm = alarm;
    _isRinging = true;
    notifyListeners();

    // Play alarm audio looping
    try {
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource('audio/alarm.wav'));
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  Future<void> testSound() async {
    try {
      await audioPlayer.stop();
      await audioPlayer.setReleaseMode(ReleaseMode.release);
      await audioPlayer.play(AssetSource('audio/alarm.wav'));
    } catch (e) {
      debugPrint('Error testing sound: $e');
    }
  }

  Future<void> stopAlarm() async {
    _isRinging = false;
    _ringingAlarm = null;
    try {
      await _audioPlayer?.stop();
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
    notifyListeners();
  }

  Future<void> snoozeAlarm([int minutes = 5]) async {
    await stopAlarm();
    final now = DateTime.now().add(Duration(minutes: minutes));
    final snoozeTime = TimeOfDay(hour: now.hour, minute: now.minute);
    addAlarm(snoozeTime, label: 'Báo lại (sau $minutes phút)');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }
}
