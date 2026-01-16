import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Son kullanılan renkler yöneticisi (max 12)
class RecentColorsNotifier extends StateNotifier<List<Color>> {
  RecentColorsNotifier() : super([]);

  /// Maksimum renk sayısı
  static const int maxColors = 12;

  /// Yeni renk ekle (başa ekler, duplicate varsa önce kaldırır)
  void addColor(Color color) {
    // Aynı renk varsa kaldır (RGB bazlı karşılaştırma)
    final filtered = state
        .where((c) =>
            c.red != color.red ||
            c.green != color.green ||
            c.blue != color.blue)
        .toList();

    // Başa ekle ve max sayıya göre kes
    state = [color, ...filtered].take(maxColors).toList();
  }

  /// Belirli bir rengi kaldır
  void removeColor(Color color) {
    state = state
        .where((c) =>
            c.red != color.red ||
            c.green != color.green ||
            c.blue != color.blue)
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
