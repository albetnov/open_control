import 'package:flutter_test/flutter_test.dart';
import 'package:open_control/data/managers/discovery_manager.dart';

void main() {
  group('pickHostAddress', () {
    test('prefers an IPv4 address among a mixed list', () {
      final result = pickHostAddress(['fe80::1', '192.168.1.10']);
      expect(result, '192.168.1.10');
    });

    test('brackets a lone IPv6 address', () {
      final result = pickHostAddress(['fe80::1']);
      expect(result, '[fe80::1]');
    });

    test('returns null for an empty list', () {
      final result = pickHostAddress([]);
      expect(result, isNull);
    });
  });
}
