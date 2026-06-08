import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pocketledger/models/category_model.dart';
import 'package:pocketledger/core/utils/error_logger.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  /// Gets a real-time stream of categories for the logged-in user.
  /// If the collection is empty, it automatically populates the defaults first.
  Stream<List<CategoryModel>> getCategories() {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('categories')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .asyncMap((snap) async {
          if (snap.docs.isEmpty) {
            await _prepopulateDefaultCategories();
            final freshSnap = await _db
                .collection('categories')
                .where('userId', isEqualTo: _uid)
                .get();
            return freshSnap.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
          }
          return snap.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
        });
  }

  /// Create a new category
  Future<void> addCategory(CategoryModel category) async {
    if (_uid == null) return;
    try {
      final docRef = _db.collection('categories').doc();
      final newCat = CategoryModel(
        id: docRef.id,
        name: category.name,
        iconCode: category.iconCode,
        colorValue: category.colorValue,
        type: category.type,
        userId: _uid!,
      );
      await docRef.set(newCat.toFirestore());
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'addCategory');
      rethrow;
    }
  }

  /// Update category details
  Future<void> updateCategory(CategoryModel category) async {
    if (_uid == null) return;
    try {
      await _db.collection('categories').doc(category.id).update(category.toFirestore());
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'updateCategory');
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    if (_uid == null) return;
    try {
      await _db.collection('categories').doc(categoryId).delete();
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'deleteCategory');
      rethrow;
    }
  }

  /// Prepopulate default categories for the user
  Future<void> _prepopulateDefaultCategories() async {
    if (_uid == null) return;
    
    final defaults = [
      // Expenses
      CategoryModel(id: '', name: 'Home', iconCode: Icons.home_rounded.codePoint, colorValue: Colors.indigo.value, type: 'expense', userId: _uid!),
      CategoryModel(id: '', name: 'Food', iconCode: Icons.restaurant_rounded.codePoint, colorValue: Colors.orange.value, type: 'expense', userId: _uid!),
      CategoryModel(id: '', name: 'Transport', iconCode: Icons.directions_bus_rounded.codePoint, colorValue: Colors.blue.value, type: 'expense', userId: _uid!),
      CategoryModel(id: '', name: 'Wife', iconCode: Icons.favorite_rounded.codePoint, colorValue: Colors.pink.value, type: 'expense', userId: _uid!),
      CategoryModel(id: '', name: 'Myself', iconCode: Icons.person_rounded.codePoint, colorValue: Colors.teal.value, type: 'expense', userId: _uid!),
      CategoryModel(id: '', name: 'Other', iconCode: Icons.grid_view_rounded.codePoint, colorValue: Colors.grey.value, type: 'expense', userId: _uid!),

      // Incomes
      CategoryModel(id: '', name: 'Income', iconCode: Icons.payments_rounded.codePoint, colorValue: Colors.green.value, type: 'income', userId: _uid!),
      CategoryModel(id: '', name: 'Salary', iconCode: Icons.work_rounded.codePoint, colorValue: Colors.deepPurple.value, type: 'income', userId: _uid!),
      CategoryModel(id: '', name: 'Business', iconCode: Icons.store_rounded.codePoint, colorValue: Colors.amber.value, type: 'income', userId: _uid!),
      CategoryModel(id: '', name: 'Other', iconCode: Icons.more_horiz_rounded.codePoint, colorValue: Colors.grey.value, type: 'income', userId: _uid!),
    ];

    final batch = _db.batch();
    for (final cat in defaults) {
      final docRef = _db.collection('categories').doc();
      batch.set(docRef, cat.toFirestore());
    }
    await batch.commit();
  }
}
