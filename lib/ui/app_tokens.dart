import 'package:flutter/material.dart';

/// Tokens sederhana biar spacing/radius konsisten di seluruh app.
class AppTokens {
  // Spacing scale
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s6 = 6;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s14 = 14;
  static const double s16 = 16;
  static const double s18 = 18;
  static const double s20 = 20;
  static const double s24 = 24;

  // Radius
  static const double r6 = 6;
  static const double r12 = 12;
  static const double r14 = 14;
  static const double r16 = 16;
  static const double r18 = 18;
  static const double r20 = 20;
  static const double r24 = 24;

  static BorderRadius radius(double r) => BorderRadius.circular(r);

  // Layout
  static const double maxChatBubbleWidth = 360;

  // Common paddings
  static const EdgeInsets pagePadding = EdgeInsets.all(s16);
  static const EdgeInsets listPadding = EdgeInsets.fromLTRB(s16, s12, s16, s16);
}
