import 'package:cloud_firestore/cloud_firestore.dart';

class GoalModel {
  final String id;
  final String monthYear; // Format: "MM-yyyy"
  final double incomeTarget;
  final double expenseLimit;
  final double savingsTarget;
  final double emi;
  final Map<String, double> categoryLimits;
  final String userId;
  final double initialProgressIncome;
  final double initialProgressExpense;
  final double initialProgressSavings;

  GoalModel({
    required this.id,
    required this.monthYear,
    required this.incomeTarget,
    required this.expenseLimit,
    required this.savingsTarget,
    this.emi = 0,
    required this.categoryLimits,
    required this.userId,
    this.initialProgressIncome = 0,
    this.initialProgressExpense = 0,
    this.initialProgressSavings = 0,
  });

  factory GoalModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return GoalModel(
      id: doc.id,
      monthYear: data['monthYear'] ?? '',
      incomeTarget: (data['incomeTarget'] ?? 0).toDouble(),
      expenseLimit: (data['expenseLimit'] ?? 0).toDouble(),
      savingsTarget: (data['savingsTarget'] ?? 0).toDouble(),
      emi: (data['emi'] ?? 0).toDouble(),
      initialProgressIncome: (data['initialProgressIncome'] ?? 0).toDouble(),
      initialProgressExpense: (data['initialProgressExpense'] ?? 0).toDouble(),
      initialProgressSavings: (data['initialProgressSavings'] ?? 0).toDouble(),
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
      'emi': emi,
      'initialProgressIncome': initialProgressIncome,
      'initialProgressExpense': initialProgressExpense,
      'initialProgressSavings': initialProgressSavings,
      'categoryLimits': categoryLimits,
      'userId': userId,
    };
  }
}
