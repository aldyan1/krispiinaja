import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';

class CatatPengeluaranScreen extends StatefulWidget {
  const CatatPengeluaranScreen({super.key});

  @override
  State<CatatPengeluaranScreen> createState() => _CatatPengeluaranScreenState();
}

class _CatatPengeluaranScreenState extends State<CatatPengeluaranScreen> {
  final SupabaseService _db = SupabaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _expenses = [];
  double _totalExpensesToday = 0;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final profile = AuthController.to.profile.value;
      if (profile != null && profile.tokoId != null) {
        final list = await _db.getTodayExpenses(profile.tokoId!);
        double total = 0;
        for (var item in list) {
          total += (item['nominal'] as num? ?? 0).toDouble();
        }
        setState(() {
          _expenses = list;
          _totalExpensesToday = total;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat pengeluaran: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteExpense(String id) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Hapus Pengeluaran", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text("Apakah Anda yakin ingin menghapus catatan pengeluaran ini? Uang laci toko akan bertambah kembali."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("BATAL", style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text("HAPUS"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _db.deletePengeluaran(id);
        
        // Refresh local shift data to keep local UI consistent if shift is active
        final profile = AuthController.to.profile.value;
        if (profile != null) {
          // Trigger shift reload
          final shiftController = Get.find<dynamic>(); // Or access ShiftController directly
          if (shiftController != null) {
            try {
              await shiftController.loadActiveShift(profile.id);
            } catch (_) {}
          }
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pengeluaran berhasil dihapus.'),
            backgroundColor: AppColors.green,
          ),
        );
        _loadExpenses();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pengeluaran: $e'),
            backgroundColor: AppColors.primary,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final profile = AuthController.to.profile.value;
    final storeName = profile?.namaToko ?? 'Toko';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Catat Pengeluaran",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadExpenses,
              color: AppColors.primary,
              child: Column(
                children: [
                  // Prominent Total Expenses Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Store badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                storeName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "PENGELUARAN HARI INI",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          formatIDR(_totalExpensesToday),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Total ${_expenses.length} kali pengeluaran",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List of Expenses
                  Expanded(
                    child: _expenses.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.monetization_on_outlined, size: 64, color: Colors.grey[400]),
                                    const SizedBox(height: 12),
                                    Text(
                                      "Belum ada pengeluaran hari ini.",
                                      style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600], fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _expenses.length,
                            itemBuilder: (context, index) {
                              final expense = _expenses[index];
                              final String docId = expense['id'] as String;
                              final double nominal = (expense['nominal'] as num? ?? 0).toDouble();
                              final String desc = expense['deskripsi'] as String? ?? '-';
                              final DateTime createdAt = DateTime.parse(expense['created_at'] as String);
                              final String cashierName = expense['profiles']?['nama_lengkap'] as String? ?? 'Kasir';

                              return Card(
                                elevation: 1,
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left indicator icon
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.arrow_outward_rounded, color: AppColors.primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),

                                      // Middle Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formatIDR(nominal),
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              desc,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 12,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Text(
                                                  "${timeFormat.format(createdAt.toLocal())} • Oleh: $cashierName",
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Right action buttons (Edit & Delete)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                                            onPressed: () async {
                                              final updated = await Get.toNamed(
                                                AppRoutes.expenseForm,
                                                arguments: expense,
                                              );
                                              if (updated == true) {
                                                _loadExpenses();
                                              }
                                            },
                                          ),
                                          IconButton(
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(6),
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.primary, size: 20),
                                            onPressed: () => _deleteExpense(docId),
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
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Get.toNamed(AppRoutes.expenseForm);
          if (created == true) {
            _loadExpenses();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Catat Pengeluaran",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
