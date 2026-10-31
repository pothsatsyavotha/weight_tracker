import 'dart:convert';
import 'package:http/http.dart' as http;

import 'notion_exception.dart';

/// Shared config + helpers used by the read and write parts of the service.
abstract class NotionBase {
  static const _token = String.fromEnvironment('NOTION_TOKEN');
  static const _databaseId = String.fromEnvironment('NOTION_DATABASE_ID');
  static const _baseUrl = 'https://api.notion.com/v1';

  final http.Client client;
  NotionBase({http.Client? client}) : client = client ?? http.Client();

  String get baseUrl => _baseUrl;
  String get databaseId => _databaseId;

  Map<String, String> get headers => {
    'Authorization': 'Bearer $_token',
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
  };

  void checkConfig() {
    if (_token.isEmpty || _databaseId.isEmpty) {
      throw NotionException(
        'Missing Notion config. Run with --dart-define-from-file=env.json',
      );
    }
  }

  Never fail(http.Response r) {
    String msg = 'Notion error ${r.statusCode}';
    try {
      msg = jsonDecode(r.body)['message'] ?? msg;
    } catch (_) {}
    throw NotionException(msg);
  }

  Map<String, dynamic> props(DateTime date, double weight, {String? user}) {
    final d = date.toIso8601String().substring(0, 10);
    return {
      'Name': {
        'title': [
          {'text': {'content': '$d – ${weight.toStringAsFixed(1)} kg'}}
        ]
      },
      'Date': {'date': {'start': d}},
      'Weight': {'number': weight},
      if (user != null)
        'User': {
          'rich_text': [
            {'text': {'content': user}}
          ]
        },
    };
  }
}
