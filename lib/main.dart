import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'word_service.dart';

void main() {
  runApp(const BirdleApp());
}

class BirdleApp extends StatelessWidget {
  const BirdleApp({super.key, this.wordService});

  final WordService? wordService;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B5FEF),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Слово',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: const Color(0xFF17213B),
          displayColor: const Color(0xFF17213B),
        ),
      ),
      home: BirdleGame(wordService: wordService),
    );
  }
}

class BirdleGame extends StatefulWidget {
  const BirdleGame({super.key, this.wordService});

  final WordService? wordService;

  @override
  State<BirdleGame> createState() => _BirdleGameState();
}

class _BirdleGameState extends State<BirdleGame> {
  final List<String> _guesses = [];
  final Set<String> _usedWords = {};
  late final WordService _wordService;
  String _answer = '';
  String? _hint;
  String? _message;
  int _wordLength = 5;
  int _wordRequestId = 0;
  bool _isLoadingHint = false;
  bool _isLoadingWord = true;

  bool get _hasWon => _answer.isNotEmpty && _guesses.contains(_answer);
  int get _maximumGuesses => _wordLength + 1;
  bool get _isFinished =>
      _answer.isNotEmpty && (_hasWon || _guesses.length == _maximumGuesses);

  @override
  void initState() {
    super.initState();
    _wordService = widget.wordService ?? GroqWordService();
    _loadNewGame();
  }

  Future<void> _loadNewGame() async {
    final requestId = ++_wordRequestId;
    final requestedLength = _wordLength;
    final usedWordsWithSameLength = _usedWords
        .where((word) => word.length == requestedLength)
        .toSet();

    setState(() {
      _answer = '';
      _guesses.clear();
      _hint = null;
      _isLoadingHint = false;
      _isLoadingWord = true;
      _message = null;
    });

    try {
      final answer = await _wordService
          .generateWord(
            length: requestedLength,
            excludedWords: usedWordsWithSameLength,
          )
          .timeout(const Duration(seconds: 12));
      if (!mounted || requestId != _wordRequestId) {
        return;
      }
      setState(() {
        _answer = answer;
        _usedWords.add(answer);
        _isLoadingWord = false;
        _message = null;
      });
    } on Exception {
      if (!mounted || requestId != _wordRequestId) {
        return;
      }
      setState(() {
        _isLoadingWord = false;
        _message = 'Не удалось получить слово из словаря.';
      });
    }
  }

  void _changeWordLength(int length) {
    if (length < 3 || length > 10) {
      setState(() => _message = 'Введите длину слова от 3 до 10 букв.');
      return;
    }

    if (length == _wordLength) {
      return;
    }

    setState(() => _wordLength = length);
    _loadNewGame();
  }

  Future<void> _requestHint() async {
    if (_answer.isEmpty || _isLoadingHint) {
      return;
    }

    final answer = _answer;
    setState(() => _isLoadingHint = true);

    try {
      final hint = await _wordService.generateHint(answer);
      if (!mounted || answer != _answer) {
        return;
      }
      setState(() {
        _hint = hint;
        _isLoadingHint = false;
      });
    } on Exception {
      if (!mounted || answer != _answer) {
        return;
      }
      setState(() {
        _isLoadingHint = false;
        _message = 'Не удалось получить облачную подсказку.';
      });
    }
  }

