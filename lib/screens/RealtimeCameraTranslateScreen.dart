import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/mlkit_translation_service.dart';
import '../services/translation_service.dart';

class RealtimeCameraTranslateScreen extends StatefulWidget {
  final String sourceLang;
  final String targetLang;

  const RealtimeCameraTranslateScreen({
    super.key,
    this.sourceLang = 'en',
    this.targetLang = 'vi',
  });

  @override
  State<RealtimeCameraTranslateScreen> createState() =>
      _RealtimeCameraTranslateScreenState();
}

class _RealtimeCameraTranslateScreenState
    extends State<RealtimeCameraTranslateScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  bool _isScanningActive = true;
  Timer? _scanTimer;

  String _detectedText = '';
  String _translatedText = '';
  late String _fromLang;
  late String _toLang;

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  void initState() {
    super.initState();
    _fromLang = widget.sourceLang;
    _toLang = widget.targetLang;
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras!.first,
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraReady = true;
          });
          _startPeriodicScan();
        }
      } else {
        if (mounted) {
          setState(() {
            _detectedText = 'Không tìm thấy camera trên thiết bị này.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _detectedText = 'Lỗi khởi động camera: $e';
        });
      }
    }
  }

  void _startPeriodicScan() {
    _scanTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (!_isScanningActive ||
          _isProcessingFrame ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return;
      }

      _isProcessingFrame = true;
      try {
        final XFile photo = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(photo.path);
        final RecognizedText recognizedText =
            await _textRecognizer.processImage(inputImage);

        final text = recognizedText.text.trim();
        if (text.isNotEmpty && mounted) {
          final translated =
              await MLKitTranslationService.instance.translateText(
            text: text,
            fromCode: _fromLang,
            toCode: _toLang,
          );
          if (mounted) {
            setState(() {
              _detectedText = text;
              _translatedText = translated;
            });
          }
        }
      } catch (e) {
        debugPrint('Realtime scan error: $e');
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fromLangObj = TranslationService.instance.getLanguage(_fromLang);
    final toLangObj = TranslationService.instance.getLanguage(_toLang);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withAlpha(180),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text(
              'Dịch Realtime Camera (Điểm cộng)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isScanningActive ? 'Tạm dừng quét' : 'Tiếp tục quét',
            icon: Icon(
              _isScanningActive ? Icons.pause_circle : Icons.play_circle,
              color: _isScanningActive ? Colors.greenAccent : Colors.amber,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isScanningActive = !_isScanningActive;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraReady && _cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.amber),
                    const SizedBox(height: 16),
                    Text(
                      _detectedText.isNotEmpty
                          ? _detectedText
                          : 'Đang mở Camera quét thời gian thực...',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Viewfinder Target Frame
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isProcessingFrame ? Colors.amber : Colors.white.withAlpha(150),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _isScanningActive
                                ? (_isProcessingFrame
                                    ? '⚡ Đang quét OCR...'
                                    : '👀 Đang nhận diện...')
                                : '⏸️ Đã tạm dừng',
                            style: TextStyle(
                              color: _isScanningActive
                                  ? Colors.greenAccent
                                  : Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${fromLangObj.flag} → ${toLangObj.flag}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Hướng camera vào dòng chữ cần dịch',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Bottom Translation HUD
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withAlpha(230),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo.withAlpha(120), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'KẾT QUẢ DỊCH THỜI GIAN THỰC (REALTIME)',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                        tooltip: 'Đổi chiều dịch',
                        onPressed: () {
                          setState(() {
                            final tmp = _fromLang;
                            _fromLang = _toLang;
                            _toLang = tmp;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Detected original text
                  if (_detectedText.isNotEmpty)
                    Text(
                      'Gốc: $_detectedText',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),

                  // Translated text
                  Text(
                    _translatedText.isNotEmpty
                        ? _translatedText
                        : 'Đang chờ phát hiện văn bản từ camera...',
                    style: TextStyle(
                      color: _translatedText.isNotEmpty
                          ? Colors.white
                          : Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
