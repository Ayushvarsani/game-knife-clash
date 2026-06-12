import 'dart:math';
import 'package:flutter/material.dart';

enum BoardThemeId {
  classicWood,
  darkWood,
  ice,
  stone,
  gold,
  obsidian,
  cherry,
}

class BoardTheme {
  final BoardThemeId id;
  final Color rimColor;
  final List<Color> ringColors;
  final Color centerColor;
  final Color centerDotColor;
  final Color boltColor;
  final Color boltHighlight;
  final Color bladeColor;
  final Color bladeShine;
  final Color guardColor;
  final Color handleColor;
  final Color handleStripe;
  final Color pommelColor;

  const BoardTheme({
    required this.id,
    required this.rimColor,
    required this.ringColors,
    required this.centerColor,
    required this.centerDotColor,
    required this.boltColor,
    required this.boltHighlight,
    required this.bladeColor,
    required this.bladeShine,
    required this.guardColor,
    required this.handleColor,
    required this.handleStripe,
    required this.pommelColor,
  });

  static const classicWood = BoardTheme(
    id: BoardThemeId.classicWood,
    rimColor: Color(0xFF1A1018),
    ringColors: [Color(0xFF2A2030), Color(0xFF3A3040), Color(0xFF2A2030), Color(0xFF3A3040), Color(0xFF2A2030)],
    centerColor: Color(0xFF1E1420),
    centerDotColor: Color(0xFF4A3848),
    boltColor: Color(0xFF3A2838),
    boltHighlight: Color(0xFFFF5A2E),
    bladeColor: Color(0xFFB8C8D8),
    bladeShine: Colors.white,
    guardColor: Color(0xFFFF5A2E),
    handleColor: Color(0xFF1A1420),
    handleStripe: Color(0xFFFF3B30),
    pommelColor: Color(0xFFFF5A2E),
  );

  static const darkWood = BoardTheme(
    id: BoardThemeId.darkWood,
    rimColor: Color(0xFF0E0A10),
    ringColors: [Color(0xFF1A1420), Color(0xFF282030), Color(0xFF1A1420), Color(0xFF282030), Color(0xFF1A1420)],
    centerColor: Color(0xFF100C12),
    centerDotColor: Color(0xFF3A3040),
    boltColor: Color(0xFF2A2030),
    boltHighlight: Color(0xFFFF7043),
    bladeColor: Color(0xFFA0B0C0),
    bladeShine: Colors.white,
    guardColor: Color(0xFFFF7043),
    handleColor: Color(0xFF120E14),
    handleStripe: Color(0xFFE64A19),
    pommelColor: Color(0xFFFF7043),
  );

  static const ice = BoardTheme(
    id: BoardThemeId.ice,
    rimColor: Color(0xFF0A1420),
    ringColors: [Color(0xFF142838), Color(0xFF1E3850), Color(0xFF142838), Color(0xFF1E3850), Color(0xFF142838)],
    centerColor: Color(0xFF0C1828),
    centerDotColor: Color(0xFF3A5878),
    boltColor: Color(0xFF1A3048),
    boltHighlight: Color(0xFF40C4FF),
    bladeColor: Color(0xFFE0F4FF),
    bladeShine: Colors.white,
    guardColor: Color(0xFF40C4FF),
    handleColor: Color(0xFF0C1828),
    handleStripe: Color(0xFF0288D1),
    pommelColor: Color(0xFF40C4FF),
  );

  static const stone = BoardTheme(
    id: BoardThemeId.stone,
    rimColor: Color(0xFF141418),
    ringColors: [Color(0xFF282830), Color(0xFF383840), Color(0xFF282830), Color(0xFF383840), Color(0xFF282830)],
    centerColor: Color(0xFF1A1A20),
    centerDotColor: Color(0xFF585860),
    boltColor: Color(0xFF303038),
    boltHighlight: Color(0xFF90A4AE),
    bladeColor: Color(0xFFB0B8C0),
    bladeShine: Colors.white,
    guardColor: Color(0xFF90A4AE),
    handleColor: Color(0xFF1A1A20),
    handleStripe: Color(0xFF607D8B),
    pommelColor: Color(0xFF90A4AE),
  );

  static const gold = BoardTheme(
    id: BoardThemeId.gold,
    rimColor: Color(0xFF1A1408),
    ringColors: [Color(0xFF2A2010), Color(0xFF3A3020), Color(0xFF2A2010), Color(0xFF3A3020), Color(0xFF2A2010)],
    centerColor: Color(0xFF201808),
    centerDotColor: Color(0xFF6A5030),
    boltColor: Color(0xFF3A2810),
    boltHighlight: Color(0xFFFFD54F),
    bladeColor: Color(0xFFFFEE88),
    bladeShine: Colors.white,
    guardColor: Color(0xFFFFD54F),
    handleColor: Color(0xFF1A1408),
    handleStripe: Color(0xFFFF8F00),
    pommelColor: Color(0xFFFFD54F),
  );

  static const obsidian = BoardTheme(
    id: BoardThemeId.obsidian,
    rimColor: Color(0xFF0A0618),
    ringColors: [Color(0xFF1A0A2E), Color(0xFF2A1A40), Color(0xFF1A0A2E), Color(0xFF2A1A40), Color(0xFF1A0A2E)],
    centerColor: Color(0xFF100820),
    centerDotColor: Color(0xFF5533AA),
    boltColor: Color(0xFF2A1A40),
    boltHighlight: Color(0xFFB388FF),
    bladeColor: Color(0xFFCC99FF),
    bladeShine: Colors.white,
    guardColor: Color(0xFFB388FF),
    handleColor: Color(0xFF1A0A2E),
    handleStripe: Color(0xFF7C4DFF),
    pommelColor: Color(0xFFB388FF),
  );

  static const cherry = BoardTheme(
    id: BoardThemeId.cherry,
    rimColor: Color(0xFF180608),
    ringColors: [Color(0xFF2A1018), Color(0xFF3A1820), Color(0xFF2A1018), Color(0xFF3A1820), Color(0xFF2A1018)],
    centerColor: Color(0xFF200810),
    centerDotColor: Color(0xFF6A2030),
    boltColor: Color(0xFF3A1820),
    boltHighlight: Color(0xFFFF5252),
    bladeColor: Color(0xFFFFCCCC),
    bladeShine: Colors.white,
    guardColor: Color(0xFFFF5252),
    handleColor: Color(0xFF200810),
    handleStripe: Color(0xFFD32F2F),
    pommelColor: Color(0xFFFF5252),
  );

  static const bonus = BoardTheme(
    id: BoardThemeId.gold,
    rimColor: Color(0xFF2A1800),
    ringColors: [Color(0xFF3A2800), Color(0xFF4A3800), Color(0xFF3A2800), Color(0xFF4A3800), Color(0xFF3A2800)],
    centerColor: Color(0xFFFFB300),
    centerDotColor: Color(0xFFFFF9C4),
    boltColor: Color(0xFFE65100),
    boltHighlight: Color(0xFFFFD54F),
    bladeColor: Color(0xFFFFF9C4),
    bladeShine: Color(0xFFFFFFFF),
    guardColor: Color(0xFFFFD54F),
    handleColor: Color(0xFF3A0810),
    handleStripe: Color(0xFFFF8F00),
    pommelColor: Color(0xFFFFD54F),
  );

  static const List<BoardTheme> allNormal = [
    classicWood, darkWood, ice, stone, gold, obsidian, cherry,
  ];

  static BoardTheme random(Random rng) {
    return allNormal[rng.nextInt(allNormal.length)];
  }
}