  void _submitGuess(String value) {
    final guess = value.trim().toUpperCase();

    if (_isFinished || _isLoadingWord) {
      return;
    }

    if (!RegExp('^[А-ЯЁ]{$_wordLength}\$').hasMatch(guess)) {
      setState(() => _message = 'Введите русское слово из $_wordLength букв.');
      return;
    }

    final hasWon = guess == _answer;
    setState(() {
      _guesses.add(guess);
      _message = hasWon
          ? null
          : _isFinished
          ? 'Ответ: $_answer'
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2F3FF), Color(0xFFF8FBFF), Color(0xFFEAF8F5)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact =
                  constraints.maxWidth < 420 || constraints.maxHeight < 700;
              final horizontalPadding = constraints.maxWidth < 380
                  ? 12.0
                  : 20.0;
              final verticalGap = compact ? 10.0 : 16.0;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      compact ? 10 : 16,
                      horizontalPadding,
                      compact ? 12 : 20,
                    ),
                    child: Column(
                      children: [
                        _Header(
                          compact: compact,
                          wordLength: _wordLength,
                          onLengthChanged: _changeWordLength,
                        ),
                        SizedBox(height: verticalGap),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(compact ? 6 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.76),
                              borderRadius: BorderRadius.circular(
                                compact ? 20 : 28,
                              ),
                              border: Border.all(color: Colors.white),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x160F1B45),
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: GameBoard(
                              guesses: _guesses,
                              answer: _answer,
                              wordLength: _wordLength,
                              maximumGuesses: _maximumGuesses,
                            ),
                          ),
                        ),
                        SizedBox(height: verticalGap),
                        _InputPanel(
                          compact: compact,
                          message: _message,
                          hint: _hint,
                          isLoadingHint: _isLoadingHint,
                          showHintButton:
                              !_isLoadingWord &&
                              _answer.isNotEmpty &&
                              !_isFinished,
                          onRequestHint: _requestHint,
                          input: GuessInput(
                            key: ValueKey(_wordLength),
                            enabled:
                                !_isFinished &&
                                !_isLoadingWord &&
                                _answer.isNotEmpty,
                            wordLength: _wordLength,
                            onSubmitGuess: _submitGuess,
                          ),
                        ),
                        if (_isFinished || (!_isLoadingWord && _answer.isEmpty))
                          Padding(
                            padding: EdgeInsets.only(top: compact ? 8 : 12),
                            child: FilledButton.icon(
                              onPressed: _loadNewGame,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(
                                _isFinished ? 'Играть ещё' : 'Повторить',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatefulWidget {
  const _Header({
    required this.compact,
    required this.wordLength,
    required this.onLengthChanged,
  });

  final bool compact;
  final int wordLength;
  final ValueChanged<int> onLengthChanged;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.wordLength.toDouble();
  }

  @override
  void didUpdateWidget(covariant _Header oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wordLength != widget.wordLength) {
      _sliderValue = widget.wordLength.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconSize = widget.compact ? 40.0 : 48.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(widget.compact ? 13 : 16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x405B5FEF),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white),
            ),
            SizedBox(width: widget.compact ? 8 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WORDLE',
                    style:
                        (widget.compact
                                ? theme.textTheme.titleLarge
                                : theme.textTheme.headlineSmall)
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 8 : 12,
                vertical: widget.compact ? 6 : 7,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEBECFF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${_sliderValue.round()} БУКВ',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Semantics(
          label: 'Длина слова: ${_sliderValue.round()} букв',
          child: Slider(
            key: const ValueKey('word-length-slider'),
            value: _sliderValue,
            min: 3,
            max: 10,
            divisions: 7,
            label: '${_sliderValue.round()} букв',
            onChanged: (value) => setState(() => _sliderValue = value),
            onChangeEnd: (value) => widget.onLengthChanged(value.round()),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text('3'), Text('10')],
          ),
        ),
      ],
    );
  }
}

class _InputPanel extends StatelessWidget {
  const _InputPanel({
    required this.compact,
    required this.input,
    required this.message,
    required this.hint,
    required this.isLoadingHint,
    required this.showHintButton,
    required this.onRequestHint,
  });

