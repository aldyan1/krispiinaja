import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/shift_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';

class BukaShiftScreen extends StatefulWidget {
  const BukaShiftScreen({super.key});

  @override
  State<BukaShiftScreen> createState() => _BukaShiftScreenState();
}

class _BukaShiftScreenState extends State<BukaShiftScreen> {
  final _modalController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _modalController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final double val = double.tryParse(_modalController.text.replaceAll(RegExp(r'\D'), '')) ?? 0;
      ShiftController.to.handleOpenShift(val);
    }
  }

  void _setAmount(double amount) {
    setState(() {
      _modalController.text = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;
    final shiftController = ShiftController.to;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Buka Shift Kasir",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => auth.handleLogout(),
            tooltip: 'Logout',
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Welcome cashier card
              Obx(() {
                final userProfile = auth.profile.value;
                if (userProfile == null) return const SizedBox();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userProfile.namaLengkap,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              userProfile.namaToko ?? "Cabang Belum Ditugaskan",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Open Shift Form
              Card(
                elevation: 2,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Masukkan Modal Awal Uang Laci",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Pencatatan modal awal membantu memantau keakuratan uang kas fisik saat penutupan shift.",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Starting capital input
                        TextFormField(
                          controller: _modalController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          decoration: InputDecoration(
                            labelText: "Modal Awal (Rupiah)",
                            prefixText: "Rp ",
                            prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Modal awal wajib diisi';
                            }
                            final cleanVal = double.tryParse(value.replaceAll(RegExp(r'\D'), ''));
                            if (cleanVal == null || cleanVal < 0) {
                              return 'Jumlah modal tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Shortcuts
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildShortcutButton(100000, "100k"),
                            _buildShortcutButton(200000, "200k"),
                            _buildShortcutButton(500000, "500k"),
                            _buildShortcutButton(1000000, "1.0M"),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
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
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.onPrimary,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "BUKA LACI KASIR",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
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
      ),
    );
  }

  Widget _buildShortcutButton(double value, String label) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
      ),
      backgroundColor: AppColors.primary.withOpacity(0.06),
      side: const BorderSide(color: Colors.transparent),
      onPressed: () => _setAmount(value),
    );
  }
}
