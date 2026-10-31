enum Range { recent, d30, d90, all }

extension RangeX on Range {
  String get label => switch (this) {
    Range.recent => 'Recent',
    Range.d30 => '30 Days',
    Range.d90 => '90 Days',
    Range.all => 'All Time',
  };
  int? get days => switch (this) {
    Range.recent => 7,
    Range.d30 => 30,
    Range.d90 => 90,
    Range.all => null,
  };
}
