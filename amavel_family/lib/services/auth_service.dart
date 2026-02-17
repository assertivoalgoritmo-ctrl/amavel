import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
    required String name,
    required String seniorUserId,
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'name': name,
        'phone': phone ?? '',
        'userType': 'family',
        'linkedSeniorId': seniorUserId,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
        'fcmToken': '',
        'isActive': true,
      });

      await _firestore
          .collection('users')
          .doc(seniorUserId)
          .collection('family_members')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone ?? '',
        'relationship': 'family',
        'addedAt': DateTime.now(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> logout() async {
    try {
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update({'fcmToken': ''});
      }
      await _auth.signOut();
    } catch (e) {
      throw 'Erro ao sair: $e';
    }
  }

  Future<bool> linkWithInvitationCode({
    required String invitationCode,
  }) async {
    try {
      final seniorDoc = await _firestore
          .collection('users')
          .where('invitationCode', isEqualTo: invitationCode)
          .limit(1)
          .get();

      if (seniorDoc.docs.isEmpty) {
        throw 'Código de convite inválido';
      }

      final seniorId = seniorDoc.docs.first.id;
      final familyMemberId = currentUser?.uid;

      if (familyMemberId == null) {
        throw 'Usuário não autenticado';
      }

      await _firestore
          .collection('users')
          .doc(familyMemberId)
          .update({'linkedSeniorId': seniorId});

      return true;
    } catch (e) {
      throw 'Erro ao vincular com convite: $e';
    }
  }

  Future<String> generateInvitationCode(String seniorUserId) async {
    try {
      final code = const Uuid().v4().substring(0, 8).toUpperCase();

      await _firestore
          .collection('users')
          .doc(seniorUserId)
          .update({'invitationCode': code});

      return code;
    } catch (e) {
      throw 'Erro ao gerar código: $e';
    }
  }

  Future<void> updateFCMToken(String token) async {
    try {
      if (currentUser != null) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      throw 'Erro ao atualizar FCM token: $e';
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Senha fraca. Use pelo menos 6 caracteres.';
      case 'email-already-in-use':
        return 'Email já cadastrado.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'operation-not-allowed':
        return 'Operação não permitida.';
      case 'user-disabled':
        return 'Usuário desativado.';
      case 'user-not-found':
        return 'Usuário não encontrado.';
      case 'wrong-password':
        return 'Senha incorreta.';
      default:
        return 'Erro de autenticação: ${e.message}';
    }
  }
}
