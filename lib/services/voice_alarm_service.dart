import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'alarm_service.dart';

class VoiceAlarmResult {
  final bool success;
  final TimeOfDay? time;
  final String message;
  final String recognizedText;

  const VoiceAlarmResult({
    required this.success,
    this.time,
    required this.message,
    required this.recognizedText,
  });
}

class VoiceAlarmService extends ChangeNotifier {
  static final VoiceAlarmService instance = VoiceAlarmService._();
  VoiceAlarmService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _recognizedWords = '';
  String _currentLocaleId = 'vi_VN';

  bool get isListening => _isListening;
  String get recognizedWords => _recognizedWords;
  String get currentLocaleId => _currentLocaleId;

  static const List<Map<String, String>> supportedLocales = [
    {'code': 'vi_VN', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'en_US', 'name': 'English (US)', 'flag': '🇺🇸'},
    {'code': 'fr_FR', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'ja_JP', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko_KR', 'name': '한국어', 'flag': '🇰🇷'},
  ];

  void setLocale(String localeId) {
    _currentLocaleId = localeId;
    notifyListeners();
  }

  Future<bool> initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (err) {
          debugPrint('STT Error: ${err.errorMsg}');
          _isListening = false;
          notifyListeners();
        },
        onStatus: (status) {
          _isListening = status == 'listening';
          notifyListeners();
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('STT init exception: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(VoiceAlarmResult result) onResult,
    Function(String recognizedText, TimeOfDay? parsedTime)? onLiveUpdate,
  }) async {
    final available = await initSpeech();
    if (!available) {
      onResult(const VoiceAlarmResult(
        success: false,
        message: 'Không thể khởi động microphone hoặc nhận diện giọng nói.',
        recognizedText: '',
      ));
      return;
    }

    _recognizedWords = '';
    _isListening = true;
    notifyListeners();

    bool hasHandled = false;

    try {
      await _speech.listen(
        localeId: _currentLocaleId,
        onResult: (result) {
          _recognizedWords = result.recognizedWords;
          notifyListeners();

          final parseRes = parseAlarmTime(result.recognizedWords);
          onLiveUpdate?.call(result.recognizedWords, parseRes);

          if (hasHandled) return;

          if (result.finalResult || result.recognizedWords.isNotEmpty) {
            if (parseRes != null) {
              hasHandled = true;
              _speech.stop();
              _isListening = false;
              AlarmService.instance.addAlarm(
                parseRes,
                label: 'Báo thức giọng nói ($_currentLocaleId)',
              );
              onResult(VoiceAlarmResult(
                success: true,
                time: parseRes,
                message:
                    'Đã đặt báo thức lúc ${parseRes.hour.toString().padLeft(2, '0')}:${parseRes.minute.toString().padLeft(2, '0')} thành công!',
                recognizedText: result.recognizedWords,
              ));
              notifyListeners();
            } else if (result.finalResult) {
              hasHandled = true;
              _isListening = false;
              notifyListeners();
              onResult(VoiceAlarmResult(
                success: false,
                message:
                    'Không nhận diện được giờ trong câu: "${result.recognizedWords}". Vui lòng thử lại (VD: "Đặt báo thức 7 giờ 30").',
                recognizedText: result.recognizedWords,
              ));
            }
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      _isListening = false;
      notifyListeners();
      onResult(VoiceAlarmResult(
        success: false,
        message: 'Lỗi ghi âm: $e',
        recognizedText: '',
      ));
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
    }
  }

  /// Phân tích câu lệnh giọng nói để lấy TimeOfDay (Hỗ trợ Tiếng Việt & Tiếng Anh)
  TimeOfDay? parseAlarmTime(String rawText) {
    final text = rawText.toLowerCase().trim();

    // 1. Vietnamese pattern: "6 rưỡi" -> 6:30
    final ruoiMatch = RegExp(r'(\d{1,2})\s*rưỡi').firstMatch(text);
    if (ruoiMatch != null) {
      int h = int.parse(ruoiMatch.group(1)!);
      if (text.contains('tối') || text.contains('chiều')) {
        if (h < 12) h += 12;
      }
      return TimeOfDay(hour: h.clamp(0, 23), minute: 30);
    }

    // 2. Pattern: "7 giờ 15 phút" or "7h15" or "7 giờ 15" or "7:15"
    final fullTimeMatch = RegExp(r'(\d{1,2})\s*(?:giờ|h|:)\s*(\d{1,2})').firstMatch(text);
    if (fullTimeMatch != null) {
      int h = int.parse(fullTimeMatch.group(1)!);
      int m = int.parse(fullTimeMatch.group(2)!);
      if (text.contains('chiều') || text.contains('tối') || text.contains('pm')) {
        if (h < 12) h += 12;
      } else if (text.contains('sáng') || text.contains('am')) {
        if (h == 12) h = 0;
      }
      return TimeOfDay(hour: h.clamp(0, 23), minute: m.clamp(0, 59));
    }

    // 3. Pattern: "7 giờ" or "7h" or "7 am" or "7 pm" or "at 7"
    final hourOnlyMatch = RegExp(r"(\d{1,2})\s*(?:giờ|h|o'clock|am|pm|\b)").firstMatch(text);
    if (hourOnlyMatch != null) {
      int h = int.tryParse(hourOnlyMatch.group(1)!) ?? -1;
      if (h >= 0 && h <= 24) {
        if (text.contains('chiều') || text.contains('tối') || text.contains('pm')) {
          if (h < 12) h += 12;
        } else if (text.contains('sáng') || text.contains('am')) {
          if (h == 12) h = 0;
        }
        return TimeOfDay(hour: h.clamp(0, 23), minute: 0);
      }
    }

    // 4. English word numbers fallback (seven thirty, eight o'clock, six am)
    final wordHours = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12,
    };
    for (final entry in wordHours.entries) {
      if (text.contains(entry.key)) {
        int h = entry.value;
        int m = 0;
        if (text.contains('thirty') || text.contains('half')) m = 30;
        if (text.contains('fifteen') || text.contains('quarter')) m = 15;
        if (text.contains('pm') || text.contains('evening') || text.contains('night')) {
          if (h < 12) h += 12;
        }
        return TimeOfDay(hour: h.clamp(0, 23), minute: m);
      }
    }

    return null;
  }
}
