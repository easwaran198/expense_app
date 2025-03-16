import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier(ref);
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  final Ref ref;

  CategoryNotifier(this.ref) : super([]) {
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final querySnapshot = await ref.read(firestoreProvider)
          .collection('categories')
          .where('userId', isEqualTo: userId) // Filter by userId
          .get();
      state = querySnapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }


  Future<void> addCategory(String categoryName) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final docRef = await ref.read(firestoreProvider).collection('categories').add({
        'name': categoryName,
        'userId': userId, // Associate with user
      });
      state = [...state, Category(id: docRef.id, name: categoryName)];
    } catch (e) {
      print("Error adding category: $e");
    }
  }


  // ✅ Edit an existing category
  Future<void> editCategory(String id, String newName) async {
    try {
      await ref.read(firestoreProvider).collection('categories').doc(id).update({'name': newName});
      state = state.map((cat) => cat.id == id ? Category(id: cat.id, name: newName) : cat).toList();
    } catch (e) {
      print("Error editing category: $e");
    }
  }

  // ✅ Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      await ref.read(firestoreProvider).collection('categories').doc(id).delete();
      state = state.where((cat) => cat.id != id).toList();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }
}
