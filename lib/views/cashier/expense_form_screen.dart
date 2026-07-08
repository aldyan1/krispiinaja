import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/shift_controller.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _db = SupabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  final _nominalController = TextEditingController();
  final _deskripsiController = TextEditingController();

  Map<String, dynamic>? _editData;
  bool _isEdit = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Check if arguments were passed (edit mode)
    if (Get.arguments != null && Get.arguments is Map<String, dynamic>) {
      _editData = Get.arguments as Map<String, dynamic>;
      _isEdit = true;
      
      final double nominal = (_editData!['nominal'] as num? ?? 0).toDouble();
      _nominalController.text = nominal.toStringAsFixed(0);
      _deskripsiController.text = _editData!['deskripsi'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _nominalController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = AuthController.to;
    final shift = ShiftController.to;
    final profile = auth.profile.value;
    final activeShift = shift.activeShift.value;

    if (profile == null) {
      Get.snackbar('Error', 'Sesi Anda kedaluwarsa.', backgroundColor: Colors.red[100], colorText: Colors.red[900]);
      return;
    }

    if (activeShift == null) {
      Get.snackbar(
        'Shift Tidak Aktif',
        'Anda harus membuka laci shift kasir terlebih dahulu untuk mencatat pengeluaran.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    final double nominal = double.parse(_nominalController.text);
    final String desc = _deskripsiController.text.trim();

    setState(() => _isSaving = true);
    try {
      if (_isEdit) {
        final String docId = _editData!['id'] as String;
        await _db.updatePengeluaran(
          id: docId,
          nominal: nominal,
          deskripsi: desc,
        );
      } else {
        await _db.createPengeluaran(
          shiftId: activeShift.id,
          tokoId: profile.tokoId!,
          kasirId: profile.id,
          nominal: nominal,
          deskripsi: desc,
        );
      }

      // Reload active shift locally to show corrected stats
      await shift.loadActiveShift(profile.id);

      Get.back(result: true); // return true to trigger refresh
      Get.snackbar(
        'Sukses',
        _isEdit ? 'Catatan pengeluaran diperbarui.' : 'Pengeluaran berhasil dicatat.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );
    } catch (e) {
      Get.snackbar(
        'Gagal Menyimpan',
        e.toString().replaceAll('Exception:', '').trim(),
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _setAmount(double amount) {
    setState(() {
      _nominalController.text = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEdit ? "Edit Pengeluaran" : "Catat Pengeluaran Baru",
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 1,
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Rincian Pengeluaran",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Divider(height: 24),

                      // Nominal field
                      TextFormField(
                        controller: _nominalController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        decoration: InputDecoration(
                          labelText: "Nominal (Rp)",
                          prefixText: "Rp ",
                          prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nominal pengeluaran wajib diisi';
                          }
                          final d = double.tryParse(value);
                          if (d == null || d <= 0) {
                            return 'Nominal tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Quick select nominal suggestions
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildShortcutChip(5000, "5rb"),
                          _buildShortcutChip(10000, "10rb"),
                          _buildShortcutChip(20000, "20rb"),
                          _buildShortcutChip(50000, "50rb"),
                          _buildShortcutChip(100000, "100rb"),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Description field
                      TextFormField(
                        controller: _deskripsiController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Keperluan / Deskripsi",
                          hintText: "Contoh: Beli es batu, isi gas tabung, parkir kurir...",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Keperluan pengeluaran wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                                )
                              : const Text(
                                  "SIMPAN CATATAN",
                                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutChip(double val, String label) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
      ),
      backgroundColor: AppColors.primary.withOpacity(0.06),
      side: const BorderSide(color: Colors.transparent),
      onPressed: () => _setAmount(val),
    );
  }
}
