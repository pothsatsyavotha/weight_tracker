class NotionException implements Exception {
  final String message;
  NotionException(this.message);
  @override
  String toString() => message;
}
