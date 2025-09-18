import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FollowListScreen extends StatelessWidget {
  final String userId;
  final String listType; // 'followers' ou 'following'

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.listType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(listType == 'followers' ? 'Seguidores' : 'Seguindo'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(listType)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum usuário aqui.'));
          }

          final userDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: userDocs.length,
            itemBuilder: (context, index) {
              final userData = userDocs[index].data() as Map<String, dynamic>;
              final photoUrl = userData['photoUrl'] as String?;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person) : null,
                ),
                title: Text(userData['username'] ?? 'Usuário'),
                // onTap: () { /* Navegar para o perfil deste usuário */ },
              );
            },
          );
        },
      ),
    );
  }
}