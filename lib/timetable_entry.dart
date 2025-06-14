import 'package:flutter/material.dart';

enum AttendancePolicy { mandatory, flexible, skip }

class TimetableEntry {
  final String id;
  final String subjectName;
  final String classroom;
  final int dayOfWeek;
  final int period;
  final Color color;
  final bool isCancelled;
  final AttendancePolicy initialPolicy;

  TimetableEntry({
    required this.id,
    required this.subjectName,
    required this.classroom,
    required this.dayOfWeek,
    required this.period,
    this.isCancelled = false,
    this.color = Colors.white,
    this.initialPolicy = AttendancePolicy.flexible,
  });
}
