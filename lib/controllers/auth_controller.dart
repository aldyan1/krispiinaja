import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../models/profile_model.dart';
import '../utils/app_routes.dart';

class AuthController extends GetxController {
  static AuthController to = Get.find();

  final SupabaseService _db = SupabaseService.instance;
  
  var isLoading = false.obs;
  Rxn<ProfileModel> profile = Rxn<ProfileModel>();

  @override
  void onInit() {
    super.onInit();
    // Delay session check slightly to allow bindings to initialize
    Future.delayed(const Duration(milliseconds: 1000), () {
      checkSession();
    });
  }

  Future<void> checkSession() async {
    final user = _db.currentUser;
    if (user == null) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }

    try {
      final currentProfile = await _db.getCurrentProfile();
      if (currentProfile == null) {
        // Sign out if profile doesn't exist
        await _db.logout();
        Get.offAllNamed(AppRoutes.login);
        Get.snackbar(
          'Error',
          'User profile tidak ditemukan.',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return;
      }

      if (currentProfile.status == 'nonaktif') {
        await _db.logout();
        Get.offAllNamed(AppRoutes.login);
        Get.snackbar(
          'Akses Ditolak',
          'Akun Anda telah dinonaktifkan oleh administrator.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[900],
        );
        return;
      }

      profile.value = currentProfile;

      // Routing based on role
      if (currentProfile.isAdmin) {
        Get.offAllNamed(AppRoutes.adminDashboard);
      } else if (currentProfile.isKasir) {
        // Check active shift for cashier
        final activeShift = await _db.getActiveShift(user.id);
        if (activeShift != null) {
          Get.offAllNamed(AppRoutes.cashierHome);
        } else {
          Get.offAllNamed(AppRoutes.bukaShift);
        }
      }
    } catch (e) {
      Get.offAllNamed(AppRoutes.login);
      Get.snackbar(
        'Koneksi Error',
        'Gagal memuat profil: $e',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  Future<void> handleLogin(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      Get.snackbar('Validasi', 'Email dan password tidak boleh kosong',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    
    // Bypass login for mock testing
    if (email.trim() == 'krispiinaja@gmail.com' && password == 'krispiinaja') {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 600));
      profile.value = ProfileModel(
        id: 'mock-admin-id-12345',
        namaLengkap: 'KrispiinAja Admin',
        email: 'krispiinaja@gmail.com',
        role: 'admin',
        status: 'aktif',
        createdAt: DateTime.now(),
      );
      isLoading.value = false;
      Get.offAllNamed(AppRoutes.adminDashboard);
      Get.snackbar(
        'Login Berhasil',
        'Masuk sebagai Mock Admin (Bypass)',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
      return;
    }
    
    isLoading.value = true;
    try {
      await _db.login(email.trim(), password);
      await checkSession();
    } catch (e) {
      Get.snackbar(
        'Login Gagal',
        e.toString().replaceAll('Exception:', '').trim(),
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleSignUp(String email, String password, String namaLengkap) async {
    if (email.trim().isEmpty || password.trim().isEmpty || namaLengkap.trim().isEmpty) {
      Get.snackbar('Validasi', 'Semua kolom wajib diisi',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (password.length < 6) {
      Get.snackbar('Validasi', 'Password minimal 6 karakter',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      await _db.signUp(email.trim(), password, namaLengkap.trim());
      // Supabase auto logins on signup depending on config.
      // Wait a moment for trigger execution to complete in Supabase.
      await Future.delayed(const Duration(seconds: 1));
      await checkSession();
    } catch (e) {
      Get.snackbar(
        'Registrasi Gagal',
        e.toString().replaceAll('Exception:', '').trim(),
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleLogout() async {
    isLoading.value = true;
    try {
      await _db.logout();
      profile.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      Get.snackbar('Gagal Logout', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
