import 'package:chatboot/screens/auth/login_screen.dart';
import 'package:chatboot/screens/chat/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthController extends GetxController {
  late final AuthService _authService = Get.find<AuthService>();
  
  RxBool isLoading = false.obs;
  RxBool isLogged = false.obs;
  Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  RxString errorMessage = ''.obs;
  
  // Flag para controlar se já navegou
  bool _hasNavigated = false;

  @override
  void onInit() {
    super.onInit();
    print('📱 AuthController: onInit');
    
    // Verificar se já existe usuário logado (MAS NÃO NAVEGAR AINDA)
    _checkCurrentUser();
  }

  @override
  void onReady() {
    super.onReady();
    print('📱 AuthController: onReady');
    
    // Observar mudanças no usuário do Firebase
    ever<User?>(_authService.firebaseUser, _handleUserChanged);
  }

  void _checkCurrentUser() {
    final user = _authService.firebaseUser.value;
    if (user != null) {
      print('👤 Usuário já logado encontrado: ${user.email}');
      // Atualizar estado mas NÃO navegar ainda
      isLogged.value = true;
      currentUser.value = UserModel(
        uid: user.uid,
        nome: user.displayName ?? 'Usuário',
        email: user.email,
        fotoURL: user.photoURL,
      );
    }
  }

  void _handleUserChanged(User? user) {
    print('🔄 AuthController: Usuário mudou - ${user?.email ?? 'null'}');
    
    if (user != null) {
      isLogged.value = true;
      currentUser.value = UserModel(
        uid: user.uid,
        nome: user.displayName ?? 'Usuário',
        email: user.email,
        fotoURL: user.photoURL,
      );
      
      // SÓ navegar se ainda não navegou e se o app estiver pronto
      _navigateToHomeIfReady();
      
    } else {
      isLogged.value = false;
      currentUser.value = null;
      _hasNavigated = false; // Resetar flag quando deslogar
    }
  }

  void _navigateToHomeIfReady() {
    // Evitar navegação múltipla
    if (_hasNavigated) {
      print('⏭️ Navegação já realizada, ignorando');
      return;
    }
    
    // Verificar se o GetMaterialApp está pronto
    if (Get.key != null && Get.context != null) {
      print('🚀 Navegando para HomeScreen agora');
      _hasNavigated = true;
      
      // Usar addPostFrameCallback para garantir que o frame atual terminou
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(() => const HomeScreen());
      });
    } else {
      print('⏳ GetMaterialApp ainda não está pronto, agendando navegação');
      
      // Agendar para quando o app estiver pronto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasNavigated && Get.key != null && Get.context != null) {
          print('🚀 Navegando para HomeScreen (após agendamento)');
          _hasNavigated = true;
          Get.offAll(() => const HomeScreen());
        }
      });
    }
  }

  Future<void> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      _showError('Preencha todos os campos');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      print('📝 Tentando login: $email');
      final user = await _authService.loginWithEmail(email.trim(), password);
      
      if (user != null) {
        print('✅ Login bem-sucedido: ${user.email}');
        _hasNavigated = false; // Resetar flag para nova navegação
        // O _handleUserChanged será chamado automaticamente pelo stream
      }
    } catch (e) {
      print('❌ Erro no login: $e');
      _showError('Erro ao fazer login');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Preencha todos os campos');
      return;
    }

    if (password.length < 6) {
      _showError('A senha deve ter pelo menos 6 caracteres');
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';
    
    try {
      print('📝 Tentando registro: $email');
      final success = await _authService.registerWithEmail(
        email.trim(), 
        password, 
        name.trim()
      );
      
      if (success) {
        print('✅ Registro bem-sucedido');
        _hasNavigated = false; // Resetar flag para nova navegação
        // O _handleUserChanged será chamado automaticamente
      }
    } catch (e) {
      print('❌ Erro no registro: $e');
      _showError('Erro ao criar conta');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      _showError('Digite seu e-mail');
      return;
    }

    isLoading.value = true;
    
    try {
      await _authService.resetPassword(email.trim());
      
      // Verificar se pode mostrar snackbar
      if (Get.key != null && Get.context != null) {
        Get.snackbar(
          'Sucesso',
          'Email de recuperação enviado!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
      
      // Voltar para login após 2 segundos
      await Future.delayed(const Duration(seconds: 2));
      
      if (Get.key != null && Get.context != null) {
        Get.back();
      }
    } catch (e) {
      _showError('Erro ao enviar email de recuperação');
    } finally {
      isLoading.value = false;
    }
  }

  void logout() async {
    try {
      await _authService.signOut();
      print('✅ Logout realizado');
      _hasNavigated = false; // Resetar flag
      
      // Navegar para login após logout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.key != null && Get.context != null) {
          Get.offAll(() => const LoginScreen());
        }
      });
      
    } catch (e) {
      print('❌ Erro no logout: $e');
    }
  }

  void _showError(String message) {
    errorMessage.value = message;
    
    // Verificar se pode mostrar snackbar
    if (Get.key != null && Get.context != null) {
      Get.snackbar(
        'Erro',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } else {
      print('❌ Erro: $message');
    }
  }
}