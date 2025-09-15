import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livro/features/auth/services/auth_service.dart'; // 1. Importe o serviço

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Instância do nosso serviço de autenticação
  final AuthService _authService = AuthService(); // 2. Crie uma instância do serviço

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Adiciona um estado de carregamento para o botão
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

// Função para lidar com o toque no botão (versão corrigida)
  void _signUp() async {
    FocusScope.of(context).unfocus();
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Por favor, preencha todos os campos.'), backgroundColor: Colors.orange),
        );
        return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = await _authService.signUpWithEmailAndPassword(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
        context,
      );

      if (user != null && mounted) {
        // A navegação agora será automática por causa do AuthGate,
        // então não precisamos fazer nada aqui.
        Navigator.of(context).pop();
        print("CADASTRO REALIZADO COM SUCESSO! User ID: ${user.uid}");
      }
    } finally {
      // Este bloco SEMPRE será executado, com ou sem erro.
      if (mounted) { // Verifica se o widget ainda está na tela
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // ... (o resto da sua UI continua igual)
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 80),
              Icon(
                Icons.book_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Crie sua Conta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),

              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline),
                  labelText: 'Nome de usuário',
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email_outlined),
                  labelText: 'E-mail',
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock_outline),
                  labelText: 'Senha',
                  helperText: 'A senha deve ter no mínimo 6 caracteres.',
                ),
              ),
              const SizedBox(height: 32),
              
              // 3. Atualize o ElevatedButton
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp, // Desabilita o botão enquanto carrega
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white) // Mostra um loading
                    : const Text(
                        'Cadastrar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem uma conta?'),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Faça Login'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}