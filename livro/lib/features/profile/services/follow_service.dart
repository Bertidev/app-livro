import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:livro/features/profile/models/user_model.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna um Stream com a contagem de seguidores de um usuário.
  Stream<int> getFollowersCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Retorna um Stream com a contagem de usuários que um usuário está seguindo.
  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  /// Verifica se o usuário logado atualmente está seguindo outro usuário.
  Stream<bool> isFollowing(String otherUserId) {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(otherUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Faz o usuário atual seguir outro usuário.
  Future<void> followUser(String userIdToFollow) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Pega os dados do usuário atual para salvar na lista do outro.
    final currentUserDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final currentUserData = UserModel.fromFirestore(currentUserDoc);

    // Pega os dados do usuário a ser seguido.
    final userToFollowDoc = await _firestore.collection('users').doc(userIdToFollow).get();
    final userToFollowData = UserModel.fromFirestore(userToFollowDoc);

    // Adiciona o usuário a ser seguido na subcoleção 'following' do usuário atual.
    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(userIdToFollow)
        .set({
          'username': userToFollowData.username,
          'photoUrl': userToFollowData.photoUrl,
        });
    
    // Adiciona o usuário atual na subcoleção 'followers' do outro usuário.
    await _firestore
        .collection('users')
        .doc(userIdToFollow)
        .collection('followers')
        .doc(currentUser.uid)
        .set({
          'username': currentUserData.username,
          'photoUrl': currentUserData.photoUrl,
        });
  }

  /// Faz o usuário atual deixar de seguir outro usuário.
  Future<void> unfollowUser(String userIdToUnfollow) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    // Remove o outro usuário da lista 'following' do usuário atual.
    await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .collection('following')
        .doc(userIdToUnfollow)
        .delete();

    // Remove o usuário atual da lista 'followers' do outro usuário.
    await _firestore
        .collection('users')
        .doc(userIdToUnfollow)
        .collection('followers')
        .doc(currentUser.uid)
        .delete();
  }
}