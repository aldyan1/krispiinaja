import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/supabase_service.dart';
import '../../models/profile_model.dart';
import '../../models/toko_model.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';
import 'admin_dashboard_screen.dart';

class AdminKasirScreen extends StatefulWidget {
  const AdminKasirScreen({super.key});

  @override
  State<AdminKasirScreen> createState() => _AdminKasirScreenState();
}

class _AdminKasirScreenState extends State<AdminKasirScreen> {
  final SupabaseService _db = SupabaseService.instance;
  
  bool _isLoading = true;
  List<ProfileModel> _cashierList = [];
  List<TokoModel> _tokoList = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _tokoList = await _db.getAllToko();
      await _loadCashiers();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCashiers() async {
    final list = await _db.getAllCashiers();
    setState(() {
      _cashierList = list;
      _isLoading = false;
    });
  }

  Future<void> _toggleCashierStatus(ProfileModel cashier) async {
    final newStatus = cashier.isActive ? 'nonaktif' : 'aktif';
    try {
      await _db.deactivateCashier(cashier.id, newStatus);
      Get.snackbar('Sukses', 'Status kasir diubah menjadi ${newStatus.toUpperCase()}');
      _loadCashiers();
    } catch (e) {
      Get.snackbar('Gagal', e.toString());
    }
  }

  void _openCashierDialog({ProfileModel? cashier}) {
    if (_tokoList.isEmpty) {
      Get.snackbar('Perhatian', 'Harap daftarkan cabang toko terlebih dahulu.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: cashier?.namaLengkap ?? '');
    final emailCtrl = TextEditingController(text: cashier?.email ?? '');
    final passCtrl = TextEditingController();
    
    String? selectedTokoId = cashier?.tokoId ?? _tokoList.first.id;
    String status = cashier?.status ?? 'aktif';
    
    bool isSaving = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              cashier == null ? "Tambah Akun Kasir" : "Ubah Detail Kasir",
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Nama Lengkap"),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama lengkap wajib' : null,
                    ),
                    const SizedBox(height: 12),

                    // Email
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: "Email Login"),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email wajib';
                        if (!GetUtils.isEmail(v.trim())) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password (required for new cashier only)
                    if (cashier == null)
                      TextFormField(
                        controller: passCtrl,
                        decoration: const InputDecoration(labelText: "Password (Min. 6 Karakter)"),
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password wajib';
                          if (v.length < 6) return 'Password minimal 6 karakter';
                          return null;
                        },
                      ),
                    const SizedBox(height: 12),

                    // Store Selector
                    DropdownButtonFormField<String>(
                      value: selectedTokoId,
                      decoration: const InputDecoration(labelText: "Ditugaskan di Toko"),
                      items: _tokoList.map((toko) => DropdownMenuItem(
                            value: toko.id,
                            child: Text(toko.namaToko, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedTokoId = val;
                        });
                      },
                      validator: (v) => v == null ? 'Pilih toko penugasan' : null,
                    ),
                    
                    if (cashier != null) ...[
                      const SizedBox(height: 16),
                      // Status Selector (Active/Inactive)
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: "Status Akun"),
                        items: const [
                          DropdownMenuItem(value: 'aktif', child: Text("Aktif (Dapat Login)", style: TextStyle(color: AppColors.green, fontSize: 13))),
                          DropdownMenuItem(value: 'nonaktif', child: Text("Nonaktif (Dilarang Login)", style: TextStyle(color: Colors.red, fontSize: 13))),
                        ],
                        onChanged: (val) {
                          setDialogState(() {
                            status = val ?? 'aktif';
                          });
                        },
                      ),
                    ]
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
                onPressed: isSaving
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isSaving = true);
                          try {
                            if (cashier == null) {
                              // Call RPC to create auth user
                              await _db.createCashier(
                                email: emailCtrl.text.trim(),
                                password: passCtrl.text,
                                nama: nameCtrl.text.trim(),
                                tokoId: selectedTokoId!,
                              );
                              Get.back(); // close dialog first
                              _loadCashiers(); // reload
                              Get.snackbar(
                                'Sukses',
                                'Akun kasir berhasil dibuat.',
                                backgroundColor: Colors.green[100],
                                colorText: Colors.green[900],
                              );
                            } else {
                              // Edit cashier profile details
                              await _db.updateCashierProfile(
                                id: cashier.id,
                                nama: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                tokoId: selectedTokoId!,
                                status: status,
                              );
                              Get.back(); // close dialog first
                              _loadCashiers(); // reload
                              Get.snackbar(
                                'Sukses',
                                'Data akun kasir berhasil diubah.',
                                backgroundColor: Colors.green[100],
                                colorText: Colors.green[900],
                              );
                            }
                          } catch (e) {
                            Get.snackbar('Gagal Menyimpan', e.toString().replaceAll('Exception:', '').trim(),
                                backgroundColor: Colors.red[100], colorText: Colors.red[900]);
                          } finally {
                            setDialogState(() => isSaving = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SIMPAN"),
              ),
            ],
          );
        }
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Kelola Kasir",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminKasir),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _openCashierDialog(),
        child: const Icon(Icons.add_rounded),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _cashierList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        "Belum ada akun kasir terdaftar",
                        style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cashierList.length,
                  itemBuilder: (context, index) {
                    final cashier = _cashierList[index];
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
                              cashier.namaLengkap,
                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: cashier.isActive ? AppColors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cashier.isActive ? "Aktif" : "Nonaktif",
                                style: TextStyle(
                                    color: cashier.isActive ? AppColors.green : Colors.red,
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
                                const Icon(Icons.email_outlined, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(cashier.email, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.store_rounded, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(cashier.namaToko ?? 'Belum Ditugaskan', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                              onPressed: () => _openCashierDialog(cashier: cashier),
                            ),
                            IconButton(
                              icon: Icon(
                                cashier.isActive ? Icons.block_flipped : Icons.check_circle_outline_rounded,
                                color: cashier.isActive ? AppColors.primary : AppColors.green,
                                size: 20,
                              ),
                              onPressed: () => _toggleCashierStatus(cashier),
                              tooltip: cashier.isActive ? 'Nonaktifkan' : 'Aktifkan',
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
