import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gift_calculator/main.dart';
import 'package:gift_calculator/utils/korean_numeral.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('opens directly into the calculator screen', (tester) async {
    await tester.pumpWidget(const GiftCalculatorApp());
    await tester.pumpAndSettle();

    expect(find.text('축의금 계산기'), findsOneWidget);
    expect(find.text('아직 접수된 내역이 없어요.'), findsOneWidget);
  });

  testWidgets('registering an entry adds it to the list with Korean numerals',
      (tester) async {
    await tester.pumpWidget(const GiftCalculatorApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, '이름'), '서준석');
    await tester.enterText(find.widgetWithText(TextField, '금액'), '십오');
    await tester.enterText(find.widgetWithText(TextField, '식권'), '3');
    await tester.tap(find.widgetWithText(ElevatedButton, '등록'));
    await tester.pumpAndSettle();

    expect(find.text('서준석'), findsOneWidget);
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('15만원')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byType(ListView), matching: find.text('3장')),
      findsOneWidget,
    );
  });

  test('parses Sino-Korean, native Korean, and plain digit numerals', () {
    expect(parseKoreanOrNumber('5'), 5);
    expect(parseKoreanOrNumber('오'), 5);
    expect(parseKoreanOrNumber('다섯'), 5);
    expect(parseKoreanOrNumber('십'), 10);
    expect(parseKoreanOrNumber('열'), 10);
    expect(parseKoreanOrNumber('십오'), 15);
    expect(parseKoreanOrNumber('삼십오'), 35);
    expect(parseKoreanOrNumber('스물다섯'), 25);
    expect(parseKoreanOrNumber(''), null);
    expect(parseKoreanOrNumber('참치'), null);
  });

  test('resolveAmount strips trailing unit words', () {
    expect(resolveAmount('5만원'), 5);
    expect(resolveAmount('50만'), 50);
    expect(resolveAmount('오만원'), 5);
    expect(resolveAmount(''), 0);
  });

  test('manwonLabel groups thousands', () {
    expect(manwonLabel(5), '5만원');
    expect(manwonLabel(1234), '1,234만원');
  });
}
