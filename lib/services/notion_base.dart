import 'dart:convert';
import 'package:http/http.dart' as http;

import 'notion_exception.dart';

/// Shared helpers. All Notion calls now go through the Vercel proxy
/// (/api/notion), so the Notion token never ships inside the app.
abstract class NotionBase {
  // Leave empty on the deployed web app (same domain).
  // For testing from a phone/desktop: --dart-define=API_BASE=https://your-app.vercel.app
  static const _apiBase = String.fromEnvironment('API_BASE');
  // Optional shared key, must match APP_KEY in Vercel.
  static const _appKey = String.fromEnvironment('APP_KEY');

  final http.Client client;
  NotionBase({http.Client? client}) : client = client ?? http.Client();

  Uri api(String path) => Uri.parse('$_apiBase/api/notion?path=$path');

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (_appKey.isNotEmpty) 'x-app-key': _appKey,
  };

  void checkConfig() {} // configuration now lives on the server

  Never fail(http.Response r) {
    String msg = 'Server error ${r.statusCode}';
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
