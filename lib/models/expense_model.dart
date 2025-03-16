import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final double amount;
  final String categoryId;
  final String description;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.description,
    required this.date,
  });

  factory ExpenseModel.fromFirestore(Map<String, dynamic> json, String id) {
    return ExpenseModel(
      id: id,
      amount: json['amount'].toDouble(),
      categoryId: json['categoryId'],
      description: json['description'],
      date: (json['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'categoryId': categoryId,
      'description': description,
      'date': Timestamp.fromDate(date),
    };
  }
}
