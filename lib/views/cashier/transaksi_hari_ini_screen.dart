import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../models/transaksi_model.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';

class TransaksiHariIniScreen extends StatefulWidget {
  const TransaksiHariIniScreen({super.key});

  @override
  State<TransaksiHariIniScreen> createState() => _TransaksiHariIniScreenState();
}

class _TransaksiHariIniScreenState extends State<TransaksiHariIniScreen> {
  final SupabaseService _db = SupabaseService.instance;
  bool _isLoading = true;
  List<TransaksiModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final profile = AuthController.to.profile.value;
      if (profile != null && profile.tokoId != null) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

        final list = await _db.getTransactions(
          tokoId: profile.tokoId!,
          startDate: todayStart,
          endDate: todayEnd,
        );
        setState(() {
          _transactions = list;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat transaksi: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          "Transaksi Hari Ini",
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
              onRefresh: _loadTransactions,
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store badge
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            storeName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  "Belum ada transaksi hari ini.",
                                  style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              
                              // Color coding based on payment method
                              Color methodColor;
                              IconData methodIcon;
                              if (tx.metodePembayaran.toLowerCase() == 'tunai') {
                                methodColor = AppColors.green;
                                methodIcon = Icons.money_rounded;
                              } else if (tx.metodePembayaran.toLowerCase() == 'qris') {
                                methodColor = Colors.blue;
                                methodIcon = Icons.qr_code_rounded;
                              } else {
                                methodColor = Colors.orange;
                                methodIcon = Icons.account_balance_rounded;
                              }

                              return Card(
                                elevation: 1,
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: methodColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(methodIcon, color: methodColor, size: 20),
                                  ),
                                  title: Text(
                                    tx.nomorTransaksi,
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                  ),
                                  subtitle: Text(
                                    "${timeFormat.format(tx.createdAt.toLocal())} • ${tx.metodePembayaran.toUpperCase()}",
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted),
                                  ),
                                  trailing: Text(
                                    formatIDR(tx.total),
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                  ),
                                  onTap: () {
                                    Get.toNamed(AppRoutes.detailTransaksi, arguments: tx);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
