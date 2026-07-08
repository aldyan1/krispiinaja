import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/shift_controller.dart';
import '../../utils/constants.dart';

class TutupShiftScreen extends StatefulWidget {
  const TutupShiftScreen({super.key});

  @override
  State<TutupShiftScreen> createState() => _TutupShiftScreenState();
}

class _TutupShiftScreenState extends State<TutupShiftScreen> {
  final _uangFisikController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _selisih = 0;
  double _expectedTotal = 0;

  @override
  void initState() {
    super.initState();
    final shift = ShiftController.to.activeShift.value;
    if (shift != null) {
      _expectedTotal = shift.totalSeharusnya;
      _selisih = -_expectedTotal; // default when physical cash is 0
    }
    _uangFisikController.addListener(_calculateDiscrepancy);
  }

  @override
  void dispose() {
    _uangFisikController.removeListener(_calculateDiscrepancy);
    _uangFisikController.dispose();
    super.dispose();
  }

  void _calculateDiscrepancy() {
    final text = _uangFisikController.text;
    final val = double.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    setState(() {
      _selisih = val - _expectedTotal;
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final double val = double.tryParse(_uangFisikController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
      ShiftController.to.handleCloseShift(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shiftController = ShiftController.to;
    final shift = shiftController.activeShift.value;

    if (shift == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Tidak ada shift aktif.", style: TextStyle(fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text("Kembali"),
              )
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Tutup Shift Kasir",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Shift Summary Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ringkasan Shift Berjalan",
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow("Waktu Buka", dateFormat.format(shift.waktuBuka)),
                    _buildSummaryRow("Modal Awal", formatIDR(shift.modalAwal)),
                    _buildSummaryRow("Penjualan Tunai (Shift ini)", formatIDR(shift.totalPenjualanTunai)),
                    _buildSummaryRow("Total Pengeluaran", formatIDR(shift.totalPengeluaran)),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      "Uang Seharusnya di Laci",
                      formatIDR(shift.totalSeharusnya),
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cash Audit Input Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Penghitungan Uang Fisik",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Masukkan total jumlah uang kertas/koin fisik yang ada di dalam laci kasir saat ini.",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 20),

                      // Physical cash input
                      TextFormField(
                        controller: _uangFisikController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        decoration: InputDecoration(
                          labelText: "Total Uang Fisik",
                          prefixText: "Rp ",
                          prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Uang fisik wajib diisi';
                          }
                          final cleanVal = double.tryParse(value.replaceAll(RegExp(r'\D'), ''));
                          if (cleanVal == null || cleanVal < 0) {
                            return 'Jumlah tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Reactive Discrepancy indicator
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _selisih == 0
                              ? Colors.green.withOpacity(0.08)
                              : _selisih > 0
                                  ? Colors.blue.withOpacity(0.08)
                                  : Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selisih == 0
                                ? Colors.green.withOpacity(0.3)
                                : _selisih > 0
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selisih == 0
                                  ? "Uang Kas Seimbang"
                                  : _selisih > 0
                                      ? "Kelebihan Uang Kas (Surplus)"
                                      : "Selisih Uang Kas (Defisit)",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _selisih == 0
                                    ? Colors.green[800]
                                    : _selisih > 0
                                        ? Colors.blue[800]
                                        : Colors.red[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatIDR(_selisih.abs()),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: _selisih == 0
                                    ? Colors.green[800]
                                    : _selisih > 0
                                        ? Colors.blue[800]
                                        : Colors.red[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tutup Shift Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: Obx(() {
                          final loading = shiftController.isLoading.value;
                          return ElevatedButton(
                            onPressed: loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                                  )
                                : const Text(
                                    "TUTUP SHIFT KASIR",
                                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isTotal ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
