import 'package:cloud_firestore/cloud_firestore.dart';

class CreditCardModel {
  final String id;
  final String userId;
  final String cardNickname;
  final String bankName;
  final String lastFourDigits;
  final String cardNetwork; // 'visa' | 'mastercard' | 'amex'
  final double creditLimit;
  final double outstandingBalance;
  final int statementClosingDay; // 1–28
  final int paymentDueDays;      // days after closing
  final double apr;              // Annual Percentage Rate %
  final int cardColorIndex;      // 0–3 premium gradient themes
  final DateTime createdAt;

  CreditCardModel({
    required this.id,
    required this.userId,
    required this.cardNickname,
    required this.bankName,
    required this.lastFourDigits,
    required this.cardNetwork,
    required this.creditLimit,
    required this.outstandingBalance,
    required this.statementClosingDay,
    required this.paymentDueDays,
    required this.apr,
    required this.cardColorIndex,
    required this.createdAt,
  });

  double get availableCredit => (creditLimit - outstandingBalance).clamp(0, creditLimit);
  double get utilizationPercent => creditLimit > 0 ? (outstandingBalance / creditLimit).clamp(0, 1) : 0;
  double get minimumPayment {
    if (outstandingBalance <= 0) return 0;
    double minPay = outstandingBalance * 0.02;
    if (minPay < 250) minPay = 250;
    if (minPay > outstandingBalance) minPay = outstandingBalance;
    return minPay;
  }

  /// Next statement closing date from today
  DateTime get nextStatementDate {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, statementClosingDay);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year, now.month + 1, statementClosingDay);
    }
    return candidate;
  }

  /// Payment due date = statement close + paymentDueDays
  DateTime get nextDueDate => nextStatementDate.add(Duration(days: paymentDueDays));

  int get daysUntilStatement => nextStatementDate.difference(DateTime.now()).inDays;
  int get daysUntilDue => nextDueDate.difference(DateTime.now()).inDays;

  factory CreditCardModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return CreditCardModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      cardNickname: d['cardNickname'] ?? '',
      bankName: d['bankName'] ?? '',
      lastFourDigits: d['lastFourDigits'] ?? '0000',
      cardNetwork: d['cardNetwork'] ?? 'visa',
      creditLimit: (d['creditLimit'] ?? 0).toDouble(),
      outstandingBalance: (d['outstandingBalance'] ?? 0).toDouble(),
      statementClosingDay: d['statementClosingDay'] ?? 25,
      paymentDueDays: d['paymentDueDays'] ?? 15,
      apr: (d['apr'] ?? 0).toDouble(),
      cardColorIndex: d['cardColorIndex'] ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'cardNickname': cardNickname,
    'bankName': bankName,
    'lastFourDigits': lastFourDigits,
    'cardNetwork': cardNetwork,
    'creditLimit': creditLimit,
    'outstandingBalance': outstandingBalance,
    'statementClosingDay': statementClosingDay,
    'paymentDueDays': paymentDueDays,
    'apr': apr,
    'cardColorIndex': cardColorIndex,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  CreditCardModel copyWith({
    String? cardNickname,
    String? bankName,
    String? lastFourDigits,
    String? cardNetwork,
    double? creditLimit,
    double? outstandingBalance,
    int? statementClosingDay,
    int? paymentDueDays,
    double? apr,
    int? cardColorIndex,
  }) {
    return CreditCardModel(
      id: id,
      userId: userId,
      cardNickname: cardNickname ?? this.cardNickname,
      bankName: bankName ?? this.bankName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      creditLimit: creditLimit ?? this.creditLimit,
      outstandingBalance: outstandingBalance ?? this.outstandingBalance,
      statementClosingDay: statementClosingDay ?? this.statementClosingDay,
      paymentDueDays: paymentDueDays ?? this.paymentDueDays,
      apr: apr ?? this.apr,
      cardColorIndex: cardColorIndex ?? this.cardColorIndex,
      createdAt: createdAt,
    );
  }
}
