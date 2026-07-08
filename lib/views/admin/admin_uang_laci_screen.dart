import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../../models/toko_model.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';
import 'admin_dashboard_screen.dart';

class AdminUangLaciScreen extends StatefulWidget {
  const AdminUangLaciScreen({super.key});

  @override
  State<AdminUangLaciScreen> createState() => _AdminUangLaciScreenState();
}

class _AdminUangLaciScreenState extends State<AdminUangLaciScreen> {
  final SupabaseService _db = SupabaseService.instance;
  bool _isLoading = true;
  List<TokoModel> _tokoList = [];

  @override
  void initState() {
    super.initState();
    _loadTokoData();
  }

  Future<void> _loadTokoData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _db.getAllToko();
      setState(() {
        _tokoList = data;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data toko: $e',
          backgroundColor: Colors.red[100], colorText: Colors.red[900]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSync(String tokoId, String storeName) async {
    setState(() => _isLoading = true);
    try {
      final double expected = await _db.calculateExpectedUangLaci(tokoId);
      await _db.syncUangLaci(tokoId);
      Get.snackbar(
        'Sukses Sinkronisasi',
        'Uang laci $storeName berhasil disinkronisasi ke ${formatIDR(expected)}',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 4),
      );
      _loadTokoData();
    } catch (e) {
      Get.snackbar('Gagal', 'Gagal mensinkronisasikan uang laci: $e',
          backgroundColor: Colors.red[100], colorText: Colors.red[900]);
      setState(() => _isLoading = false);
    }
  }

  void _openEditDialog(TokoModel toko) {
    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(
        text: toko.uangLaci.toStringAsFixed(0));

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Edit Manual Uang Laci - ${toko.namaToko}",
          style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Masukkan nominal uang laci secara manual untuk menyesuaikan saldo saat ini.",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: "Nominal Uang Laci (Rp)",
                  hintText: "e.g. 500000",
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("BATAL", style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final double amount = double.tryParse(amountCtrl.text) ?? 0;
                Get.back(); // close dialog
                setState(() => _isLoading = true);
                try {
                  await _db.updateUangLaci(toko.id, amount);
                  Get.snackbar(
                    'Sukses',
                    'Uang laci ${toko.namaToko} berhasil diubah manual.',
                    backgroundColor: Colors.green[100],
                    colorText: Colors.green[900],
                  );
                  _loadTokoData();
                } catch (e) {
                  Get.snackbar('Gagal', 'Gagal mengubah uang laci: $e',
                      backgroundColor: Colors.red[100], colorText: Colors.red[900]);
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("SIMPAN"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Kelola Uang Laci Toko",
          style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminUangLaci),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadTokoData,
              color: AppColors.primary,
              child: _tokoList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.store_rounded, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            "Belum ada toko cabang terdaftar.",
                            style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _tokoList.length,
                      itemBuilder: (context, index) {
                        final toko = _tokoList[index];
                        return Card(
                          elevation: 1,
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title / Shop name
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.storefront_rounded,
                                          color: AppColors.primary, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            toko.namaToko,
                                            style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textDark),
                                          ),
                                          Text(
                                            toko.lokasi,
                                            style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                color: AppColors.textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                // Cash drawer detail
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "Uang Laci Sekarang",
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          formatIDR(toko.uangLaci),
                                          style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    // Status Badge (Active/Inactive)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: toko.statusAktif
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        toko.statusAktif ? "AKTIF" : "NON-AKTIF",
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: toko.statusAktif
                                                ? Colors.green
                                                : Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                // Action buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openEditDialog(toko),
                                        icon: const Icon(Icons.edit_rounded, size: 16),
                                        label: const Text(
                                          "Edit Manual",
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.textDark,
                                          side: const BorderSide(color: AppColors.border),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _handleSync(toko.id, toko.namaToko),
                                        icon: const Icon(Icons.sync_rounded, size: 16),
                                        label: const Text(
                                          "Sinkronisasi",
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
