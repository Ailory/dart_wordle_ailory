import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'russian_noun_dictionary.dart';

abstract interface class WordService {
  Future<String> generateWord({
    required int length,
    Set<String> excludedWords = const {},
  });

  Future<String> generateHint(String word);
}

class GroqWordService implements WordService {
  GroqWordService({Random? random}) : _random = random ?? Random();

  static const _endpoint = String.fromEnvironment(
    'GROQ_PROXY_ENDPOINT',
    defaultValue: 'http://127.0.0.1:11435',
  );

  final Random _random;

  @override
  Future<String> generateWord({
    required int length,
    Set<String> excludedWords = const {},
  }) => Future.value(
    RussianNounDictionary.pickWord(
      length: length,
      excludedWords: excludedWords,
      random: _random,
    ),
  );

  @override
  Future<String> generateHint(String word) async {
    final response = await http
        .post(
          Uri.parse('$_endpoint/hint'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode({'word': word}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw const GroqException();
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final hint = decoded['hint'] as String? ?? '';
    final normalizedHint = hint.trim();

    if (normalizedHint.isEmpty ||
        normalizedHint.toUpperCase().contains(word.toUpperCase())) {
      throw const GroqException();
    }

    return normalizedHint;
  }
}

class GroqException implements Exception {
  const GroqException();
}
