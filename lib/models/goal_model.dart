import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String monthYear; // Format: "MM-yyyy"
  final double incomeTarget;
  final double expenseLimit;
  final double savingsTarget;
  final Map<String, double> categoryLimits;
  final String userId;

  GoalModel({
    required this.id,
    required this.monthYear,
    required this.incomeTarget,
    required this.expenseLimit,
    required this.savingsTarget,
    required this.categoryLimits,
    required this.userId,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      monthYear: data['monthYear'] ?? '',
      incomeTarget: (data['incomeTarget'] ?? 0).toDouble(),
      expenseLimit: (data['expenseLimit'] ?? 0).toDouble(),
      savingsTarget: (data['savingsTarget'] ?? 0).toDouble(),
      categoryLimits: data['categoryLimits'] != null 
          ? Map<String, double>.from((data['categoryLimits'] as Map).map((k, v) => MapEntry(k, (v ?? 0).toDouble()))) 
          : {},
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'monthYear': monthYear,
      'incomeTarget': incomeTarget,
      'expenseLimit': expenseLimit,
      'savingsTarget': savingsTarget,
      'categoryLimits': categoryLimits,
      'userId': userId,
    };
  }
}
