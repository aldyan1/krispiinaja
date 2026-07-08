import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../../models/toko_model.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';
import 'admin_dashboard_screen.dart';

class AdminTokoScreen extends StatefulWidget {
  const AdminTokoScreen({super.key});

  @override
  State<AdminTokoScreen> createState() => _AdminTokoScreenState();
}

class _AdminTokoScreenState extends State<AdminTokoScreen> {
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
      Get.snackbar('Error', 'Gagal memuat data toko: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openTokoDialog({TokoModel? toko}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: toko?.namaToko ?? '');
    final locationCtrl = TextEditingController(text: toko?.lokasi ?? '');
    final phoneCtrl = TextEditingController(text: toko?.nomorTelepon ?? '');
    bool isAktif = toko?.statusAktif ?? true;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              toko == null ? "Tambah Cabang Toko" : "Ubah Detail Toko",
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Nama Toko", hintText: "e.g. KrispiinAja - Dago"),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: "Lokasi Alamat", hintText: "e.g. Jl. Dago No. 12"),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Lokasi wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: "No. Telepon Toko", hintText: "e.g. 081234567"),
                      validator: (v) => v == null || v.trim().isEmpty ? 'No telp wajib diisi' : null,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Status Cabang Aktif", style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                        Switch(
                          value: isAktif,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setDialogState(() {
                              isAktif = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                    Get.back(); // close dialog
                    setState(() => _isLoading = true);
                    try {
                      if (toko == null) {
                        await _db.createToko(nameCtrl.text.trim(), locationCtrl.text.trim(), phoneCtrl.text.trim(), isAktif);
                        Get.snackbar('Sukses', 'Toko berhasil ditambahkan');
                      } else {
                        await _db.updateToko(toko.id, nameCtrl.text.trim(), locationCtrl.text.trim(), phoneCtrl.text.trim(), isAktif);
                        Get.snackbar('Sukses', 'Data toko berhasil diubah');
                      }
                      _loadTokoData();
                    } catch (e) {
                      Get.snackbar('Gagal Menyimpan', e.toString());
                      setState(() => _isLoading = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text("SIMPAN"),
              ),
            ],
          );
        }
      ),
      barrierDismissible: false,
    );
  }

  void _deleteToko(String id) {
    Get.defaultDialog(
      title: "Hapus Toko?",
      middleText: "Toko yang dihapus tidak dapat dipulihkan. Lanjutkan?",
      textCancel: "Batal",
      textConfirm: "Hapus",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () async {
        Get.back(); // close confirm dialog
        setState(() => _isLoading = true);
        try {
          await _db.deleteToko(id);
          Get.snackbar('Sukses', 'Toko berhasil dihapus');
          _loadTokoData();
        } catch (e) {
          Get.snackbar('Gagal Menghapus', e.toString().replaceAll('Exception:', '').trim(),
              backgroundColor: Colors.red[100], colorText: Colors.red[900]);
          setState(() => _isLoading = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Kelola Toko (Cabang)",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminToko),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _openTokoDialog(),
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tokoList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        "Belum ada cabang toko terdaftar",
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
                      elevation: 0.5,
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Text(
                              toko.namaToko,
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: toko.statusAktif ? AppColors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                toko.statusAktif ? "Aktif" : "Nonaktif",
                                style: TextStyle(
                                    color: toko.statusAktif ? AppColors.green : Colors.grey,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(toko.lokasi, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(toko.nomorTelepon, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                              onPressed: () => _openTokoDialog(toko: toko),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: AppColors.primary, size: 20),
                              onPressed: () => _deleteToko(toko.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
