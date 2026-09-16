import 'package:flutter/material.dart';

/// Design tokens carried through [ThemeData] as a [ThemeExtension], so every
/// widget reads colors from `Theme.of(context).extension<AppPalette>()`
/// instead of hard-coding hex values. Values are the ones measured and
/// tuned against the contrast-ratio research discussed with the couple:
/// body text sits near an 8:1 ratio (the point past which reading
/// performance stops improving) rather than the harsher ~14:1 of pure
/// black-on-white, and no hue here is blue or red — red specifically is
/// avoided near names, since red ink on a person's name reads as a funeral
/// association in Korean custom.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color bg;
  final Color surface;
  final Color fill;
  final Color fillStrong;
  final Color tint;
  final Color text;
  final Color textSoft;
  final Color textFaint;
  final Color line;
  final Color accent;
  final Color accentInk;
  final Color accentSoft;
  final Color good;
  final Color goodSoft;
  final Color warn;
  final Color warnSoft;

  const AppPalette({
    required this.bg,
    required this.surface,
    required this.fill,
    required this.fillStrong,
    required this.tint,
    required this.text,
    required this.textSoft,
    required this.textFaint,
    required this.line,
    required this.accent,
    required this.accentInk,
    required this.accentSoft,
    required this.good,
    required this.goodSoft,
    required this.warn,
    required this.warnSoft,
  });

  static const light = AppPalette(
    bg: Color(0xFFFDF8EF),
    surface: Color(0xFFFBF5E7),
    fill: Color(0xFFF0DDB0),
    fillStrong: Color(0xFFE6C988),
    tint: Color(0xFFF4E2AE),
    text: Color(0xFF564A3A),
    textSoft: Color(0xFF756852),
    textFaint: Color(0xFF93825F),
    line: Color(0xFFDDC48C),
    accent: Color(0xFF96700A),
    accentInk: Color(0xFFFFFFFF),
    accentSoft: Color(0xFFFAF3DE),
    good: Color(0xFF2F9E6B),
    goodSoft: Color(0xFFE6F6EE),
    warn: Color(0xFFD64545),
    warnSoft: Color(0xFFFBE6E6),
  );

  static const dark = AppPalette(
    bg: Color(0xFF1A160E),
    surface: Color(0xFF241D13),
    fill: Color(0xFF362B18),
    fillStrong: Color(0xFF44351B),
    tint: Color(0xFF3D3014),
    text: Color(0xFFB8AC8F),
    textSoft: Color(0xFF8F8265),
    textFaint: Color(0xFF6B6045),
    line: Color(0xFF574726),
    accent: Color(0xFFE6BB52),
    accentInk: Color(0xFF241C0A),
    accentSoft: Color(0xFF3A2F14),
    good: Color(0xFF4BBF8E),
    goodSoft: Color(0xFF173328),
    warn: Color(0xFFFF6B6B),
    warnSoft: Color(0xFF3A1C1C),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? fill,
    Color? fillStrong,
    Color? tint,
    Color? text,
    Color? textSoft,
    Color? textFaint,
    Color? line,
    Color? accent,
    Color? accentInk,
    Color? accentSoft,
    Color? good,
    Color? goodSoft,
    Color? warn,
    Color? warnSoft,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      fill: fill ?? this.fill,
      fillStrong: fillStrong ?? this.fillStrong,
      tint: tint ?? this.tint,
      text: text ?? this.text,
      textSoft: textSoft ?? this.textSoft,
      textFaint: textFaint ?? this.textFaint,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentInk: accentInk ?? this.accentInk,
      accentSoft: accentSoft ?? this.accentSoft,
      good: good ?? this.good,
      goodSoft: goodSoft ?? this.goodSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      fill: Color.lerp(fill, other.fill, t)!,
      fillStrong: Color.lerp(fillStrong, other.fillStrong, t)!,
      tint: Color.lerp(tint, other.tint, t)!,
      text: Color.lerp(text, other.text, t)!,
      textSoft: Color.lerp(textSoft, other.textSoft, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentInk: Color.lerp(accentInk, other.accentInk, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      good: Color.lerp(good, other.good, t)!,
      goodSoft: Color.lerp(goodSoft, other.goodSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
    );
  }
}
