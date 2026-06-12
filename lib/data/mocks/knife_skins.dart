import 'package:flutter/material.dart';

class KnifeSkin {
  final String id;
  final String name;
  final String emoji;
  final Color bladeColor;
  final Color guardColor;
  final Color handleColor;
  final Color handleStripe;
  final Color pommelColor;
  /// Lifetime apples needed to unlock. 0 = unlocked by default.
  final int applesRequired;

  const KnifeSkin({
    required this.id,
    required this.name,
    required this.emoji,
    required this.bladeColor,
    required this.guardColor,
    required this.handleColor,
    required this.handleStripe,
    required this.pommelColor,
    this.applesRequired = 0,
  });
}

const List<KnifeSkin> kKnifeSkins = [
  KnifeSkin(
    id: 'default',
    name: 'Classic',
    emoji: '🔪',
    bladeColor: Color(0xFFDDDDDD),
    guardColor: Color(0xFFFFD700),
    handleColor: Color(0xFFE07020),
    handleStripe: Color(0xFFB85010),
    pommelColor: Color(0xFFFFD700),
    applesRequired: 0,
  ),
  KnifeSkin(
    id: 'ice',
    name: 'Ice Blade',
    emoji: '❄️',
    bladeColor: Color(0xFFE0F4FF),
    guardColor: Color(0xFF88CCFF),
    handleColor: Color(0xFF5588BB),
    handleStripe: Color(0xFF336699),
    pommelColor: Color(0xFFAADDFF),
    applesRequired: 10,
  ),
  KnifeSkin(
    id: 'gold',
    name: 'Golden',
    emoji: '✨',
    bladeColor: Color(0xFFFFEE88),
    guardColor: Color(0xFFFFCC00),
    handleColor: Color(0xFFAA7700),
    handleStripe: Color(0xFF886600),
    pommelColor: Color(0xFFFFCC00),
    applesRequired: 25,
  ),
  KnifeSkin(
    id: 'obsidian',
    name: 'Obsidian',
    emoji: '💜',
    bladeColor: Color(0xFFCC99FF),
    guardColor: Color(0xFF9966FF),
    handleColor: Color(0xFF2D1B5E),
    handleStripe: Color(0xFF9966FF),
    pommelColor: Color(0xFF9966FF),
    applesRequired: 50,
  ),
  KnifeSkin(
    id: 'cherry',
    name: 'Cherry',
    emoji: '🍒',
    bladeColor: Color(0xFFFFCCCC),
    guardColor: Color(0xFFFFAAAA),
    handleColor: Color(0xFF8B1A1A),
    handleStripe: Color(0xFF551111),
    pommelColor: Color(0xFFFFAAAA),
    applesRequired: 75,
  ),
];

KnifeSkin skinById(String id) =>
    kKnifeSkins.firstWhere((s) => s.id == id, orElse: () => kKnifeSkins.first);
