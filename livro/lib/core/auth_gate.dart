import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/features/auth/screens/login_screen.dart';
import 'package:livro/features/home/screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // Ouve em tempo real as mudanças no estado de autenticação
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Se ainda está verificando, mostra um loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Se tem um usuário (logado), mostra a HomeScreen
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // Se não tem um usuário (deslogado), mostra a LoginScreen
          return const LoginScreen();
        },
      ),
    );
  }
}