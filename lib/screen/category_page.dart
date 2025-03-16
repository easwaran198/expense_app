import 'package:expense_app/models/category_model.dart';
import 'package:expense_app/provider/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryPage extends ConsumerWidget {
  final TextEditingController _categoryController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Manage Categories")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: "New Category",
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    final newCategory = _categoryController.text.trim();
                    if (newCategory.isNotEmpty) {
                      ref.read(categoryProvider.notifier).addCategory(newCategory);
                      _categoryController.clear();
                    }
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return ListTile(
                  title: Text(category.name),
                  leading: Icon(Icons.category),

                  // ✅ Edit Button
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditDialog(context, ref, category);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(context, ref, category.id);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Show Edit Category Dialog
  void _showEditDialog(BuildContext context, WidgetRef ref, Category category) {
    TextEditingController _editController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Category"),
          content: TextField(
            controller: _editController,
            decoration: InputDecoration(labelText: "Category Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final newName = _editController.text.trim();
                if (newName.isNotEmpty) {
                  ref.read(categoryProvider.notifier).editCategory(category.id, newName);
                }
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Show Delete Confirmation Dialog
  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String categoryId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Category"),
          content: Text("Are you sure you want to delete this category?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                ref.read(categoryProvider.notifier).deleteCategory(categoryId);
                Navigator.pop(context);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

