import 'package:flutter_test/flutter_test.dart';
import 'package:open_control/core/utils.dart';

void main() {
  group('formatFileSize', () {
    test('shows bytes without a decimal', () {
      expect(formatFileSize(512), '512 B');
    });

    test('converts to KB with one decimal', () {
      expect(formatFileSize(2048), '2.0 KB');
    });

    test('converts to MB', () {
      expect(formatFileSize(5 * 1024 * 1024), '5.0 MB');
    });

    test('caps at TB for very large sizes', () {
      expect(formatFileSize(1024 * 1024 * 1024 * 1024 * 1024), '1024.0 TB');
    });
  });
}
