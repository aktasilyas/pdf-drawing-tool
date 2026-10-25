import 'package:drawing_core/drawing_core.dart';
import 'package:test/test.dart';

void main() {
  group('StrokeDynamics', () {
    test('none has legacy defaults and isNone', () {
      expect(StrokeDynamics.none.taperStart, 0);
      expect(StrokeDynamics.none.taperEnd, 0);
      expect(StrokeDynamics.none.streamline, 0.5);
      expect(StrokeDynamics.none.velocityThinning, 0.2);
      expect(StrokeDynamics.none.isNone, isTrue);
    });

    test('isNone is false when any taper is set', () {
      expect(const StrokeDynamics(taperStart: 1).isNone, isFalse);
      expect(const StrokeDynamics(taperEnd: 1).isNone, isFalse);
    });

    test('equality by value', () {
      expect(
        const StrokeDynamics(taperStart: 1, taperEnd: 2),
        const StrokeDynamics(taperStart: 1, taperEnd: 2),
      );
      expect(
        const StrokeDynamics(taperStart: 1),
        isNot(const StrokeDynamics(taperStart: 2)),
      );
    });

    test('JSON round trip', () {
      const d = StrokeDynamics(
        taperStart: 1.5,
        taperEnd: 3,
        streamline: 0.45,
        velocityThinning: 0.25,
      );
      expect(StrokeDynamics.fromJson(d.toJson()), d);
    });

    test('missing or null JSON yields none', () {
      expect(StrokeDynamics.fromJson(null), StrokeDynamics.none);
      expect(StrokeDynamics.fromJson(const {}), StrokeDynamics.none);
    });

    test('copyWith replaces fields', () {
      final d = StrokeDynamics.none.copyWith(taperEnd: 4);
      expect(d.taperEnd, 4);
      expect(d.streamline, 0.5);
    });
  });

  group('StrokeStyle.dynamics', () {
    test('defaults to none', () {
      expect(StrokeStyle.pen().dynamics, StrokeDynamics.none);
    });

    test('is part of equality and copyWith', () {
      final a = StrokeStyle.pen();
      final b = a.copyWith(dynamics: const StrokeDynamics(taperEnd: 2));
      expect(b.dynamics.taperEnd, 2);
      expect(a, isNot(b));
      expect(b.copyWith(thickness: 3).dynamics.taperEnd, 2);
    });

    test('JSON omits dynamics key when none (legacy unchanged)', () {
      expect(StrokeStyle.pen().toJson().containsKey('dynamics'), isFalse);
    });

    test('JSON round trip keeps dynamics', () {
      final s = StrokeStyle.pen()
          .copyWith(dynamics: const StrokeDynamics(taperStart: 1, taperEnd: 2));
      final json = s.toJson();
      expect(json['dynamics'], isA<Map>());
      expect(StrokeStyle.fromJson(json), s);
    });

    test('legacy JSON without key loads as none', () {
      final json = StrokeStyle.pen().toJson();
      expect(StrokeStyle.fromJson(json).dynamics, StrokeDynamics.none);
    });
  });
}
