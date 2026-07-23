import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/booking/booking_time_validator.dart';

void main() {
  test('accepts valid booking time inside business hours', () {
    final result = BookingTimeValidator.validate(
      date: DateTime(2026, 7, 23),
      time: const TimeOfDay(hour: 10, minute: 0),
      now: DateTime(2026, 7, 23, 8, 30),
    );

    expect(result, isNull);
  });

  test('allows next hour without one hour notice', () {
    final result = BookingTimeValidator.validate(
      date: DateTime(2026, 7, 23),
      time: const TimeOfDay(hour: 9, minute: 0),
      now: DateTime(2026, 7, 23, 8, 30),
    );

    expect(result, isNull);
  });

  test('allows future minutes in the current hour', () {
    final result = BookingTimeValidator.validate(
      date: DateTime(2026, 7, 23),
      time: const TimeOfDay(hour: 8, minute: 45),
      now: DateTime(2026, 7, 23, 8, 30),
    );

    expect(result, isNull);
  });

  test('rejects booking time in the current or past minute', () {
    final result = BookingTimeValidator.validate(
      date: DateTime(2026, 7, 23),
      time: const TimeOfDay(hour: 8, minute: 30),
      now: DateTime(2026, 7, 23, 8, 30),
    );

    expect(result, BookingTimeValidator.currentTimeMessage);
  });

  test('rejects past booking date', () {
    final result = BookingTimeValidator.validate(
      date: DateTime(2026, 7, 22),
      time: const TimeOfDay(hour: 10, minute: 0),
      now: DateTime(2026, 7, 23, 8, 30),
    );

    expect(result, BookingTimeValidator.currentTimeMessage);
  });

  test('rejects booking time outside business hours', () {
    final result = BookingTimeValidator.validate(
      date: DateTime(2026, 7, 24),
      time: const TimeOfDay(hour: 12, minute: 0),
      now: DateTime(2026, 7, 23, 8, 30),
    );

    expect(result, BookingTimeValidator.businessHoursMessage);
  });
}