  final bool compact;
  final Widget input;
  final String? message;
  final String? hint;
  final bool isLoadingHint;
  final bool showHintButton;
  final VoidCallback onRequestHint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F1B45),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: input),
              if (showHintButton) ...[
                SizedBox(width: compact ? 6 : 8),
                Tooltip(
                  message: 'Подсказка',
                  child: SizedBox(
                    width: compact ? 44 : 48,
                    height: compact ? 44 : 48,
                    child: OutlinedButton(
                      onPressed: hint == null && !isLoadingHint
                          ? onRequestHint
                          : null,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: isLoadingHint
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('💡', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (hint != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6D8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '💡 $hint',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF66521B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class GameBoard extends StatelessWidget {
  const GameBoard({
    super.key,
    required this.guesses,
    required this.answer,
    required this.wordLength,
    required this.maximumGuesses,
  });

  final List<String> guesses;
  final String answer;
  final int wordLength;
  final int maximumGuesses;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSide = math.min(
          constraints.maxWidth / wordLength,
          constraints.maxHeight / maximumGuesses,
        );
        final tilePadding = math.max(1.0, math.min(3.0, tileSide * 0.08));

        return Center(
          child: SizedBox(
            width: tileSide * wordLength,
            height: tileSide * maximumGuesses,
            child: Column(
              children: List.generate(maximumGuesses, (rowIndex) {
                final guess = rowIndex < guesses.length
                    ? guesses[rowIndex]
                    : '';
                final states = answer.isEmpty || guess.isEmpty
                    ? List.filled(wordLength, TileState.empty)
                    : _evaluateGuess(guess, answer);

                return SizedBox(
                  height: tileSide,
                  child: Row(
                    children: List.generate(wordLength, (columnIndex) {
                      final letter = columnIndex < guess.length
                          ? guess[columnIndex]
                          : '';
                      return SizedBox(
                        width: tileSide,
                        child: Padding(
                          padding: EdgeInsets.all(tilePadding),
                          child: LetterTile(
                            letter: letter,
                            state: states[columnIndex],
                            tileSide: tileSide,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

List<TileState> _evaluateGuess(String guess, String answer) {
  final result = List.filled(answer.length, TileState.absent);
  final availableLetters = answer.split('');

  for (var index = 0; index < answer.length; index++) {
    if (guess[index] == answer[index]) {
      result[index] = TileState.correct;
      availableLetters[index] = '';
    }
  }

  for (var index = 0; index < answer.length; index++) {
    if (result[index] == TileState.correct) {
      continue;
    }

    final availableIndex = availableLetters.indexOf(guess[index]);
    if (availableIndex != -1) {
      result[index] = TileState.present;
      availableLetters[availableIndex] = '';
    }
  }

  return result;
}

enum TileState { empty, absent, present, correct }

class LetterTile extends StatelessWidget {
  const LetterTile({
    super.key,
    required this.letter,
    required this.state,
    required this.tileSide,
  });

  final String letter;
  final TileState state;
  final double tileSide;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (state) {
      TileState.empty => const Color(0xFFF1F4F9),
      TileState.absent => const Color(0xFF798396),
      TileState.present => const Color(0xFFE9A93A),
      TileState.correct => const Color(0xFF43A781),
    };
    final borderColor = state == TileState.empty
        ? const Color(0xFFD5DCE8)
        : backgroundColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: tileSide < 30 ? 1 : 2),
        borderRadius: BorderRadius.circular(math.min(12, tileSide * 0.24)),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            letter,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: state == TileState.empty
                  ? const Color(0xFF17213B)
                  : Colors.white,
              fontSize: tileSide * 0.54,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class GuessInput extends StatefulWidget {
  const GuessInput({
    super.key,
    required this.onSubmitGuess,
    required this.enabled,
    required this.wordLength,
  });

  final ValueChanged<String> onSubmitGuess;
  final bool enabled;
  final int wordLength;

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!widget.enabled) {
      return;
    }

    widget.onSubmitGuess(_controller.text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('guess-input'),
            controller: _controller,
            focusNode: _focusNode,
            autofocus: true,
            enabled: widget.enabled,
            maxLength: widget.wordLength,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[а-яА-ЯёЁ]')),
              LengthLimitingTextInputFormatter(widget.wordLength),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Введите слово',
              filled: true,
              fillColor: const Color(0xFFF4F6FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Проверить',
          onPressed: widget.enabled ? _submit : null,
          icon: const Icon(Icons.arrow_upward_rounded),
        ),
      ],
    );
  }
}
