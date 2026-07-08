import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../services/supabase_service.dart';
import '../../utils/constants.dart';

class CatatanKeuanganScreen extends StatefulWidget {
  const CatatanKeuanganScreen({super.key});

  @override
  State<CatatanKeuanganScreen> createState() => _CatatanKeuanganScreenState();
}

class _CatatanKeuanganScreenState extends State<CatatanKeuanganScreen> {
  final SupabaseService _db = SupabaseService.instance;
  bool _isLoading = true;
  double _uangLaci = 0;
  double _pendapatanDana = 0;
  double _pendapatanKeseluruhan = 0;
  double _totalPengeluaran = 0;

  @override
  void initState() {
    super.initState();
    _loadFinancialSummary();
  }

  Future<void> _loadFinancialSummary() async {
    setState(() => _isLoading = true);
    try {
      final profile = AuthController.to.profile.value;
      if (profile != null && profile.tokoId != null) {
        final summary = await _db.getTodayFinancialSummary(profile.tokoId!);
        setState(() {
          _uangLaci = summary['uang_laci'] ?? 0;
          _pendapatanDana = summary['pendapatan_dana'] ?? 0;
          _pendapatanKeseluruhan = summary['pendapatan_keseluruhan'] ?? 0;
          _totalPengeluaran = summary['total_pengeluaran'] ?? 0;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat catatan keuangan: $e'),
          backgroundColor: AppColors.primary,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = AuthController.to.profile.value;
    final storeName = profile?.namaToko ?? 'Toko';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Catatan Keuangan",
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
              onRefresh: _loadFinancialSummary,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Store badge
                    Container(
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
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Ringkasan Keuangan",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Text(
                      "Data pendapatan dan pengeluaran di bawah dihitung berdasarkan hari ini, kecuali uang laci.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card 1: Uang Laci (Persistent)
                    _buildSummaryCard(
                      title: "Uang Laci Toko",
                      subtitle: "Uang tunai dalam laci (terus berjalan)",
                      value: _uangLaci,
                      icon: Icons.wallet_rounded,
                      iconColor: Colors.amber[800]!,
                      bgColor: Colors.amber[50]!,
                    ),
                    const SizedBox(height: 12),

                    // Card 2: Pendapatan DANA / Non-Tunai
                    _buildSummaryCard(
                      title: "Pendapatan DANA / Non-Tunai",
                      subtitle: "QRIS & Transfer masuk hari ini (direset harian)",
                      value: _pendapatanDana,
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: Colors.blue[700]!,
                      bgColor: Colors.blue[50]!,
                    ),
                    const SizedBox(height: 12),

                    // Card 3: Pendapatan Keseluruhan
                    _buildSummaryCard(
                      title: "Pendapatan Keseluruhan",
                      subtitle: "Tunai + Non-Tunai hari ini (direset harian)",
                      value: _pendapatanKeseluruhan,
                      icon: Icons.monetization_on_rounded,
                      iconColor: AppColors.green,
                      bgColor: Colors.green[50]!,
                    ),
                    const SizedBox(height: 12),

                    // Card 4: Total Pengeluaran Hari Ini
                    _buildSummaryCard(
                      title: "Total Pengeluaran Hari Ini",
                      subtitle: "Pengeluaran kas tunai hari ini (direset harian)",
                      value: _totalPengeluaran,
                      icon: Icons.trending_down_rounded,
                      iconColor: AppColors.primary,
                      bgColor: Colors.red[50]!,
                    ),
                    const SizedBox(height: 24),

                    // Note bottom card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      color: AppColors.surface,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.textMuted),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Semua pengeluaran toko dibayar cash menggunakan uang laci, sehingga mengurangi saldo Uang Laci secara langsung.",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: AppColors.textMuted,
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

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required double value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Card(
      elevation: 1,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatIDR(value),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
