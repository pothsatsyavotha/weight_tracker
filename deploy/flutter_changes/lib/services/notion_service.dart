import 'dart:convert';

import '../models/weight_entry.dart';
import 'notion_base.dart';
import 'notion_writes.dart';

// Re-exported so existing imports of notion_service.dart keep working.
export '../models/weight_entry.dart';
export 'notion_exception.dart';

/// Reads go through the Vercel proxy. add/update/delete come from [NotionWrites].
///
/// Notion database must have these properties:
///   Name   (Title)
///   Date   (Date)
///   Weight (Number)
///   User   (Text)
class NotionService extends NotionBase with NotionWrites {
  NotionService({super.client});

  /// Fetch entries, oldest first. Pass [user] to get only that user's rows;
  /// leave it null to get everyone's (admin screen).
  Future<List<WeightEntry>> fetchAll({String? user}) async {
    checkConfig();
    final entries = <WeightEntry>[];
    String? cursor;
    do {
      final res = await client.post(
        api('query'),
        headers: headers,
        body: jsonEncode({
          'page_size': 100,
          'sorts': [
            {'property': 'Date', 'direction': 'ascending'}
          ],
          if (user != null)
            'filter': {
              'property': 'User',
              'rich_text': {'equals': user},
            },
          if (cursor != null) 'start_cursor': cursor,
        }),
      );
      if (res.statusCode != 200) fail(res);
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      for (final page in json['results'] as List) {
        final props = page['properties'] as Map<String, dynamic>;
        final dateStr = props['Date']?['date']?['start'] as String?;
        final weight = props['Weight']?['number'];
        if (dateStr == null || weight == null) continue;

        String? owner;
        final rt = props['User']?['rich_text'];
        if (rt is List && rt.isNotEmpty) {
          owner = rt.map((t) => (t['plain_text'] ?? '') as String).join();
        }

        entries.add(WeightEntry(
          id: page['id'] as String,
          date: DateTime.parse(dateStr.substring(0, 10)),
          weight: (weight as num).toDouble(),
          user: owner,
        ));
      }
      cursor = json['has_more'] == true ? json['next_cursor'] as String? : null;
    } while (cursor != null);
    return entries;
  }
}
