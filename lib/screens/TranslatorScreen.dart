import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/translation_service.dart';
import '../services/mlkit_translation_service.dart';
import 'RealtimeCameraTranslateScreen.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with SingleTickerProviderStateMixin {
  final TranslationService _service = TranslationService.instance;
  final MLKitTranslationService _mlKitService = MLKitTranslationService.instance;
  final TextEditingController _inputController = TextEditingController();

  String _sourceLang = 'vi';
  String _targetLang = 'en';
  String _translatedText = '';
  bool _isLoading = false;
  bool _isInlineListening = false;
  String? _errorMessage;
  String? _scannedImagePath;

  late AnimationController _swapAnimController;

  @override
  void initState() {
    super.initState();
    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _service.addListener(_onServiceUpdate);
    _mlKitService.addListener(_onServiceUpdate);
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _mlKitService.stopVoiceTranslation();
    _service.removeListener(_onServiceUpdate);
    _mlKitService.removeListener(_onServiceUpdate);
    _swapAnimController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  /// 1. Dịch text bằng Google ML Kit (7đ)
  Future<void> _doTranslate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _translatedText = '';
        _errorMessage = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _mlKitService.translateText(
        text: text,
        fromCode: _sourceLang,
        toCode: _targetLang,
      );
      if (mounted) {
        setState(() {
          _translatedText = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi dịch thuật: $e';
        });
      }
    }
  }

  /// Nhấn nói trực tiếp vào ô văn bản (9đ)
  Future<void> _toggleInlineSpeech() async {
    if (_isInlineListening) {
      await _mlKitService.stopVoiceTranslation();
      setState(() {
        _isInlineListening = false;
      });
      return;
    }

    setState(() {
      _isInlineListening = true;
      _errorMessage = null;
    });

    await _mlKitService.startVoiceTranslation(
      fromCode: _sourceLang,
      onResult: (recognized, isFinal) {
        if (mounted) {
          setState(() {
            _inputController.text = recognized;
            if (isFinal) {
              _isInlineListening = false;
            }
          });
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isInlineListening = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi micro: $err'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  /// 2. Lấy text và dịch từ giọng nói STT (9đ)
  /// Luồng: Nhấn nói -> Nhận diện text -> Người dùng bấm nút để dịch
  void _startVoiceTranslation() {
    String currentSpeech = _inputController.text.trim();
    bool isListening = true;
    void Function(void Function())? updateModal;

    void startListening() {
      _mlKitService.startVoiceTranslation(
        fromCode: _sourceLang,
        onResult: (words, isFinal) {
          currentSpeech = words;
          if (isFinal) isListening = false;
          updateModal?.call(() {});
        },
        onError: (err) {
          isListening = false;
          updateModal?.call(() {});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi micro: $err'), backgroundColor: Colors.red),
            );
          }
        },
      );
    }

    startListening();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            updateModal = setModalState;
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
            final fromLangObj = _service.getLanguage(_sourceLang);
            final toLangObj = _service.getLanguage(_targetLang);

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.purple.withAlpha(isDark ? 50 : 25),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mic, color: Colors.purple, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Dịch giọng nói (9đ)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[300] ?? Colors.purple,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${fromLangObj.flag} ${fromLangObj.name} ➔ ${toLangObj.flag} ${toLangObj.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '1. Nhấn nói vào micro  ➔  2. Kiểm tra văn bản  ➔  3. Bấm để dịch',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Nút Micro tròn
                    GestureDetector(
                      onTap: () async {
                        if (isListening) {
                          await _mlKitService.stopVoiceTranslation();
                          setModalState(() {
                            isListening = false;
                          });
                        } else {
                          setModalState(() {
                            isListening = true;
                          });
                          startListening();
                        }
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? Colors.purple.withAlpha(35)
                              : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          border: Border.all(
                            color: isListening ? Colors.purple : Colors.grey,
                            width: 3,
                          ),
                          boxShadow: isListening
                              ? [
                                  BoxShadow(
                                    color: Colors.purple.withAlpha(90),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          color: isListening ? Colors.purple : Colors.grey[600],
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isListening
                          ? '🎙 Đang lắng nghe... Hãy nói câu của bạn'
                          : (currentSpeech.isNotEmpty
                              ? '✓ Đã ghi nhận lời nói. Bấm nút dưới để dịch!'
                              : 'Bấm micro để bắt đầu nói'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isListening ? Colors.purple : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Khung văn bản nhận diện được
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 75, maxHeight: 150),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: currentSpeech.isNotEmpty
                              ? Colors.purple.withAlpha(120)
                              : (isDark ? Colors.white12 : Colors.black12),
                          width: currentSpeech.isNotEmpty ? 1.5 : 1.0,
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          currentSpeech.isNotEmpty
                              ? currentSpeech
                              : 'Lời nói của bạn sẽ xuất hiện tại đây...',
                          style: TextStyle(
                            fontSize: 15,
                            color: currentSpeech.isNotEmpty
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nút bấm: "Bấm để dịch ngay"
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.translate, size: 20),
                        label: const Text(
                          'Bấm để dịch ngay (9đ)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        onPressed: currentSpeech.trim().isEmpty
                            ? null
                            : () async {
                                await _mlKitService.stopVoiceTranslation();
                                if (modalCtx.mounted) Navigator.pop(modalCtx);
                                if (mounted) {
                                  setState(() {
                                    _inputController.text = currentSpeech.trim();
                                  });
                                  await _doTranslate();
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Nút phụ: Chèn vào ô & Đóng
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('Chèn vào ô & Sửa'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: currentSpeech.trim().isEmpty
                                ? null
                                : () async {
                                    await _mlKitService.stopVoiceTranslation();
                                    if (modalCtx.mounted) Navigator.pop(modalCtx);
                                    if (mounted) {
                                      setState(() {
                                        _inputController.text = currentSpeech.trim();
                                      });
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await _mlKitService.stopVoiceTranslation();
                            if (modalCtx.mounted) Navigator.pop(modalCtx);
                          },
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _mlKitService.stopVoiceTranslation();
    });
  }

  /// 3. Dịch từ ảnh chụp (Camera / Gallery OCR - 10đ)
  Future<void> _pickAndTranslateImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _mlKitService.recognizeAndTranslateImage(
        source: source,
        fromCode: _sourceLang,
        toCode: _targetLang,
      );

      if (result != null && mounted) {
        setState(() {
          _scannedImagePath = result['imagePath'];
          _inputController.text = result['originalText'] ?? '';
          _translatedText = result['translatedText'] ?? '';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Đã nhận diện chữ và dịch thành công từ ảnh!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  /// 4. Mở Camera dịch Realtime (Điểm cộng!)
  void _openRealtimeCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RealtimeCameraTranslateScreen(
          sourceLang: _sourceLang,
          targetLang: _targetLang,
        ),
      ),
    );
  }

  void _swapLanguages() {
    _swapAnimController.forward(from: 0.0);
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;

      if (_translatedText.isNotEmpty) {
        _inputController.text = _translatedText;
        _translatedText = '';
      }
    });
    if (_inputController.text.isNotEmpty) {
      _doTranslate();
    }
  }

  void _selectLanguage({required bool isSource}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _LanguagePickerSheet(
          currentCode: isSource ? _sourceLang : _targetLang,
          title: isSource ? 'Chọn ngôn ngữ gốc' : 'Chọn ngôn ngữ dịch sang',
          onSelected: (code) {
            Navigator.pop(ctx);
            setState(() {
              if (isSource) {
                if (code == _targetLang) {
                  _targetLang = _sourceLang;
                }
                _sourceLang = code;
              } else {
                if (code == _sourceLang) {
                  _sourceLang = _targetLang;
                }
                _targetLang = code;
              }
            });
            if (_inputController.text.isNotEmpty) {
              _doTranslate();
            }
          },
        );
      },
    );
  }

  void _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      _inputController.text = data.text!;
      setState(() {});
      _doTranslate();
    }
  }

  void _copyToClipboard(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Đã sao chép bản dịch vào bộ nhớ tạm!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sourceLangObj = _service.getLanguage(_sourceLang);
    final targetLangObj = _service.getLanguage(_targetLang);

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
              child: Icon(Icons.g_translate, color: theme.colorScheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Google ML Kit Translate',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ML Kit Mode Indicator Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.primary.withAlpha(50)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tích hợp Google ML Kit: Dịch Text (7đ) • Giọng nói (9đ) • Ảnh OCR (10đ) • Camera Realtime (Điểm cộng)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Language Selector Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 25 : 8),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Source Language Button
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectLanguage(isSource: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(sourceLangObj.flag, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                sourceLangObj.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Swap Button
                  RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(_swapAnimController),
                    child: IconButton(
                      tooltip: 'Đổi ngôn ngữ ⇄',
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withAlpha(isDark ? 50 : 25),
                        foregroundColor: theme.colorScheme.primary,
                      ),
                      onPressed: _swapLanguages,
                      icon: const Icon(Icons.swap_horiz, size: 22),
                    ),
                  ),

                  // Target Language Button
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _selectLanguage(isSource: false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(targetLangObj.flag, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                targetLangObj.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Smart Multi-Modal Action Toolbar (Voice, Camera OCR, Gallery, Realtime)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Voice Translate Button (9đ)
                  ActionChip(
                    avatar: const Icon(Icons.mic, color: Colors.purple, size: 18),
                    label: const Text('Giọng nói (9đ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    backgroundColor: Colors.purple.withAlpha(isDark ? 50 : 25),
                    onPressed: _startVoiceTranslation,
                  ),
                  const SizedBox(width: 8),

                  // Camera OCR Translate (10đ)
                  ActionChip(
                    avatar: const Icon(Icons.camera_alt, color: Colors.blue, size: 18),
                    label: const Text('Chụp ảnh OCR (10đ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    backgroundColor: Colors.blue.withAlpha(isDark ? 50 : 25),
                    onPressed: () => _pickAndTranslateImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 8),

                  // Gallery OCR Translate (10đ)
                  ActionChip(
                    avatar: const Icon(Icons.photo_library, color: Colors.teal, size: 18),
                    label: const Text('Thư viện ảnh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    backgroundColor: Colors.teal.withAlpha(isDark ? 50 : 25),
                    onPressed: () => _pickAndTranslateImage(ImageSource.gallery),
                  ),
                  const SizedBox(width: 8),

                  // Bonus: Realtime Live Camera Translation
                  ActionChip(
                    avatar: const Icon(Icons.videocam, color: Colors.deepOrange, size: 18),
                    label: const Text('⚡ Camera Realtime (Điểm cộng)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.deepOrange)),
                    backgroundColor: Colors.deepOrange.withAlpha(isDark ? 50 : 25),
                    onPressed: _openRealtimeCamera,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Source Input Card
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 30 : 10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Scanned image thumbnail if OCR was used
                  if (_scannedImagePath != null)
                    Container(
                      height: 110,
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withAlpha(80)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Image.file(
                              File(_scannedImagePath!),
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            color: Colors.black45,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: const Row(
                              children: [
                                Icon(Icons.document_scanner, color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Văn bản trích xuất từ ảnh (OCR)',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 18),
                              onPressed: () {
                                setState(() {
                                  _scannedImagePath = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${sourceLangObj.flag} ${sourceLangObj.name} (Văn bản gốc)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isInlineListening ? Icons.mic : Icons.mic_none,
                                color: _isInlineListening ? Colors.redAccent : Colors.purple,
                                size: 20,
                              ),
                              tooltip: _isInlineListening
                                  ? 'Đang nghe... Bấm để dừng'
                                  : 'Nhấn nói trực tiếp vào ô nhập (9đ)',
                              onPressed: _toggleInlineSpeech,
                            ),
                            if (_inputController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                tooltip: 'Xóa nội dung',
                                onPressed: () {
                                  _inputController.clear();
                                  setState(() {
                                    _translatedText = '';
                                    _errorMessage = null;
                                    _scannedImagePath = null;
                                  });
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.content_paste, size: 20),
                              tooltip: 'Dán từ clipboard',
                              onPressed: _pasteFromClipboard,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_isInlineListening)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.withAlpha(80)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.mic, color: Colors.purple, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đang lắng nghe... Nói xong bấm mic hoặc bấm "Dịch ngay (7đ)"',
                              style: TextStyle(color: Colors.purple, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      controller: _inputController,
                      maxLines: 4,
                      minLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _doTranslate(),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Nhập text (7đ), bấm mic nói (9đ), hoặc chụp ảnh (10đ)...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_inputController.text.length} ký tự',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _doTranslate,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.translate, size: 18),
                          label: Text(_isLoading ? 'Đang dịch...' : 'Dịch ngay (7đ)'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Error Display if any
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Translation Output Card
            if (_translatedText.isNotEmpty || _isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(isDark ? 40 : 25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(targetLangObj.flag, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Text(
                              targetLangObj.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Sao chép kết quả',
                          onPressed: () => _copyToClipboard(_translatedText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      SelectableText(
                        _translatedText,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Quick Phrases Section
            Row(
              children: [
                const Icon(Icons.flash_on, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Mẫu câu thông dụng',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TranslationService.quickPhrases.map((phrase) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: Text(
                        phrase.category == 'Chào hỏi'
                            ? '👋'
                            : phrase.category == 'Du lịch'
                                ? '✈️'
                                : phrase.category == 'Ăn uống'
                                    ? '🍽️'
                                    : '💬',
                        style: const TextStyle(fontSize: 14),
                      ),
                      label: Text(
                        phrase.text,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        _inputController.text = phrase.text;
                        _sourceLang = 'vi';
                        _targetLang = 'en';
                        _doTranslate();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // Translation History
            if (_service.history.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Lịch sử bản dịch gần đây',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Xóa hết', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      _service.clearHistory();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...List.generate(
                _service.history.length > 5 ? 5 : _service.history.length,
                (index) {
                  final item = _service.history[index];
                  final fromLang = _service.getLanguage(item.fromLangCode);
                  final toLang = _service.getLanguage(item.toLangCode);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.translate, size: 16, color: theme.colorScheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              _inputController.text = item.sourceText;
                              _sourceLang = item.fromLangCode;
                              _targetLang = item.toLangCode;
                              setState(() {
                                _translatedText = item.translatedText;
                              });
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text('${fromLang.flag} ${fromLang.name}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    const Text(' → ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text('${toLang.flag} ${toLang.name}',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.sourceText,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.translatedText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          tooltip: 'Sao chép',
                          onPressed: () => _copyToClipboard(item.translatedText),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                          tooltip: 'Xóa mục này',
                          onPressed: () => _service.removeHistoryItem(item.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LanguagePickerSheet extends StatefulWidget {
  final String currentCode;
  final String title;
  final ValueChanged<String> onSelected;

  const _LanguagePickerSheet({
    required this.currentCode,
    required this.title,
    required this.onSelected,
  });

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = TranslationService.supportedLanguages.where((lang) {
      final q = _searchQuery.toLowerCase();
      return lang.name.toLowerCase().contains(q) ||
          lang.code.toLowerCase().contains(q);
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm ngôn ngữ...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected = item.code == widget.currentCode;

                    return ListTile(
                      leading: Text(item.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : null,
                        ),
                      ),
                      subtitle: Text(item.code.toUpperCase(), style: const TextStyle(fontSize: 11)),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => widget.onSelected(item.code),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
