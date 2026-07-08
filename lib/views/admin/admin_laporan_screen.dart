import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/toko_model.dart';
import '../../models/transaksi_model.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';
import 'admin_dashboard_screen.dart';

class AdminLaporanScreen extends StatefulWidget {
  const AdminLaporanScreen({super.key});

  @override
  State<AdminLaporanScreen> createState() => _AdminLaporanScreenState();
}

class _AdminLaporanScreenState extends State<AdminLaporanScreen> {
  final SupabaseService _db = SupabaseService.instance;
  
  bool _isLoading = true;
  List<TokoModel> _tokoList = [];
  String? _selectedTokoId;
  
  // Report range
  String _dateRangePreset = 'today'; // 'today' | 'weekly' | 'monthly' | 'custom'
  DateTime? _startDate;
  DateTime? _endDate;

  // Laporan data
  double _totalOmset = 0;
  int _totalTransactionsCount = 0;
  List<MapEntry<String, int>> _topProducts = [];
  Map<String, double> _paymentMethodsShare = {};
  List<MapEntry<String, double>> _bestCashiers = [];

  @override
  void initState() {
    super.initState();
    _setPresetDates('today');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _tokoList = await _db.getAllToko();
      await _generateReport();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data awal: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setPresetDates(String preset) {
    final now = DateTime.now();
    setState(() {
      _dateRangePreset = preset;
      if (preset == 'today') {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'weekly') {
        // start of week (Monday)
        final daysToSub = now.weekday - 1;
        _startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSub));
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      } else if (preset == 'monthly') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      }
    });
  }

  Future<void> _generateReport() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch transactions within range
      final transactions = await _db.getTransactions(
        tokoId: _selectedTokoId,
        startDate: _startDate,
        endDate: _endDate,
      );

      _totalTransactionsCount = transactions.length;
      _totalOmset = transactions.fold(0.0, (sum, tx) => sum + tx.total);

      // 2. Calculations maps
      final Map<String, int> productSales = {};
      final Map<String, double> paymentMethods = {};
      final Map<String, double> cashierSales = {};

      for (var tx in transactions) {
        // Payment methods
        final m = tx.metodePembayaran.toUpperCase();
        paymentMethods[m] = (paymentMethods[m] ?? 0.0) + tx.total;

        // Cashier sales
        final kasirNama = tx.namaKasir ?? 'Tanpa Nama';
        cashierSales[kasirNama] = (cashierSales[kasirNama] ?? 0.0) + tx.total;

        // Fetch transaction items detail sequentially
        final fullTx = await _db.getTransactionById(tx.id);
        if (fullTx.items != null) {
          for (var item in fullTx.items!) {
            productSales[item.namaProduk] = (productSales[item.namaProduk] ?? 0) + item.qty;
          }
        }
      }

      // Sort products
      _topProducts = productSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Sort cashiers
      _bestCashiers = cashierSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Payment share
      _paymentMethodsShare = paymentMethods;

    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses laporan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        end: _endDate ?? DateTime.now(),
      ),
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRangePreset = 'custom';
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplayFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Laporan Penjualan",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminLaporan),
      body: RefreshIndicator(
        onRefresh: _generateReport,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Filter Panel
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  children: [
                    // Toko Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pilih Cabang:",
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedTokoId,
                              hint: const Text("Semua Cabang", style: TextStyle(fontSize: 12)),
                              style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text("Semua Cabang")),
                                ..._tokoList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.namaToko))),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedTokoId = val;
                                });
                                _generateReport();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date presets buttons
                    Row(
                      children: [
                        _buildPresetBtn('today', "Hari Ini"),
                        const SizedBox(width: 6),
                        _buildPresetBtn('weekly', "Minggu Ini"),
                        const SizedBox(width: 6),
                        _buildPresetBtn('monthly', "Bulan Ini"),
                        const SizedBox(width: 6),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectCustomDateRange(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _dateRangePreset == 'custom' ? AppColors.primary : AppColors.textDark,
                              side: BorderSide(
                                color: _dateRangePreset == 'custom' ? AppColors.primary : AppColors.border,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            icon: const Icon(Icons.date_range_rounded, size: 14),
                            label: const Text("Kustom", style: TextStyle(fontSize: 10, fontFamily: 'Poppins')),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_startDate != null && _endDate != null) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Periode: ${dateDisplayFormat.format(_startDate!)} s/d ${dateDisplayFormat.format(_endDate!)}",
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ]
                  ],
                ),
              ),

              // Report data content
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else ...[
                // Main figures
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Total Omset card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 3))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TOTAL OMSET PENJUALAN",
                              style: TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatIDR(_totalOmset),
                              style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Jumlah Transaksi", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                                Text("$_totalTransactionsCount TRX", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Best product list
                      _buildCardSection(
                        title: "Daftar Produk Terlaris",
                        icon: Icons.star_rounded,
                        iconColor: Colors.amber,
                        child: _topProducts.isEmpty
                            ? const Center(child: Text("Belir ada produk terjual", style: TextStyle(fontSize: 12, color: AppColors.textMuted)))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _topProducts.length.clamp(0, 5),
                                itemBuilder: (context, index) {
                                  final entry = _topProducts[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("${index + 1}. ${entry.key}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        Text("${entry.value} porsi", style: const TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Payment methods share
                      _buildCardSection(
                        title: "Metode Pembayaran Terbanyak",
                        icon: Icons.pie_chart_rounded,
                        iconColor: Colors.blue,
                        child: _paymentMethodsShare.isEmpty
                            ? const Center(child: Text("Belum ada data pembayaran", style: TextStyle(fontSize: 12, color: AppColors.textMuted)))
                            : Column(
                                children: _paymentMethodsShare.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.key, style: const TextStyle(fontSize: 12)),
                                        Text(formatIDR(entry.value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Best Cashiers performance list
                      _buildCardSection(
                        title: "Kinerja Kasir (Volume Penjualan)",
                        icon: Icons.people_rounded,
                        iconColor: Colors.teal,
                        child: _bestCashiers.isEmpty
                            ? const Center(child: Text("Belum ada data kasir", style: TextStyle(fontSize: 12, color: AppColors.textMuted)))
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _bestCashiers.length.clamp(0, 5),
                                itemBuilder: (context, index) {
                                  final entry = _bestCashiers[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("${index + 1}. ${entry.key}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                        Text(formatIDR(entry.value), style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetBtn(String preset, String label) {
    final bool isSelected = _dateRangePreset == preset;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          _setPresetDates(preset);
          _generateReport();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.surface,
          foregroundColor: isSelected ? AppColors.onPrimary : AppColors.textDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Card(
      elevation: 0.5,
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
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}
