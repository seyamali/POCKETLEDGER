import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringBillModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String frequency; // 'Weekly', 'Monthly', 'Yearly'
  final DateTime nextDueDate;
  final String? linkedAccountId;
  final String? linkedAccountName;
  final String userId;
  final bool isActive;

  RecurringBillModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.nextDueDate,
    this.linkedAccountId,
    this.linkedAccountName,
    required this.userId,
    this.isActive = true,
  });

  factory RecurringBillModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RecurringBillModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Other',
      frequency: data['frequency'] ?? 'Monthly',
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
      linkedAccountId: data['linkedAccountId'],
      linkedAccountName: data['linkedAccountName'],
      userId: data['userId'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'category': category,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'linkedAccountId': linkedAccountId,
      'linkedAccountName': linkedAccountName,
      'userId': userId,
      'isActive': isActive,
    };
  }
}
