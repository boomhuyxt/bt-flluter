import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'translation_service.dart';

class MLKitTranslationService extends ChangeNotifier {
  static final MLKitTranslationService instance = MLKitTranslationService._();
  MLKitTranslationService._();

  final ImagePicker _picker = ImagePicker();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isSpeechListening = false;
  String _liveSpeechText = '';

  bool get isSpeechListening => _isSpeechListening;
  String get liveSpeechText => _liveSpeechText;

  static const Map<String, TranslateLanguage> _languageCodeMap = {
    'vi': TranslateLanguage.vietnamese,
    'en': TranslateLanguage.english,
    'zh-CN': TranslateLanguage.chinese,
    'zh-TW': TranslateLanguage.chinese,
    'ja': TranslateLanguage.japanese,
    'ko': TranslateLanguage.korean,
    'fr': TranslateLanguage.french,
    'es': TranslateLanguage.spanish,
    'de': TranslateLanguage.german,
    'ru': TranslateLanguage.russian,
    'th': TranslateLanguage.thai,
    'it': TranslateLanguage.italian,
    'pt': TranslateLanguage.portuguese,
    'id': TranslateLanguage.indonesian,
    'ms': TranslateLanguage.malay,
    'hi': TranslateLanguage.hindi,
    'ar': TranslateLanguage.arabic,
    'tr': TranslateLanguage.turkish,
    'nl': TranslateLanguage.dutch,
    'pl': TranslateLanguage.polish,
  };

  TranslateLanguage _getMlKitLanguage(String code) {
    return _languageCodeMap[code] ?? TranslateLanguage.english;
  }

  /// 1. Dịch văn bản (Text Translation - 7đ)
  /// Sử dụng Google ML Kit OnDeviceTranslator trên điện thoại,
  /// tự động fallback sang Cloud HTTP trên Windows Desktop.
  Future<String> translateText({
    required String text,
    required String fromCode,
    required String toCode,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    if (fromCode == toCode) return trimmed;

    // Mobile check: ML Kit native is supported on Android & iOS
    final bool isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (isMobile) {
      try {
        final sourceLang = _getMlKitLanguage(fromCode);
        final targetLang = _getMlKitLanguage(toCode);

        final modelManager = OnDeviceTranslatorModelManager();
        final isSourceDownloaded = await modelManager.isModelDownloaded(sourceLang.bcpCode);
        if (!isSourceDownloaded) {
          await modelManager.downloadModel(sourceLang.bcpCode);
        }

        final isTargetDownloaded = await modelManager.isModelDownloaded(targetLang.bcpCode);
        if (!isTargetDownloaded) {
          await modelManager.downloadModel(targetLang.bcpCode);
        }

        final onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: sourceLang,
          targetLanguage: targetLang,
        );

        final response = await onDeviceTranslator.translateText(trimmed);
        await onDeviceTranslator.close();

        if (response.isNotEmpty) {
          return response;
        }
      } catch (e) {
        debugPrint('ML Kit on-device translation error: $e. Fallback to Cloud.');
      }
    }

    // Fallback: Google Translate Web API (Works universally on Windows Desktop & Mobile)
    return await TranslationService.instance.translate(
      text: trimmed,
      fromCode: fromCode,
      toCode: toCode,
    );
  }

  /// 2. Lấy text từ giọng nói (Voice Translation STT - 9đ)
  /// Nhấn nói -> Nhận diện văn bản -> Người dùng bấm nút để dịch
  Future<void> startVoiceTranslation({
    required String fromCode,
    required Function(String recognized, bool isFinal) onResult,
    required Function(String error) onError,
  }) async {
    try {
      final available = await _speech.initialize(
        onError: (val) {
          _isSpeechListening = false;
          notifyListeners();
          onError(val.errorMsg);
        },
        onStatus: (status) {
          _isSpeechListening = status == 'listening';
          notifyListeners();
        },
      );

      if (!available) {
        onError('Thiết bị không hỗ trợ nhận diện giọng nói hoặc chưa cấp quyền micro.');
        return;
      }

      _liveSpeechText = '';
      _isSpeechListening = true;
      notifyListeners();

      // Convert fromCode to recognition locale
      String localeId = 'vi_VN';
      if (fromCode == 'en') localeId = 'en_US';
      if (fromCode == 'fr') localeId = 'fr_FR';
      if (fromCode == 'ja') localeId = 'ja_JP';
      if (fromCode == 'ko') localeId = 'ko_KR';
      if (fromCode == 'zh-CN') localeId = 'zh_CN';

      await _speech.listen(
        localeId: localeId,
        onResult: (result) {
          _liveSpeechText = result.recognizedWords;
          notifyListeners();
          onResult(result.recognizedWords, result.finalResult);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      );
    } catch (e) {
      _isSpeechListening = false;
      notifyListeners();
      onError('Lỗi microphone: $e');
    }
  }

  Future<void> stopVoiceTranslation() async {
    if (_isSpeechListening) {
      await _speech.stop();
      _isSpeechListening = false;
      notifyListeners();
    }
  }

  /// 3. Dịch từ ảnh chụp camera / thư viện ảnh (Photo OCR Translation - 10đ)
  /// Chụp ảnh hoặc chọn ảnh -> Nhận diện văn bản bằng TextRecognizer -> Dịch bằng ML Kit
  Future<Map<String, String>?> recognizeAndTranslateImage({
    required ImageSource source,
    required String fromCode,
    required String toCode,
  }) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo == null) return null;

    final inputImage = InputImage.fromFilePath(photo.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text.trim();

      if (rawText.isEmpty) {
        throw Exception('Không tìm thấy văn bản nào trong bức ảnh này.');
      }

      final translated = await translateText(
        text: rawText,
        fromCode: fromCode,
        toCode: toCode,
      );

      return {
        'imagePath': photo.path,
        'originalText': rawText,
        'translatedText': translated,
      };
    } finally {
      await textRecognizer.close();
    }
  }
}
