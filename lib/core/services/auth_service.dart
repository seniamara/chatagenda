import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends GetxService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Observable para o usuário do Firebase
  Rx<User?> firebaseUser = Rx<User?>(null);

  // Propriedade de conveniência
  User? get user => firebaseUser.value;

  @override
  void onInit() {
    super.onInit();
    print('🚀 AuthService iniciado');
    
    // Listener para mudanças no estado de autenticação
    firebaseUser.bindStream(_firebaseAuth.authStateChanges());
    
    // Verificar usuário atual
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      print('👤 Usuário já logado: ${currentUser.email}');
      firebaseUser.value = currentUser;
    }
  }

  // Login com email e senha
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      print('🔐 Tentando login: $email');
      
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Login bem-sucedido: ${credential.user?.email}');
      
      // Atualizar último login no Firestore
      await _updateUserLastLogin(credential.user!.uid);
      
      return credential.user;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Erro Firebase Auth: ${e.code} - ${e.message}');
      _handleAuthError(e);
      return null;
      
    } catch (e) {
      print('❌ Erro inesperado: $e');
      Get.snackbar(
        'Erro',
        'Erro de conexão. Verifique sua internet.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }

  // Registro com email e senha
  Future<bool> registerWithEmail(String email, String password, String name) async {
    try {
      print('🔐 Tentando registro: $email');
      
      // Criar usuário
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Atualizar perfil com nome
      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
      
      // Criar documento do usuário no Firestore
      await _createUserDocument(credential.user!.uid, name, email);
      
      print('✅ Registro bem-sucedido: ${credential.user?.email}');
      return true;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Erro Firebase Auth: ${e.code} - ${e.message}');
      _handleAuthError(e);
      return false;
      
    } catch (e) {
      print('❌ Erro inesperado: $e');
      Get.snackbar(
        'Erro',
        'Erro de conexão. Verifique sua internet.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Criar documento do usuário no Firestore
  Future<void> _createUserDocument(String uid, String name, String email) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'nome': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'taskStreak': 0,
        'totalTasks': 0,
      });
      print('📄 Documento do usuário criado no Firestore');
    } catch (e) {
      print('⚠️ Erro ao criar documento no Firestore: $e');
    }
  }

  // Atualizar último login
  Future<void> _updateUserLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Erro ao atualizar último login: $e');
    }
  }

  // Reset de senha
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      print('📧 Email de recuperação enviado para: $email');
      
      Get.snackbar(
        'Sucesso',
        'Email de recuperação enviado!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      
    } on FirebaseAuthException catch (e) {
      print('❌ Erro ao enviar email: ${e.code}');
      _handleAuthError(e);
      
    } catch (e) {
      print('❌ Erro inesperado: $e');
      Get.snackbar(
        'Erro',
        'Erro ao enviar email de recuperação',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print('👋 Logout realizado');
      
    } catch (e) {
      print('❌ Erro no logout: $e');
    }
  }

  // Tratamento de erros do Firebase
  void _handleAuthError(FirebaseAuthException e) {
    String title = 'Erro de autenticação';
    String message = '';
    
    switch (e.code) {
      case 'user-not-found':
        message = 'Usuário não encontrado';
        break;
      case 'wrong-password':
        message = 'Senha incorreta';
        break;
      case 'invalid-email':
        message = 'Email inválido';
        break;
      case 'user-disabled':
        message = 'Usuário desabilitado';
        break;
      case 'too-many-requests':
        message = 'Muitas tentativas. Tente novamente mais tarde';
        break;
      case 'network-request-failed':
        message = 'Erro de conexão. Verifique sua internet';
        break;
      case 'email-already-in-use':
        message = 'Email já está em uso';
        break;
      case 'weak-password':
        message = 'Senha muito fraca (mínimo 6 caracteres)';
        break;
      case 'operation-not-allowed':
        message = 'Operação não permitida';
        break;
      default:
        message = e.message ?? 'Erro desconhecido';
    }
    
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}