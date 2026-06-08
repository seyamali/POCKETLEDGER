import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final int iconCode;      // Material icon codepoint
  final int colorValue;    // Color 32-bit ARGB value
  final String type;       // 'income' or 'expense'
  final String userId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    required this.type,
    required this.userId,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] ?? '',
      iconCode: data['iconCode'] ?? 57541, // defaults to Icons.category
      colorValue: data['colorValue'] ?? 4284124022, // defaults to AppColors.primaryGreen
      type: data['type'] ?? 'expense',
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'type': type,
      'userId': userId,
    };
  }
}
