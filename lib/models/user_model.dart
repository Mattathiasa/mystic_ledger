import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'uid':       uid,
        'name':      name,
        'email':     email,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
        uid:       m['uid']   as String,
        name:      m['name']  as String,
        email:     m['email'] as String,
        createdAt: (m['createdAt'] as Timestamp).toDate(),
      );

  UserModel copyWith({String? name, String? email}) => UserModel(
        uid:       uid,
        name:      name  ?? this.name,
        email:     email ?? this.email,
        createdAt: createdAt,
      );
}
