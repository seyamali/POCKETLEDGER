import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocketledger/core/constants/app_constants.dart';

class AccountModel {
  final String id;
  final String name;
  final String type; // Bank, MFS, Cash
  final double totalBalance;
  final Map<String, double> breakdown; // { AppConstants.ownerSelf: 20000, AppConstants.ownerFather: 10000 }
  final String userId;
  
  // Bank details fields
  final String? accountNumber;
  final String? cardNumber;
  final String? branchName;
  final String? routingNumber;

  // MFS fields
  final String? mobileNumber;

  AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBalance,
    required this.breakdown,
    required this.userId,
    this.accountNumber,
    this.cardNumber,
    this.branchName,
    this.routingNumber,
    this.mobileNumber,
  });

  factory AccountModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AccountModel(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      totalBalance: (data['totalBalance'] ?? 0).toDouble(),
      breakdown: Map<String, double>.from(
        (data['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
      ),
      userId: data['userId'] ?? '',
      accountNumber: data['accountNumber'],
      cardNumber: data['cardNumber'],
      branchName: data['branchName'],
      routingNumber: data['routingNumber'],
      mobileNumber: data['mobileNumber'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'totalBalance': totalBalance,
      'breakdown': breakdown,
      'userId': userId,
      'accountNumber': accountNumber,
      'cardNumber': cardNumber,
      'branchName': branchName,
      'routingNumber': routingNumber,
      'mobileNumber': mobileNumber,
    };
  }
}
