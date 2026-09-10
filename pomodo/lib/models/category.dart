import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final String color; // 十六进制，如 '#008779'
  final String? icon;
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'icon': icon,
      'sort_order': sortOrder,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      color: (map['color'] as String?) ?? '#008779',
      icon: map['icon'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? color,
    String? icon,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Color get uiColor {
    try {
      final hex = color.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF008779); // 默认马尔斯绿
  }
}
