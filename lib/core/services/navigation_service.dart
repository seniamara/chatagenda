import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationService {
  // Singleton
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Navegação segura
  void offAll(Widget Function() page) {
    // Verificar se o GetX está pronto para navegação
    if (Get.key != null && Get.context != null) {
      Get.offAll(page());
    } else {
      // Se não estiver pronto, agendar para depois
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAll(page());
      });
    }
  }

  void to(Widget Function() page) {
    if (Get.key != null && Get.context != null) {
      Get.to(page());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.to(page());
      });
    }
  }

  void back() {
    if (Get.key != null && Get.context != null) {
      Get.back();
    }
  }
}