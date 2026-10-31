const kUnderweightBmi = 18.5;
const kOverweightBmi = 25.0; // BMI at or above this = "over"
const _healthyMaxBmi = 24.9;

double bmiOf(double kg, double heightCm) {
  final m = heightCm / 100;
  return kg / (m * m);
}

String bmiCategory(double bmi) {
  if (bmi < kUnderweightBmi) return 'Underweight';
  if (bmi < kOverweightBmi) return 'Normal';
  if (bmi < 30) return 'Overweight';
  return 'Obese';
}

/// Heaviest weight (kg) that is still BMI 24.9 for this height.
double healthyMaxKg(double heightCm) {
  final m = heightCm / 100;
  return _healthyMaxBmi * m * m;
}

/// Lightest weight (kg) that is still BMI 18.5 for this height.
double healthyMinKg(double heightCm) {
  final m = heightCm / 100;
  return kUnderweightBmi * m * m;
}
