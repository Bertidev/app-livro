import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Faz o upload de uma imagem de perfil e retorna a URL de download.
  Future<String?> uploadProfileImage() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    // 1. Pede ao usuário para escolher uma imagem
    final imagePicker = ImagePicker();
    final XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      return null; // Usuário cancelou
    }

    // 2. Define o caminho no Firebase Storage
    File imageFile = File(pickedFile.path);
    String filePath = 'profile_images/${currentUser.uid}.jpg';
    
    // 3. Faz o upload do arquivo
    try {
      final uploadTask = await _storage.ref(filePath).putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Erro no upload da imagem: $e');
      return null;
    }
  }
}