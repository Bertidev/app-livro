import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      username: data['username'] ?? 'Usuário anônimo',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }
}