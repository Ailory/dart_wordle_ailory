import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:dart_wordle/russian_noun_dictionary.dart';

void main() {
  test('rejects invented words and normalizes ё', () {
    expect(RussianNounDictionary.contains('заяц'), isTrue);
    expect(RussianNounDictionary.contains('зайць'), isFalse);
    expect(
      RussianNounDictionary.normalize('ёжик'),
      RussianNounDictionary.normalize('ежик'),
    );
    expect(RussianNounDictionary.wordsOfLength(4), contains('ЗАЯЦ'));
  });

  test('prioritizes common words when selecting an answer', () {
    final commonWords = RussianNounDictionary.commonWordsOfLength(3);

    expect(commonWords, containsAll(<String>['ДОМ', 'ЛЕС']));
    expect(commonWords, isNot(contains('ДЕК')));

    final excluded = commonWords.toSet()..remove('ДОМ');
    expect(
      RussianNounDictionary.pickWord(
        length: 3,
        excludedWords: excluded,
        random: Random(1),
      ),
      'ДОМ',
    );
  });
}
