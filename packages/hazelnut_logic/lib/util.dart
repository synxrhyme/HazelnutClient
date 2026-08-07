import "dart:convert";
import 'package:characters/characters.dart';
import 'package:flutter/painting.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

String sanitizeRawInput(
  String? input, {
  int maxLength = 2000,
  bool forDisplay = false,
}) {
  if (input == null) return '';

  var sanitized = input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
  sanitized = sanitized.trim();

  // Zeichenbegrenzung (unicode-safe)
  if (sanitized.characters.length > maxLength) {
    sanitized = sanitized.characters.take(maxLength).toString();
  }

  if (forDisplay) {
    sanitized = const HtmlEscape().convert(sanitized);
  }

  return sanitized;
}

int stableHash(String input) {
  int hash = 0;
  for (int i = 0; i < input.length; i++) {
    hash = (hash * 31 + input.codeUnitAt(i)) & 0x7fffffff;
  }
  return hash;
}

Color getAccentFromString(String input) {
  final hash = stableHash(input);
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.7, 0.6).toColor();
}

String generateUniqueMessageId(DateTime timestamp) {
  return Uuid().v7(config: V7Options(timestamp.millisecondsSinceEpoch, null)).toString();
}