/// One weight record (a row in the Notion database).
class WeightEntry {
  final String id; // Notion page id
  final DateTime date;
  final double weight;
  final String? user; // owner username (Notion "User" column)

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weight,
    this.user,
  });
}
