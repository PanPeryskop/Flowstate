import 'dart:convert';

class BrewingStep {
  final int stepNumber;
  final double waterAmount; 
  final int? time;
  
  BrewingStep({
    required this.stepNumber,
    required this.waterAmount,
    this.time,
  });

  BrewingStep copyWith({
    int? stepNumber,
    double? waterAmount,
    int? time,
  }) {
    return BrewingStep(
      stepNumber: stepNumber ?? this.stepNumber,
      waterAmount: waterAmount ?? this.waterAmount,
      time: time ?? this.time,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stepNumber': stepNumber,
      'waterAmount': waterAmount,
      'time': time,
    };
  }

  factory BrewingStep.fromMap(Map<String, dynamic> map) {
    return BrewingStep(
      stepNumber: map['stepNumber'],
      waterAmount: map['waterAmount'],
      time: map['time'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BrewingStep.fromJson(String source) => 
      BrewingStep.fromMap(json.decode(source));
}