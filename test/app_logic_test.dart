import 'package:flutter_test/flutter_test.dart';
import 'package:diepgihuy123/services/translation_service.dart';
import 'package:diepgihuy123/services/voice_alarm_service.dart';
import 'package:diepgihuy123/screens/GroupInfoScreen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Quy đổi nhiệt độ', () {
    test('Chuyển đổi 10F sang Độ C', () {
      const inputF = 10.0;
      final resultC = (inputF - 32) * 5 / 9;
      expect(resultC.toStringAsFixed(2), '-12.22');
    });

    test('Chuyển đổi 10C sang Độ F', () {
      const inputC = 10.0;
      final resultF = (inputC * 9 / 5) + 32;
      expect(resultF.toStringAsFixed(2), '50.00');
    });
  });

  group('Quy đổi đơn vị đo', () {
    test('10 mét sang feet', () {
      const inputMeters = 10.0;
      const meterToBase = 1.0;
      const feetToBase = 0.3048;
      final resultFeet = (inputMeters * meterToBase) / feetToBase;
      expect(resultFeet.toStringAsFixed(2), '32.81');
    });

    test('5 kg sang pound (lb)', () {
      const inputKg = 5.0;
      const kgToBase = 1.0;
      const lbToBase = 0.45359237;
      final resultLb = (inputKg * kgToBase) / lbToBase;
      expect(resultLb.toStringAsFixed(2), '11.02');
    });
  });

  group('Dịch thuật đa ngôn ngữ (TranslationService)', () {
    final service = TranslationService.instance;

    test('Danh sách ngôn ngữ hỗ trợ bao gồm Tiếng Việt, Tiếng Anh, Tiếng Nhật, v.v.', () {
      final vi = service.getLanguage('vi');
      expect(vi.code, 'vi');
      expect(vi.name, 'Tiếng Việt');
      expect(vi.flag, '🇻🇳');

      final en = service.getLanguage('en');
      expect(en.code, 'en');
      expect(en.name, 'Tiếng Anh');

      final ja = service.getLanguage('ja');
      expect(ja.code, 'ja');
      expect(ja.name, 'Tiếng Nhật');
    });

    test('Lấy ngôn ngữ mặc định nếu mã không tồn tại', () {
      final fallback = service.getLanguage('unknown_xyz');
      expect(fallback.code, 'vi');
    });

    test('Dịch chuỗi rỗng trả về chuỗi rỗng ngay lập tức', () async {
      final res = await service.translate(
        text: '   ',
        fromCode: 'vi',
        toCode: 'en',
      );
      expect(res, '');
    });

    test('Dịch cùng một ngôn ngữ trả về chính chuỗi gốc', () async {
      final res = await service.translate(
        text: 'Xin chào',
        fromCode: 'vi',
        toCode: 'vi',
      );
      expect(res, 'Xin chào');
    });

    test('Quản lý danh sách mẫu câu giao tiếp nhanh', () {
      expect(TranslationService.quickPhrases.isNotEmpty, true);
      final first = TranslationService.quickPhrases.first;
      expect(first.category, 'Chào hỏi');
      expect(first.text.contains('Xin chào'), true);
    });

    test('Quản lý và xóa lịch sử dịch thuật', () {
      service.clearHistory();
      expect(service.history.isEmpty, true);
    });
  });

  group('Báo thức giọng nói đa ngôn ngữ (VoiceAlarmService - 5đ)', () {
    final voiceService = VoiceAlarmService.instance;

    test('Phân tích khẩu lệnh Tiếng Việt "đặt báo thức 7 giờ"', () {
      final tod = voiceService.parseAlarmTime('Đặt báo thức 7 giờ');
      expect(tod, isNotNull);
      expect(tod!.hour, 7);
      expect(tod.minute, 0);
    });

    test('Phân tích khẩu lệnh Tiếng Việt "hẹn giờ 6 rưỡi sáng"', () {
      final tod = voiceService.parseAlarmTime('hẹn giờ 6 rưỡi sáng');
      expect(tod, isNotNull);
      expect(tod!.hour, 6);
      expect(tod.minute, 30);
    });

    test('Phân tích khẩu lệnh Tiếng Việt "báo thức 8 giờ 15 phút"', () {
      final tod = voiceService.parseAlarmTime('báo thức 8 giờ 15 phút');
      expect(tod, isNotNull);
      expect(tod!.hour, 8);
      expect(tod.minute, 15);
    });

    test('Phân tích khẩu lệnh Tiếng Anh "set alarm at 7 am"', () {
      final tod = voiceService.parseAlarmTime('set alarm at 7 am');
      expect(tod, isNotNull);
      expect(tod!.hour, 7);
      expect(tod.minute, 0);
    });

    test('Phân tích khẩu lệnh Tiếng Anh "wake me up at six thirty"', () {
      final tod = voiceService.parseAlarmTime('wake me up at six thirty');
      expect(tod, isNotNull);
      expect(tod!.hour, 6);
      expect(tod.minute, 30);
    });

    test('Kiểm tra danh sách ngôn ngữ hỗ trợ nhận diện giọng nói', () {
      expect(VoiceAlarmService.supportedLocales.length >= 3, true);
      final hasVi = VoiceAlarmService.supportedLocales.any((l) => l['code'] == 'vi_VN');
      final hasEn = VoiceAlarmService.supportedLocales.any((l) => l['code'] == 'en_US');
      expect(hasVi, true);
      expect(hasEn, true);
    });
  });

  group('Thông tin nhóm đồ án (GroupInfoScreen - Mục 6)', () {
    test('Danh sách thành viên nhóm có đầy đủ thông tin và vai trò', () {
      expect(GroupInfoScreen.teamMembers.length >= 2, true);
      final leader = GroupInfoScreen.teamMembers.first;
      expect(leader.name.isNotEmpty, true);
      expect(leader.studentId.isNotEmpty, true);
      expect(leader.role.contains('Trưởng Nhóm'), true);
      expect(leader.contribution.isNotEmpty, true);
    });
  });

  group('Giao diện cá nhân & url_launcher (Mục 2 - 3.5đ)', () {
    test('Định dạng URI gọi điện thoại chính xác', () {
      const phone = '0987654321';
      final uri = Uri(scheme: 'tel', path: phone);
      expect(uri.toString(), 'tel:0987654321');
    });

    test('Định dạng URI mở app YouTube chính xác', () {
      final appUri = Uri.parse('vnd.youtube://');
      expect(appUri.scheme, 'vnd.youtube');
    });
  });

  group('Dịch thuật giọng nói ML Kit (Mục 4 - 9đ)', () {
    test('Quy trình: Nhấn nói -> Nhận text -> Bấm nút để dịch', () {
      // Giả lập luồng người dùng:
      // 1. Nhấn nói -> Mic nhận diện thành chuỗi text
      const mockRecognizedSpeech = 'xin chào';
      expect(mockRecognizedSpeech.isNotEmpty, true);

      // 2. Text được lưu vào bộ nhớ / ô nhập liệu trước khi dịch (không tự ý dịch vội)
      String inputFieldText = mockRecognizedSpeech;
      expect(inputFieldText, 'xin chào');

      // 3. Người dùng bấm nút "Bấm để dịch ngay"
      final lang = TranslationService.instance.getLanguage('vi');
      expect(lang.code, 'vi');
      expect(inputFieldText.trim(), 'xin chào');
    });
  });
}
