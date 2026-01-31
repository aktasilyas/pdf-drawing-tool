import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Son kullanılan renkler yöneticisi (max 6)
class RecentColorsNotifier extends StateNotifier<List<Color>> {
  RecentColorsNotifier() : super([]);

  /// Maksimum renk sayısı
  static const int maxColors = 6;

  /// Yeni renk ekle (başa ekler, duplicate varsa önce kaldırır)
  void addColor(Color color) {
    // Aynı renk varsa kaldır (RGB bazlı karşılaştırma)
    final filtered = state
        .where((c) =>
            (c.r * 255.0).round().clamp(0, 255) != (color.r * 255.0).round().clamp(0, 255) ||
            (c.g * 255.0).round().clamp(0, 255) != (color.g * 255.0).round().clamp(0, 255) ||
            (c.b * 255.0).round().clamp(0, 255) != (color.b * 255.0).round().clamp(0, 255))
        .toList();

    // Başa ekle ve max sayıya göre kes
    state = [color, ...filtered].take(maxColors).toList();
  }

  /// Belirli bir rengi kaldır
  void removeColor(Color color) {
    state = state
        .where((c) =>
            (c.r * 255.0).round().clamp(0, 255) != (color.r * 255.0).round().clamp(0, 255) ||
            (c.g * 255.0).round().clamp(0, 255) != (color.g * 255.0).round().clamp(0, 255) ||
            (c.b * 255.0).round().clamp(0, 255) != (color.b * 255.0).round().clamp(0, 255))
        .toList();
  }

  /// Tüm renkleri temizle
  void clear() {
    state = [];
  }
}

/// Son kullanılan renkler provider'ı
final recentColorsProvider =
    StateNotifierProvider<RecentColorsNotifier, List<Color>>(
  (ref) => RecentColorsNotifier(),
);
