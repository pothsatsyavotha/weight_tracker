import 'dart:convert';

import 'notion_base.dart';

/// Create / update / delete operations.
mixin NotionWrites on NotionBase {
  // ═══════════ CREATE: adds a new row to the Notion database ═══════════
  Future<void> add(DateTime date, double weight, {required String user}) async {
    checkConfig();
    final res = await client.post(
      Uri.parse('$baseUrl/pages'),
      headers: headers,
      body: jsonEncode({
        'parent': {'database_id': databaseId},
        'properties': props(date, weight, user: user),
      }),
    );
    if (res.statusCode != 200) fail(res);
  }

  // ═══════════ UPDATE: edits an existing row in the database ═══════════
  /// Edit an existing entry in place.
  Future<void> update(String pageId, DateTime date, double weight) async {
    checkConfig();
    final res = await client.patch(
      Uri.parse('$baseUrl/pages/$pageId'),
      headers: headers,
      body: jsonEncode({'properties': props(date, weight)}),
    );
    if (res.statusCode != 200) fail(res);
  }

  // ═══════════ DELETE: removes (archives) a row in the database ═══════════
  /// Notion "deletes" by archiving the page.
  Future<void> delete(String pageId) async {
    checkConfig();
    final res = await client.patch(
      Uri.parse('$baseUrl/pages/$pageId'),
      headers: headers,
      body: jsonEncode({'archived': true}),
    );
    if (res.statusCode != 200) fail(res);
  }
}
