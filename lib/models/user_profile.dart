/// Goal + body data a user enters (used for BMI and goal progress).
class UserProfile {
  final double heightCm;
  final int age;
  final double currentWeight; // weight when the goal was set
  final double goalWeight;

  const UserProfile({
    required this.heightCm,
    required this.age,
    required this.currentWeight,
    required this.goalWeight,
  });

  Map<String, dynamic> toJson() => {
    'heightCm': heightCm,
    'age': age,
    'currentWeight': currentWeight,
    'goalWeight': goalWeight,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    heightCm: (j['heightCm'] as num).toDouble(),
    age: (j['age'] as num).toInt(),
    currentWeight: (j['currentWeight'] as num).toDouble(),
    goalWeight: (j['goalWeight'] as num).toDouble(),
  );
}
