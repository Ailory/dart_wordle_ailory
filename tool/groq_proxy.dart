import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _host = '127.0.0.1';
const _port = 11435;
const _groqEndpoint = 'https://api.groq.com/openai/v1/chat/completions';
const _model = 'qwen/qwen3.8-27b';
const _systemPrompt =
    'Дай одну короткую, намеренно расплывчатую смысловую подсказку для '
    'русского слова из игры Wordle. Укажи только общий контекст, назначение '
    'или ассоциацию: подсказка должна давать направление, но не быть точным '
    'определением. Не называй слово, его формы, однокоренные слова и не '
    'объясняй правила игры.';

Future<void> main() async {
  final apiKey = Platform.environment['GROQ_API_KEY'];
  if (apiKey == null || apiKey.trim().isEmpty) {
    stderr.writeln('Set GROQ_API_KEY before starting the proxy.');
    exitCode = 64;
    return;
  }

  final server = await HttpServer.bind(_host, _port);
  stdout.writeln('Groq hint proxy is running at http://$_host:$_port');

  await for (final request in server) {
    unawaited(_handleRequest(request, apiKey));
  }
}

Future<void> _handleRequest(HttpRequest request, String apiKey) async {
  final origin = request.headers.value('origin');
  if (!_isAllowedOrigin(origin)) {
    await _writeJson(request.response, HttpStatus.forbidden, {
      'error': 'Origin is not allowed.',
    });
    return;
  }

  _addCorsHeaders(request.response, origin);
  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  if (request.method != 'POST' || request.uri.path != '/hint') {
    await _writeJson(request.response, HttpStatus.notFound, {
      'error': 'Route not found.',
    });
    return;
  }

  try {
    final body = await utf8.decoder.bind(request).join();
    final payload = jsonDecode(body) as Map<String, dynamic>;
    final word = (payload['word'] as String? ?? '').trim().toUpperCase();
    if (!RegExp(r'^[А-ЯЁ]{3,10}$').hasMatch(word)) {
      throw const FormatException('Invalid word.');
    }

    final hint = await _requestHint(word, apiKey);
    await _writeJson(request.response, HttpStatus.ok, {'hint': hint}, origin);
  } on FormatException {
    await _writeJson(request.response, HttpStatus.badRequest, {
      'error': 'Invalid request.',
    }, origin);
  } on TimeoutException {
    await _writeJson(request.response, HttpStatus.gatewayTimeout, {
      'error': 'Groq request timed out.',
    }, origin);
  } catch (_) {
    await _writeJson(request.response, HttpStatus.badGateway, {
      'error': 'Unable to create a hint.',
    }, origin);
  }
}

Future<String> _requestHint(String word, String apiKey) async {
  final response = await http
      .post(
        Uri.parse(_groqEndpoint),
        headers: {
          HttpHeaders.authorizationHeader: 'Bearer $apiKey',
          HttpHeaders.contentTypeHeader: 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'reasoning_effort': 'none',
          'temperature': 0.5,
          'max_completion_tokens': 48,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': 'Слово: $word'},
          ],
        }),
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('Groq returned ${response.statusCode}.');
  }

  final payload = jsonDecode(response.body) as Map<String, dynamic>;
  final choices = payload['choices'] as List<dynamic>?;
  final firstChoice = choices?.firstOrNull as Map<String, dynamic>?;
  final message = firstChoice?['message'] as Map<String, dynamic>?;
  final hint = (message?['content'] as String? ?? '').trim();
  if (hint.isEmpty || hint.toUpperCase().contains(word)) {
    throw const FormatException('Invalid hint.');
  }

  return hint;
}

bool _isAllowedOrigin(String? origin) {
  if (origin == null) {
    return true;
  }

  final uri = Uri.tryParse(origin);
  return uri != null &&
      uri.port == 8081 &&
      (uri.host == 'localhost' || uri.host == '127.0.0.1');
}

void _addCorsHeaders(HttpResponse response, String? origin) {
  if (origin == null) {
    return;
  }

  response.headers
    ..set(HttpHeaders.accessControlAllowOriginHeader, origin)
    ..set(HttpHeaders.accessControlAllowMethodsHeader, 'POST, OPTIONS')
    ..set(HttpHeaders.accessControlAllowHeadersHeader, 'Content-Type');
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, String> payload, [
  String? origin,
]) async {
  _addCorsHeaders(response, origin);
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(payload));
  await response.close();
}
