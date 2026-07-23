import 'package:flutter/material.dart';

class BookingTimeValidator {
  static const currentTimeMessage =
      'No puedes agendar o reprogramar una cita en la hora actual o en una hora pasada.';
  static const businessHoursMessage =
      'El horario de atención es de 08:00 a 12:00 y de 14:00 a 18:00.\nPor favor selecciona una hora dentro de estos rangos.';

  static String? validate({
    required DateTime date,
    required TimeOfDay time,
    DateTime? now,
  }) {
    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final currentTime = now ?? DateTime.now();

    if (!_isWithinBusinessHours(time)) {
      return businessHoursMessage;
    }

    if (_isCurrentOrPastTimeSlot(selectedDateTime, currentTime)) {
      return currentTimeMessage;
    }

    return null;
  }

  static bool _isCurrentOrPastTimeSlot(
    DateTime selectedDateTime,
    DateTime currentTime,
  ) {
    if (!selectedDateTime.isAfter(currentTime)) {
      return true;
    }

    return false;
  }

  static bool _isWithinBusinessHours(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    const morningStart = 8 * 60;
    const morningEnd = 12 * 60;
    const afternoonStart = 14 * 60;
    const afternoonEnd = 18 * 60;

    return (minutes >= morningStart && minutes < morningEnd) ||
        (minutes >= afternoonStart && minutes < afternoonEnd);
  }
}
