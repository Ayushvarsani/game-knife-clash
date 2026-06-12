import 'package:flutter/material.dart';

class GameConstants {
  // Screen
  static const double boardRadius = 120.0;
  static const double knifeWidth = 11.0;
  static const double knifeHeight = 94.0;
  static const double appleRadius = 18.0;

  // Physics
  static const double knifeSpeed = 1200.0;
  static const double knifeMinSpeed = 700.0; // knife decelerates to this, never stops mid-air
  static const double minAngleBetweenKnives = 0.26; // radians — wider gap = easier for casual play
  // Radius (from board center) at which a stuck knife's CENTER (the guard, i.e.
  // the blade/handle boundary) sits. The knife only draws a short blade stub +
  // guard + handle + pommel (no full blade), and the centre is placed just
  // inside the rim so the stub enters the wood and the handle protrudes outward
  // — the knife reads as stuck INTO the board, not floating on top of it.
  static const double stuckKnifeRadius = boardRadius - 5;
  // The flying knife sticks the instant its center reaches this radius, which is
  // the same point the stuck knife will occupy — so there is no visual jump.
  static const double knifeBoardHitRadius = stuckKnifeRadius;

  // Colors
  static const Color backgroundColor = Color(0xFF1C0709);
  static const Color boardColor = Color(0xFFc8a96e);
  static const Color boardRimColor = Color(0xFF8B6914);
  static const Color knifeColor = Color(0xFFe0e0e0);
  static const Color knifeHandleColor = Color(0xFFc0392b);
  static const Color appleColor = Color(0xFFe74c3c);
  static const Color appleLeafColor = Color(0xFF2ecc71);
  static const Color bossboardColor = Color(0xFF8B0000);
  static const Color scoreColor = Color(0xFFf39c12);
  static const Color stageColor = Color(0xFFf39c12);
}
