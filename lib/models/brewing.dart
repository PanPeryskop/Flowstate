import 'dart:convert';
import 'package:flowstate/models/brewing_step.dart';

class Brewing {
  final String id;
  final String coffeeId;
  final double coffeeDose; 
  final String grindSetting;
  final double waterTemperature; 
  final int? preInfusionTime; 
  final double? preInfusionWater; 
  final Duration totalBrewTime;
  final List<BrewingStep> steps;
  final int rating; // 1-5
  final String notes;
  final DateTime brewDate;
  
  Brewing({
    required this.id,
    required this.coffeeId,
    required this.coffeeDose,
    required this.grindSetting,
    required this.waterTemperature,
    this.preInfusionTime,
    this.preInfusionWater,
    required this.totalBrewTime,
    required this.steps,
    required this.rating,
    this.notes = '',
    required this.brewDate,
  });

  double get totalWater => 
      steps.fold(0.0, (sum, step) => sum + step.waterAmount) +
      (preInfusionWater ?? 0.0);
      
  double get ratio => totalWater / coffeeDose;

  Brewing copyWith({
    double? coffeeDose,
    String? grindSetting,
    double? waterTemperature,
    int? preInfusionTime,
    double? preInfusionWater,
    Duration? totalBrewTime,
    List<BrewingStep>? steps,
    int? rating,
    String? notes,
    DateTime? brewDate,
  }) {
    return Brewing(
      id: id,
      coffeeId: coffeeId,
      coffeeDose: coffeeDose ?? this.coffeeDose,
      grindSetting: grindSetting ?? this.grindSetting,
      waterTemperature: waterTemperature ?? this.waterTemperature,
      preInfusionTime: preInfusionTime ?? this.preInfusionTime,
      preInfusionWater: preInfusionWater ?? this.preInfusionWater,
      totalBrewTime: totalBrewTime ?? this.totalBrewTime,
      steps: steps ?? this.steps,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      brewDate: brewDate ?? this.brewDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'coffeeId': coffeeId,
      'coffeeDose': coffeeDose,
      'grindSetting': grindSetting,
      'waterTemperature': waterTemperature,
      'preInfusionTime': preInfusionTime,
      'preInfusionWater': preInfusionWater,
      'totalBrewTimeInSeconds': totalBrewTime.inSeconds,
      'steps': steps.map((x) => x.toMap()).toList(),
      'rating': rating,
      'notes': notes,
      'brewDate': brewDate.millisecondsSinceEpoch,
    };
  }

  factory Brewing.fromMap(Map<String, dynamic> map) {
    return Brewing(
      id: map['id'],
      coffeeId: map['coffeeId'],
      coffeeDose: map['coffeeDose'],
      grindSetting: map['grindSetting'],
      waterTemperature: map['waterTemperature'],
      preInfusionTime: map['preInfusionTime'],
      preInfusionWater: map['preInfusionWater'],
      totalBrewTime: Duration(seconds: map['totalBrewTimeInSeconds']),
      steps: List<BrewingStep>.from(
          map['steps']?.map((x) => BrewingStep.fromMap(x))),
      rating: map['rating'],
      notes: map['notes'] ?? '',
      brewDate: DateTime.fromMillisecondsSinceEpoch(map['brewDate']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Brewing.fromJson(String source) => 
      Brewing.fromMap(json.decode(source));
}