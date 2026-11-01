import 'dart:convert';

import 'notion_base.dart';

/// Create / update / delete operations (via the Vercel proxy).
mixin NotionWrites on NotionBase {
  // CREATE: adds a new row to the Notion database
  Future<void> add(DateTime date, double weight, {required String user}) async {
    checkConfig();
    final res = await client.post(
      api('pages'),
      headers: headers,
      body: jsonEncode({'properties': props(date, weight, user: user)}),
    );
    if (res.statusCode != 200) fail(res);
  }

  // UPDATE: edits an existing row in place
  Future<void> update(String pageId, DateTime date, double weight) async {
    checkConfig();
    final res = await client.patch(
      api('pages/$pageId'),
      headers: headers,
      body: jsonEncode({'properties': props(date, weight)}),
    );
    if (res.statusCode != 200) fail(res);
  }

  // DELETE: Notion "deletes" by archiving the page
  Future<void> delete(String pageId) async {
    checkConfig();
    final res = await client.patch(
      api('pages/$pageId'),
      headers: headers,
      body: jsonEncode({'archived': true}),
    );
    if (res.statusCode != 200) fail(res);
  }
}
