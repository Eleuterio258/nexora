import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AulaEntity extends Equatable {
  const AulaEntity({
    required this.subject,
    required this.teacher,
    required this.activity,
    required this.time,
    required this.icon,
    required this.color,
    required this.weekday,
  });

  final String subject;
  final String teacher;
  final String activity;
  final String time;
  final IconData icon;
  final Color color;
  final int weekday;

  @override
  List<Object> get props => [subject, teacher, activity, time, icon, color, weekday];
}
