import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubePlayerScreen extends StatefulWidget {
  const YouTubePlayerScreen({super.key});

  @override
  State<YouTubePlayerScreen> createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
  );
  late YoutubePlayerController _playerController;
  String _currentVideoId = 'dQw4w9WgXcQ';
  String? _errorMessage;

  final List<Map<String, String>> _sampleVideos = [
    {
      'title': 'Never Gonna Give You Up',
      'id': 'dQw4w9WgXcQ',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'desc': 'Video âm nhạc kinh điển Rick Astley',
    },
    {
      'title': 'Lofi Hip Hop Radio',
      'id': 'jfKfPfyJRdk',
      'url': 'https://www.youtube.com/watch?v=jfKfPfyJRdk',
      'desc': 'Nhạc thư giãn học bài & làm việc',
    },
    {
      'title': 'Flutter in 100 Seconds',
      'id': 'lHhRhPV--G0',
      'url': 'https://www.youtube.com/watch?v=lHhRhPV--G0',
      'desc': 'Giới thiệu nhanh nền tảng Flutter',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initController(_currentVideoId);
  }

  void _initController(String videoId) {
    _playerController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
      ),
    );
  }

  String? _extractVideoId(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return null;

    if (clean.length == 11 && !clean.contains('/') && !clean.contains('?') && !clean.contains('&')) {
      return clean;
    }

    final regExp = RegExp(
      r'(?:https?:\/\/)?(?:www\.|m\.)?(?:youtube\.com\/(?:watch\?v=|shorts\/|embed\/|v\/)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(clean);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }
    return null;
  }

  void _playVideo(String videoId) {
    setState(() {
      _currentVideoId = videoId;
      _errorMessage = null;
    });
    _playerController.loadVideoById(videoId: videoId);
  }

  void _submitUrl() {
    final input = _urlController.text.trim();
    if (input.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập liên kết hoặc ID video YouTube');
      return;
    }

    final id = _extractVideoId(input);
    if (id == null) {
      setState(() {
        _errorMessage = 'Liên kết YouTube không hợp lệ. Ví dụ đúng: https://www.youtube.com/watch?v=dQw4w9WgXcQ';
      });
      return;
    }

    _playVideo(id);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      _urlController.text = data.text!;
      _submitUrl();
    }
  }

  @override
  void dispose() {
    _playerController.close();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xem Video YouTube'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // YouTube Player Component
            Container(
              color: Colors.black,
              child: YoutubePlayer(
                controller: _playerController,
                aspectRatio: 16 / 9,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error message banner
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
                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input Box
                  Text(
                    'Nhập liên kết video YouTube:',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'Dán link video (https://youtu.be/...)',
                            prefixIcon: const Icon(Icons.link, color: Colors.red),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _urlController.clear(),
                            ),
                          ),
                          onSubmitted: (_) => _submitUrl(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Dán từ bộ nhớ tạm',
                        onPressed: _pasteFromClipboard,
                        icon: const Icon(Icons.content_paste),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Load & Play Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _submitUrl,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Phát Video Này', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),

                  // Current video information card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.smart_display, color: Colors.red, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Thông tin phát',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(30),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'YouTube Player',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'ID Video hiện tại: $_currentVideoId',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hỗ trợ đầy đủ các dạng link: youtube.com/watch?v=..., youtu.be/..., link Shorts, hoặc nhập trực tiếp ID 11 ký tự.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Preset sample videos
                  Text(
                    'Video mẫu thử nghiệm nhanh (1 chạm):',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._sampleVideos.map((sample) {
                    final isPlaying = sample['id'] == _currentVideoId;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isPlaying ? Colors.red : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPlaying ? Colors.red : (isDark ? Colors.grey[800] : Colors.grey[200]),
                          foregroundColor: isPlaying ? Colors.white : Colors.red,
                          child: Icon(isPlaying ? Icons.play_arrow : Icons.videocam),
                        ),
                        title: Text(
                          sample['title']!,
                          style: TextStyle(
                            fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                            color: isPlaying ? Colors.red : null,
                          ),
                        ),
                        subtitle: Text(sample['desc']!),
                        trailing: isPlaying
                            ? const Chip(
                                label: Text('Đang phát', style: TextStyle(fontSize: 11, color: Colors.red)),
                                backgroundColor: Colors.transparent,
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          _urlController.text = sample['url']!;
                          _playVideo(sample['id']!);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
