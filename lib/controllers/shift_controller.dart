import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../models/shift_model.dart';
import 'auth_controller.dart';
import '../utils/app_routes.dart';

class ShiftController extends GetxController {
  static ShiftController to = Get.find();

  final SupabaseService _db = SupabaseService.instance;
  
  var isLoading = false.obs;
  Rxn<ShiftModel> activeShift = Rxn<ShiftModel>();

  @override
  void onInit() {
    super.onInit();
    final profile = AuthController.to.profile.value;
    if (profile != null && profile.isKasir) {
      loadActiveShift(profile.id);
    }
  }

  Future<void> loadActiveShift(String kasirId) async {
    isLoading.value = true;
    try {
      final shift = await _db.getActiveShift(kasirId);
      activeShift.value = shift;
    } catch (e) {
      debugPrint('Load Active Shift Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleOpenShift(double modalAwal) async {
    final profile = AuthController.to.profile.value;
    if (profile == null) {
      Get.snackbar('Error', 'Sesi Anda telah kedaluwarsa. Silakan login kembali.');
      return;
    }
    if (profile.tokoId == null) {
      Get.snackbar(
        'Toko Belum Ditugaskan',
        'Akun kasir Anda belum ditugaskan ke toko manapun. Hubungi Admin.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    isLoading.value = true;
    try {
      final shift = await _db.openShift(profile.id, profile.tokoId!, modalAwal);
      activeShift.value = shift;
      Get.offAllNamed(AppRoutes.cashierHome);
      Get.snackbar(
        'Shift Dimulai',
        'Laci kasir dibuka dengan modal awal ${modalAwal.toStringAsFixed(0)}',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } catch (e) {
      Get.snackbar('Gagal Buka Shift', e.toString(),
          backgroundColor: Colors.red[100], colorText: Colors.red[900]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleCloseShift(double uangFisik) async {
    final shift = activeShift.value;
    if (shift == null) {
      Get.snackbar('Error', 'Tidak ada shift aktif untuk ditutup.');
      return;
    }

    isLoading.value = true;
    try {
      // Re-fetch shift stats from database to get latest penjualan tunai
      final currentDbShift = await _db.getActiveShift(shift.kasirId);
      final activeShiftDetails = currentDbShift ?? shift;

      await _db.closeShift(
        shiftId: activeShiftDetails.id,
        tokoId: activeShiftDetails.tokoId,
        uangFisik: uangFisik,
        totalPenjualanTunai: activeShiftDetails.totalPenjualanTunai,
        totalPengeluaran: activeShiftDetails.totalPengeluaran,
        totalSeharusnya: activeShiftDetails.totalSeharusnya,
      );

      activeShift.value = null;
      Get.offAllNamed(AppRoutes.bukaShift);
      Get.snackbar(
        'Shift Ditutup',
        'Uang laci shift berhasil direkonsiliasi.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } catch (e) {
      Get.snackbar('Gagal Tutup Shift', e.toString(),
          backgroundColor: Colors.red[100], colorText: Colors.red[900]);
    } finally {
      isLoading.value = false;
    }
  }
}
