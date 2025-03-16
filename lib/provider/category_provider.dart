import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';

// Firestore instance provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Firebase Auth provider to get the current user
final authProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

// Category provider
final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier(ref);
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  final Ref ref;

  CategoryNotifier(this.ref) : super([]) {
    fetchCategories();
  }

  // ✅ Fetch categories for the logged-in user
  Future<void> fetchCategories() async {
    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return; // User not logged in

      final querySnapshot = await ref
          .read(firestoreProvider)
          .collection('categories')
          .where('userId', isEqualTo: user.uid) // Fetch only the logged-in user's categories
          .get();

      state = querySnapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // ✅ Add a new category with user ID
  Future<void> addCategory(String categoryName) async {
    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return; // User not logged in

      final docRef = await ref.read(firestoreProvider).collection('categories').add({
        'name': categoryName,
        'userId': user.uid, // Associate category with the user
      });

      state = [...state, Category(id: docRef.id, name: categoryName)];
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  // ✅ Edit a category (Only if it belongs to the user)
  Future<void> editCategory(String id, String newName) async {
    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return; // User not logged in

      await ref.read(firestoreProvider).collection('categories').doc(id).update({
        'name': newName,
        'userId': user.uid, // Ensure update is for this user
      });

      state = state.map((cat) => cat.id == id ? Category(id: cat.id, name: newName) : cat).toList();
    } catch (e) {
      print("Error editing category: $e");
    }
  }

  // ✅ Delete a category (Only if it belongs to the user)
  Future<void> deleteCategory(String id) async {
    try {
      final user = ref.read(authProvider).currentUser;
      if (user == null) return; // User not logged in

      await ref.read(firestoreProvider).collection('categories').doc(id).delete();
      state = state.where((cat) => cat.id != id).toList();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }
}
