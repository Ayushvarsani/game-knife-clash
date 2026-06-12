import 'dart:math';
import 'package:flutter/material.dart';

/// Random fruit bonus pickups on the reactor rim.
enum CollectibleType {
  apple,
  orange,
  grape,
  watermelon,
  banana,
  cherry,
  strawberry,
  lemon,
}

extension CollectibleTypeX on CollectibleType {
  static CollectibleType random(Random rng) =>
      CollectibleType.values[rng.nextInt(CollectibleType.values.length)];

  Color get primary {
    switch (this) {
      case CollectibleType.apple:
        return const Color(0xFFE82020);
      case CollectibleType.orange:
        return const Color(0xFFFF8F00);
      case CollectibleType.grape:
        return const Color(0xFF9B59B6);
      case CollectibleType.watermelon:
        return const Color(0xFF2ECC71);
      case CollectibleType.banana:
        return const Color(0xFFFFD54F);
      case CollectibleType.cherry:
        return const Color(0xFFE91E63);
      case CollectibleType.strawberry:
        return const Color(0xFFFF3B5C);
      case CollectibleType.lemon:
        return const Color(0xFFFFF176);
    }
  }

  Color get secondary {
    switch (this) {
      case CollectibleType.apple:
        return const Color(0xFFB50000);
      case CollectibleType.orange:
        return const Color(0xFFE65100);
      case CollectibleType.grape:
        return const Color(0xFF6A1B9A);
      case CollectibleType.watermelon:
        return const Color(0xFF1B8A4A);
      case CollectibleType.banana:
        return const Color(0xFFFFB300);
      case CollectibleType.cherry:
        return const Color(0xFFC2185B);
      case CollectibleType.strawberry:
        return const Color(0xFFD32F2F);
      case CollectibleType.lemon:
        return const Color(0xFFFBC02D);
    }
  }

  Color get leafColor => const Color(0xFF2ECC40);
}
