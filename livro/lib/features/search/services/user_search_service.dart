import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:livro/features/profile/models/user_model.dart';

class UserSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Busca usuários cujo nome de usuário comece com o termo da pesquisa.
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }

    // A consulta busca por nomes de usuário que estão entre o termo de busca
    // e o "próximo" caractere, simulando um "começa com".
    // Ex: query='luc' busca entre 'luc' e 'lud'.
    final querySnapshot = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThan: query + 'z')
        .limit(15) // Limita a 15 resultados para não sobrecarregar
        .get();

    return querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
}