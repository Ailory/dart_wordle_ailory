import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dart_wordle/main.dart';
import 'package:dart_wordle/word_service.dart';

void main() {
  testWidgets('changes the word length and accepts a matching guess', (
    tester,
  ) async {
    await tester.pumpWidget(BirdleApp(wordService: FixedWordService()));
    await tester.pump();

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('word-length-slider')),
    );
    slider.onChangeEnd!(4);
    await tester.pumpAndSettle();

    expect(find.text('4 БУКВ'), findsOneWidget);
    expect(find.byType(LetterTile), findsNWidgets(20));

    await tester.tap(find.byTooltip('Подсказка'));
    await tester.pump();

    expect(find.text('💡 Тёплое время года.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('guess-input')), 'лето');
    await tester.tap(find.byTooltip('Проверить'));
    await tester.pumpAndSettle();

    expect(tester.widget<GameBoard>(find.byType(GameBoard)).guesses, ['ЛЕТО']);
    expect(tester.widget<GuessInput>(find.byType(GuessInput)).enabled, isFalse);
    expect(find.text('Играть ещё'), findsOneWidget);
    expect(find.byKey(const ValueKey('praise-card')), findsNothing);

    await tester.tap(find.text('Играть ещё'));
    await tester.pumpAndSettle();

    expect(tester.widget<GameBoard>(find.byType(GameBoard)).guesses, isEmpty);
    expect(tester.widget<GuessInput>(find.byType(GuessInput)).enabled, isTrue);
  });

  testWidgets('fits a compact phone viewport without layout errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BirdleApp(wordService: FixedWordService()));
    await tester.pump();

    expect(find.byType(GameBoard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class FixedWordService implements WordService {
  @override
  Future<String> generateWord({
    required int length,
    Set<String> excludedWords = const {},
  }) async => switch (length) {
    4 => 'ЛЕТО',
    5 => 'ВОРОН',
    6 => 'КОРАБЛ',
    _ => throw ArgumentError.value(length),
  };

  @override
  Future<String> generateHint(String word) async => 'Тёплое время года.';
}
