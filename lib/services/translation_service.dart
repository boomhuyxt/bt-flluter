import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class TranslationLanguage {
  final String code;
  final String name;
  final String flag;

  const TranslationLanguage({
    required this.code,
    required this.name,
    required this.flag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationLanguage &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class TranslationHistoryItem {
  final String id;
  final String sourceText;
  final String translatedText;
  final String fromLangCode;
  final String toLangCode;
  final DateTime timestamp;
  bool isFavorite;

  TranslationHistoryItem({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    required this.fromLangCode,
    required this.toLangCode,
    required this.timestamp,
    this.isFavorite = false,
  });
}

class QuickPhrase {
  final String category;
  final String text;
  final String translation;

  const QuickPhrase({
    required this.category,
    required this.text,
    required this.translation,
  });
}

class TranslationService extends ChangeNotifier {
  static final TranslationService instance = TranslationService._();
  TranslationService._();

  static const List<TranslationLanguage> supportedLanguages = [
    TranslationLanguage(code: 'vi', name: 'Tiếng Việt', flag: '🇻🇳'),
    TranslationLanguage(code: 'en', name: 'Tiếng Anh', flag: '🇬🇧'),
    TranslationLanguage(code: 'zh-CN', name: 'Tiếng Trung (Giản thể)', flag: '🇨🇳'),
    TranslationLanguage(code: 'zh-TW', name: 'Tiếng Trung (Phồn thể)', flag: '🇹🇼'),
    TranslationLanguage(code: 'ja', name: 'Tiếng Nhật', flag: '🇯🇵'),
    TranslationLanguage(code: 'ko', name: 'Tiếng Hàn', flag: '🇰🇷'),
    TranslationLanguage(code: 'fr', name: 'Tiếng Pháp', flag: '🇫🇷'),
    TranslationLanguage(code: 'es', name: 'Tiếng Tây Ban Nha', flag: '🇪🇸'),
    TranslationLanguage(code: 'de', name: 'Tiếng Đức', flag: '🇩🇪'),
    TranslationLanguage(code: 'ru', name: 'Tiếng Nga', flag: '🇷🇺'),
    TranslationLanguage(code: 'th', name: 'Tiếng Thái', flag: '🇹🇭'),
    TranslationLanguage(code: 'it', name: 'Tiếng Ý', flag: '🇮🇹'),
    TranslationLanguage(code: 'pt', name: 'Tiếng Bồ Đào Nha', flag: '🇵🇹'),
    TranslationLanguage(code: 'id', name: 'Tiếng Indonesia', flag: '🇮🇩'),
    TranslationLanguage(code: 'ms', name: 'Tiếng Malaysia', flag: '🇲🇾'),
    TranslationLanguage(code: 'hi', name: 'Tiếng Hindi', flag: '🇮🇳'),
    TranslationLanguage(code: 'ar', name: 'Tiếng Ả Rập', flag: '🇸🇦'),
    TranslationLanguage(code: 'tr', name: 'Tiếng Thổ Nhĩ Kỳ', flag: '🇹🇷'),
    TranslationLanguage(code: 'nl', name: 'Tiếng Hà Lan', flag: '🇳🇱'),
    TranslationLanguage(code: 'pl', name: 'Tiếng Ba Lan', flag: '🇵🇱'),
    TranslationLanguage(code: 'la', name: 'Tiếng Latinh', flag: '🏛️'),
  ];

  static const List<QuickPhrase> quickPhrases = [
    QuickPhrase(
      category: 'Chào hỏi',
      text: 'Xin chào, rất vui được gặp bạn!',
      translation: 'Hello, very nice to meet you!',
    ),
    QuickPhrase(
      category: 'Chào hỏi',
      text: 'Chúc bạn một ngày làm việc tuyệt vời!',
      translation: 'Have a wonderful working day!',
    ),
    QuickPhrase(
      category: 'Giao tiếp',
      text: 'Cảm ơn bạn rất nhiều vì sự giúp đỡ!',
      translation: 'Thank you very much for your help!',
    ),
    QuickPhrase(
      category: 'Giao tiếp',
      text: 'Bạn có thể nói chậm lại một chút được không?',
      translation: 'Could you please speak a little slower?',
    ),
    QuickPhrase(
      category: 'Du lịch',
      text: 'Làm ơn cho tôi hỏi đường đến sân bay gần nhất?',
      translation: 'Excuse me, could you tell me the way to the nearest airport?',
    ),
    QuickPhrase(
      category: 'Du lịch',
      text: 'Một đêm ở khách sạn này giá bao nhiêu?',
      translation: 'How much does it cost per night at this hotel?',
    ),
    QuickPhrase(
      category: 'Ăn uống',
      text: 'Vui lòng cho tôi xem thực đơn món ăn.',
      translation: 'Please show me the food menu.',
    ),
    QuickPhrase(
      category: 'Ăn uống',
      text: 'Món này rất ngon, tôi xin phép thanh toán hóa đơn.',
      translation: 'This dish is delicious, check please.',
    ),
  ];

  final List<TranslationHistoryItem> _history = [];
  List<TranslationHistoryItem> get history => List.unmodifiable(_history);

  TranslationLanguage getLanguage(String code) {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == code,
      orElse: () => supportedLanguages.first,
    );
  }

  /// Dịch văn bản thông qua Google Translate endpoint công khai
  Future<String> translate({
    required String text,
    required String fromCode,
    required String toCode,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    if (fromCode == toCode) return trimmed;

    final url = Uri.parse(
      'https://translate.googleapis.com/translate_a/single'
      '?client=gtx'
      '&sl=$fromCode'
      '&tl=$toCode'
      '&dt=t'
      '&q=${Uri.encodeComponent(trimmed)}',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final buffer = StringBuffer();

        if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
          for (final chunk in decoded[0]) {
            if (chunk is List && chunk.isNotEmpty && chunk[0] != null) {
              buffer.write(chunk[0]);
            }
          }
        }

        final result = buffer.toString();
        if (result.isNotEmpty) {
          _addToHistory(
            sourceText: trimmed,
            translatedText: result,
            fromLangCode: fromCode,
            toLangCode: toCode,
          );
        }
        return result;
      } else {
        throw Exception('Không thể kết nối đến máy chủ dịch thuật (mã lỗi ${response.statusCode})');
      }
    } catch (e) {
      debugPrint('Lỗi dịch thuật: $e');
      rethrow;
    }
  }

  void _addToHistory({
    required String sourceText,
    required String translatedText,
    required String fromLangCode,
    required String toLangCode,
  }) {
    // Avoid immediate duplicate
    if (_history.isNotEmpty &&
        _history.first.sourceText == sourceText &&
        _history.first.fromLangCode == fromLangCode &&
        _history.first.toLangCode == toLangCode) {
      return;
    }

    final item = TranslationHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sourceText: sourceText,
      translatedText: translatedText,
      fromLangCode: fromLangCode,
      toLangCode: toLangCode,
      timestamp: DateTime.now(),
    );

    _history.insert(0, item);
    if (_history.length > 50) {
      _history.removeLast();
    }
    notifyListeners();
  }

  void removeHistoryItem(String id) {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final index = _history.indexWhere((item) => item.id == id);
    if (index != -1) {
      _history[index].isFavorite = !_history[index].isFavorite;
      notifyListeners();
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }
}
