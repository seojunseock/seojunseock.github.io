/// Parses Korean numeral words typed on a keyboard still switched to Hangul
/// input, so the receptionist never has to flip to an English/number layout
/// mid-entry. Supports both Sino-Korean digits (오, 십, 백...) and native
/// Korean number words (하나, 열, 스물...), plus plain digit strings.
library;

const Map<String, int> _sinoDigit = {
  '영': 0,
  '일': 1,
  '이': 2,
  '삼': 3,
  '사': 4,
  '오': 5,
  '육': 6,
  '륙': 6,
  '칠': 7,
  '팔': 8,
  '구': 9,
};

const Map<String, int> _sinoUnit = {'십': 10, '백': 100, '천': 1000};

const Map<String, int> _nativeOnes = {
  '하나': 1,
  '한': 1,
  '둘': 2,
  '두': 2,
  '셋': 3,
  '세': 3,
  '넷': 4,
  '네': 4,
  '다섯': 5,
  '여섯': 6,
  '일곱': 7,
  '여덟': 8,
  '아홉': 9,
};

const Map<String, int> _nativeTens = {
  '열': 10,
  '스물': 20,
  '서른': 30,
  '마흔': 40,
  '쉰': 50,
  '예순': 60,
  '일흔': 70,
  '여든': 80,
  '아흔': 90,
};

int? _parseSino(String str) {
  int total = 0;
  int current = 0;
  bool matched = false;
  for (final ch in str.split('')) {
    final digit = _sinoDigit[ch];
    final unit = _sinoUnit[ch];
    if (digit != null) {
      current = digit;
      matched = true;
    } else if (unit != null) {
      total += (current == 0 ? 1 : current) * unit;
      current = 0;
      matched = true;
    } else {
      return null;
    }
  }
  return matched ? total + current : null;
}

int? _parseNative(String str) {
  final tens = _nativeTens[str];
  if (tens != null) return tens;
  final ones = _nativeOnes[str];
  if (ones != null) return ones;
  for (final entry in _nativeTens.entries) {
    if (str.startsWith(entry.key)) {
      final rest = str.substring(entry.key.length);
      if (rest.isEmpty) return entry.value;
      final restOnes = _nativeOnes[rest];
      if (restOnes != null) return entry.value + restOnes;
    }
  }
  return null;
}

/// Parses a Korean numeral word or a plain digit string into an integer.
/// Returns null if [input] cannot be parsed as either.
int? parseKoreanOrNumber(String input) {
  final str = input.trim();
  if (str.isEmpty) return null;
  if (RegExp(r'^\d+$').hasMatch(str)) return int.parse(str);
  if (str == '영' || str == '공') return 0;
  final native = _parseNative(str);
  if (native != null) return native;
  return _parseSino(str);
}

/// Strips a known trailing unit word (checked longest-first) then parses the
/// remainder as a Korean numeral or digit string. An empty field resolves to
/// 0 (the receptionist skipped it), matching the quick-entry flow.
int? resolveNumberField(String raw, List<String> units) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 0;
  var s = trimmed;
  for (final unit in units) {
    if (s.endsWith(unit)) {
      s = s.substring(0, s.length - unit.length).trim();
      break;
    }
  }
  return parseKoreanOrNumber(s);
}

int? resolveAmount(String raw) => resolveNumberField(raw, ['만원', '만', '원']);

int? resolveTickets(String raw) => resolveNumberField(raw, ['장']);

/// Formats a 만원-unit amount as "15만원", with thousands separators for
/// amounts of 1,000만원 or more.
String manwonLabel(int manwon) {
  final digits = manwon.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final sign = manwon < 0 ? '-' : '';
  return '$sign${buffer.toString()}만원';
}
