import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_manager/core/error/exceptions.dart';

void main() {
  group('ServerException', () {
    test('stores message correctly', () {
      final exception = ServerException(message: 'Server error');

      expect(exception.message, 'Server error');
    });

    test('toString contains message', () {
      final exception = ServerException(message: 'Something went wrong');

      expect(exception.toString(), contains('Something went wrong'));
    });
  });
}
