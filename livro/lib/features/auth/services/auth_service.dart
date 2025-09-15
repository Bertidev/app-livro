import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Instância do Firebase Auth para lidar com autenticação
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Instância do Firestore para lidar com o banco de dados
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para cadastrar um novo usuário
  Future<User?> signUpWithEmailAndPassword(
      String username, String email, String password, BuildContext context) async {
    try {
      // 1. Criar o usuário no Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. Salvar informações adicionais (como o nome de usuário) no Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'username': username,
          'email': email,
          'createdAt': Timestamp.now(),
        });
      }
      return user;

    } on FirebaseAuthException catch (e) {
      // 3. Tratar erros de forma amigável
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'A senha fornecida é muito fraca.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Este e-mail já está em uso.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'O formato do e-mail é inválido.';
      } else {
        errorMessage = 'Ocorreu um erro. Tente novamente.';
      }
      
      // Mostra uma mensagem de erro na tela
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

  // Método para fazer login
  Future<User?> signInWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Ocorreu um erro. Verifique suas credenciais.';
      // Códigos de erro comuns para login
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'E-mail ou senha incorretos.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
    return null;
  }

    /// Atualiza a URL da foto de perfil do usuário no Firestore.
  Future<void> updateUserProfilePicture(String photoUrl) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    await _firestore.collection('users').doc(currentUser.uid).update({
      'photoUrl': photoUrl,
    });
  }
}