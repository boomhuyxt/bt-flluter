import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/alarm_service.dart';
import '../services/voice_alarm_service.dart';

class AlarmClockScreen extends StatefulWidget {
  final bool isEmbedded;
  const AlarmClockScreen({super.key, this.isEmbedded = false});

  @override
  State<AlarmClockScreen> createState() => _AlarmClockScreenState();
}

class _AlarmClockScreenState extends State<AlarmClockScreen> {
  final AlarmService _alarmService = AlarmService.instance;
  final VoiceAlarmService _voiceAlarmService = VoiceAlarmService.instance;
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
    _alarmService.addListener(_onAlarmServiceUpdate);
    _voiceAlarmService.addListener(_onAlarmServiceUpdate);
  }

  void _onAlarmServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _alarmService.removeListener(_onAlarmServiceUpdate);
    _voiceAlarmService.removeListener(_onAlarmServiceUpdate);
    super.dispose();
  }

  Future<void> _pickAndAddAlarm() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final labelController = TextEditingController(text: 'Báo thức');
      await showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Tên báo thức'),
            content: TextField(
              controller: labelController,
              decoration: const InputDecoration(
                hintText: 'Nhập nhãn (VD: Đi làm, Uống thuốc)',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () {
                  _alarmService.addAlarm(pickedTime, label: labelController.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('Lưu'),
              ),
            ],
          );
        },
      );
    }
  }

  void _addQuickAlarm(int minutes) {
    final target = DateTime.now().add(Duration(minutes: minutes));
    final tod = TimeOfDay(hour: target.hour, minute: target.minute);
    _alarmService.addAlarm(tod, label: 'Hẹn sau $minutes phút');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã hẹn giờ báo thức lúc ${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 3. Đặt giờ báo thức bằng giọng nói đa ngôn ngữ (STT - 5đ)
  void _openVoiceAlarmDialog() {
    bool isModalOpen = true;
    TimeOfDay? detectedTime;
    String liveSpeech = '';
    void Function(void Function())? updateModal;
    BuildContext? activeModalCtx;

    void safeCloseModal() {
      if (isModalOpen) {
        isModalOpen = false;
        _voiceAlarmService.stopListening();
        if (activeModalCtx != null && activeModalCtx!.mounted && Navigator.canPop(activeModalCtx!)) {
          Navigator.pop(activeModalCtx!);
        }
      }
    }

    void startListeningFlow() {
      _voiceAlarmService.startListening(
        onLiveUpdate: (words, time) {
          liveSpeech = words;
          if (time != null) detectedTime = time;
          updateModal?.call(() {});
        },
        onResult: (result) {
          if (!mounted) return;
          if (result.success) {
            safeCloseModal();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(child: Text(result.message)),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (result.message.isNotEmpty && isModalOpen) {
            updateModal?.call(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.message),
                backgroundColor: Colors.orange[800],
              ),
            );
          }
        },
      );
    }

    startListeningFlow();

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        activeModalCtx = modalCtx;
        return StatefulBuilder(
          builder: (context, setModalState) {
            updateModal = setModalState;
            final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
            final isListening = _voiceAlarmService.isListening;
            final currentLocale = _voiceAlarmService.currentLocaleId;

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
                          child: const Row(
                            children: [
                              Icon(Icons.alarm, color: Colors.purple, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Báo thức giọng nói đa ngôn ngữ (5đ)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Nói giờ bạn muốn hẹn vào micro (VD: "Đặt báo thức 7 giờ", "Wake me up at 6:30")',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),

                    // Language selector chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: VoiceAlarmService.supportedLocales.map((loc) {
                          final isSelected = loc['code'] == currentLocale;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text('${loc['flag']} ${loc['name']}'),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) {
                                  _voiceAlarmService.setLocale(loc['code']!);
                                  startListeningFlow();
                                  setModalState(() {});
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Mic Avatar Pulse
                    GestureDetector(
                      onTap: () {
                        if (isListening) {
                          _voiceAlarmService.stopListening();
                        } else {
                          startListeningFlow();
                        }
                        setModalState(() {});
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: isListening ? Colors.redAccent : Colors.purple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isListening ? Colors.red : Colors.purple).withAlpha(100),
                              blurRadius: isListening ? 20 : 10,
                              spreadRadius: isListening ? 4 : 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status Text
                    Text(
                      isListening
                          ? '🎙 Đang lắng nghe... Hãy nói giờ bạn muốn đặt!'
                          : 'Bấm vào micro để bắt đầu nói lại',
                      style: TextStyle(
                        color: isListening ? Colors.purple : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Speech Preview Box
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 50, maxHeight: 100),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: liveSpeech.isNotEmpty
                              ? Colors.purple.withAlpha(120)
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          liveSpeech.isNotEmpty
                              ? '"$liveSpeech"'
                              : (_voiceAlarmService.recognizedWords.isNotEmpty
                                  ? '"${_voiceAlarmService.recognizedWords}"'
                                  : 'Lời nói của bạn sẽ hiển thị tại đây...'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: liveSpeech.isNotEmpty || _voiceAlarmService.recognizedWords.isNotEmpty
                                ? Colors.purple
                                : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Detected Time Badge (if detected)
                    if (detectedTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.green, width: 1.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Nhận diện: ${detectedTime!.hour.toString().padLeft(2, '0')}:${detectedTime!.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Primary Action: "Bấm để đặt báo thức ngay"
                    if (detectedTime != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.alarm_add, size: 20),
                          label: Text(
                            'Đặt báo thức ${detectedTime!.hour.toString().padLeft(2, '0')}:${detectedTime!.minute.toString().padLeft(2, '0')} (5đ)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                          ),
                          onPressed: () {
                            _alarmService.addAlarm(
                              detectedTime!,
                              label: 'Báo thức giọng nói ($currentLocale)',
                            );
                            safeCloseModal();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đã đặt báo thức lúc ${detectedTime!.hour.toString().padLeft(2, '0')}:${detectedTime!.minute.toString().padLeft(2, '0')} thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: safeCloseModal,
                          child: const Text('Đóng'),
                        ),
                        if (isListening) ...[
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              _voiceAlarmService.stopListening();
                              setModalState(() {});
                            },
                            icon: const Icon(Icons.stop, size: 18),
                            label: const Text('Dừng nghe'),
                          ),
                        ],
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
      isModalOpen = false;
      _voiceAlarmService.stopListening();
    });
  }

  /// Mở ứng dụng đồng hồ thật (Android SET_ALARM intent)
  Future<void> _openNativeClock() async {
    final Uri alarmUri = Uri.parse('android.intent.action.SET_ALARM');
    try {
      if (await canLaunchUrl(alarmUri)) {
        await launchUrl(alarmUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đang sử dụng hệ thống chuông báo thức nội bộ của ứng dụng.'),
              backgroundColor: Colors.indigo,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hệ thống đang chạy báo thức độc lập trong ứng dụng.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final alarms = _alarmService.alarms;
    final isRinging = _alarmService.isRinging;
    final ringingAlarm = _alarmService.ringingAlarm;

    final hourStr = _currentTime.hour.toString().padLeft(2, '0');
    final minStr = _currentTime.minute.toString().padLeft(2, '0');
    final secStr = _currentTime.second.toString().padLeft(2, '0');

    return Scaffold(
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              title: const Text('Đồng hồ báo thức'),
              actions: [
                IconButton(
                  tooltip: 'Thử chuông báo thức',
                  icon: const Icon(Icons.volume_up),
                  onPressed: () {
                    _alarmService.testSound();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đang phát thử nghiệm âm thanh chuông báo thức...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          // Active Ringing Alarm Alert Banner
          if (isRinging)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.red,
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_on, color: Colors.white, size: 32),
                        SizedBox(width: 8),
                        Text(
                          'ĐANG REO CHUÔNG BÁO THỨC!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ringingAlarm?.formattedTime ?? ""} - ${ringingAlarm?.label ?? "Báo thức"}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => _alarmService.stopAlarm(),
                          icon: const Icon(Icons.stop),
                          label: const Text('Tắt chuông'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                          onPressed: () => _alarmService.snoozeAlarm(5),
                          icon: const Icon(Icons.snooze),
                          label: const Text('Báo lại (+5p)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Digital Clock Display Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? Colors.black : Colors.amber).withAlpha(50),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'THỜI GIAN HIỆN TẠI',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 2,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$hourStr:$minStr',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ':$secStr',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick add buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildQuickAlarmChip('+1p (Test)', 1),
                    _buildQuickAlarmChip('+5 phút', 5),
                    _buildQuickAlarmChip('+15 phút', 15),
                    _buildQuickAlarmChip('+30 phút', 30),
                  ],
                ),
              ],
            ),
          ),

          // Voice Alarm Action Banner (Speech-to-Text - 5đ)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withAlpha(60),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: Colors.purple, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo thức bằng giọng nói (5đ)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Đa ngôn ngữ: Tiếng Việt 🇻🇳, English 🇺🇸,...',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _openVoiceAlarmDialog,
                    child: const Text('Nói ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // List Alarms Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách báo thức (${alarms.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Đồng bộ sang đồng hồ thật (Android)',
                      icon: const Icon(Icons.sync, size: 20),
                      onPressed: _openNativeClock,
                    ),
                    TextButton.icon(
                      onPressed: _pickAndAddAlarm,
                      icon: const Icon(Icons.add_alarm, size: 18),
                      label: const Text('Thêm giờ'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Alarms List
          Expanded(
            child: alarms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alarm_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'Chưa có báo thức nào',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _pickAndAddAlarm,
                          icon: const Icon(Icons.add),
                          label: const Text('Đặt báo thức ngay'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: alarms.length,
                    itemBuilder: (context, index) {
                      final item = alarms[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          _alarmService.removeAlarm(item.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.isEnabled
                                  ? (isDark ? Colors.amber.withAlpha(80) : Colors.amber.withAlpha(120))
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: item.isEnabled ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: item.isEnabled ? Colors.amber.withAlpha(30) : Colors.grey.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.isEnabled ? Icons.alarm : Icons.alarm_off,
                                color: item.isEnabled ? Colors.amber[800] : Colors.grey,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              item.formattedTime,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: item.isEnabled ? null : Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              item.label,
                              style: TextStyle(
                                color: item.isEnabled ? (isDark ? Colors.grey[300] : Colors.grey[700]) : Colors.grey,
                              ),
                            ),
                            trailing: Switch(
                              value: item.isEnabled,
                              activeTrackColor: Colors.amber[800],
                              activeThumbColor: Colors.white,
                              onChanged: (val) {
                                _alarmService.toggleAlarm(item.id, val);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Đặt báo thức bằng giọng nói',
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        onPressed: _openVoiceAlarmDialog,
        child: const Icon(Icons.mic),
      ),
    );
  }

  Widget _buildQuickAlarmChip(String text, int minutes) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white)),
      backgroundColor: Colors.white.withAlpha(30),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: () => _addQuickAlarm(minutes),
    );
  }
}
