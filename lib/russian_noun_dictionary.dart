import 'dart:math';

import 'package:russian_words/russian_words.dart' as russian_words;

class RussianNounDictionary {
  RussianNounDictionary._();

  static const _commonWordLimit = 1000;

  static final List<String> _rankedNouns = () {
    final seenNouns = <String>{};
    final nouns = <String>[];

    for (final rawNoun in russian_words.nouns) {
      final noun = normalize(rawNoun);
      if (seenNouns.add(noun)) {
        nouns.add(noun);
      }
    }

    return List<String>.unmodifiable(nouns);
  }();

  static final Set<String> _nouns = _rankedNouns.toSet();
  static final Map<int, List<String>> _nounsByLength = _groupByLength(
    _rankedNouns,
  );
  static final Map<int, List<String>> _commonNounsByLength = _groupByLength(
    _rankedNouns.take(_commonWordLimit),
  );

  static bool contains(String word) => _nouns.contains(normalize(word));

  static List<String> wordsOfLength(int length) =>
      List.unmodifiable(_nounsByLength[length] ?? const []);

  static List<String> commonWordsOfLength(int length) =>
      List.unmodifiable(_commonNounsByLength[length] ?? const []);

  static String pickWord({
    required int length,
    required Set<String> excludedWords,
    required Random random,
  }) {
    final excluded = excludedWords.map(normalize).toSet();
    final commonCandidates = _withoutExcluded(
      commonWordsOfLength(length),
      excluded,
    );
    final candidates = commonCandidates.isNotEmpty
        ? commonCandidates
        : _withoutExcluded(wordsOfLength(length), excluded);

    if (candidates.isEmpty) {
      throw StateError(
        'No dictionary nouns available for the requested length.',
      );
    }

    return candidates[random.nextInt(candidates.length)];
  }

  static Map<int, List<String>> _groupByLength(Iterable<String> nouns) {
    final nounsByLength = <int, List<String>>{};
    for (final noun in nouns) {
      (nounsByLength[noun.length] ??= []).add(noun);
    }
    return nounsByLength;
  }

  static List<String> _withoutExcluded(
    List<String> words,
    Set<String> excludedWords,
  ) => words.where((word) => !excludedWords.contains(word)).toList();

  static String normalize(String word) =>
      word.trim().toUpperCase().replaceAll('Ё', 'Е');
}
