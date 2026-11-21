import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:air_sight/services/text_scale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TextScaleService Tests', () {
    test('Default scale is 1.0 (Normal)', () {
      expect(TextScaleService.currentScale, equals(TextScaleService.scaleNormal));
      expect(TextScaleService.textScaleNotifier.value, equals(1.0));
    });

    test('setTextScale updates value and notifies listeners', () async {
      await TextScaleService.setTextScale(TextScaleService.scaleLarge);
      expect(TextScaleService.currentScale, equals(1.2));
      expect(TextScaleService.textScaleNotifier.value, equals(1.2));

      await TextScaleService.setTextScale(TextScaleService.scaleNormal);
      expect(TextScaleService.currentScale, equals(1.0));
    });

    test('getScaleLabel returns formatted accessible labels', () {
      expect(TextScaleService.getScaleLabel(0.9), equals('Pequeño (0.9x)'));
      expect(TextScaleService.getScaleLabel(1.0), equals('Normal (1.0x)'));
      expect(TextScaleService.getScaleLabel(1.2), equals('Grande (1.2x)'));
      expect(TextScaleService.getScaleLabel(1.3), equals('Muy grande (1.3x)'));
    });

    test('init loads saved preference if available', () async {
      SharedPreferences.setMockInitialValues({'pref_app_text_scale': 1.3});
      await TextScaleService.init();
      expect(TextScaleService.currentScale, equals(1.3));

      // Reset to normal
      await TextScaleService.setTextScale(1.0);
    });
  });
}
