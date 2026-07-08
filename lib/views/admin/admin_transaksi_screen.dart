import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/transaksi_model.dart';
import '../../models/toko_model.dart';
import '../../models/profile_model.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';
import 'admin_dashboard_screen.dart';

class AdminTransaksiScreen extends StatefulWidget {
  const AdminTransaksiScreen({super.key});

  @override
  State<AdminTransaksiScreen> createState() => _AdminTransaksiScreenState();
}

class _AdminTransaksiScreenState extends State<AdminTransaksiScreen> {
  final SupabaseService _db = SupabaseService.instance;
  
  bool _isLoading = true;
  List<TransaksiModel> _transactions = [];
  List<TokoModel> _tokoList = [];
  List<ProfileModel> _kasirList = [];
  
  // Filters
  String? _selectedTokoId;
  String? _selectedKasirId;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _tokoList = await _db.getAllToko();
      _kasirList = await _db.getAllCashiers();
      
      // Default: last 30 days
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
      _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      await _loadTransactions();
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data filter: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final list = await _db.getTransactions(
        tokoId: _selectedTokoId,
        kasirId: _selectedKasirId,
        startDate: _startDate,
        endDate: _endDate,
      );
      setState(() {
        _transactions = list;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat transaksi: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
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
        _startDate = picked.start;
        _endDate = DateTime(picked.end.year, picked.end.month, picked.end.day, 23, 59, 59);
      });
      _loadTransactions();
    }
  }

  void _showTransactionDetails(TransaksiModel tx) async {
    // Show loading indicator
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );
    
    try {
      final fullTx = await _db.getTransactionById(tx.id);
      Get.back(); // close loading

      // Show details dialog
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(20),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Struk Penjualan",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  const Divider(height: 20),
                  _buildDetailRow("No Transaksi", fullTx.nomorTransaksi),
                  _buildDetailRow("Tanggal", DateFormat('dd-MM-yyyy HH:mm').format(fullTx.createdAt)),
                  _buildDetailRow("Kasir", fullTx.namaKasir ?? '-'),
                  _buildDetailRow("Toko Cabang", fullTx.namaToko ?? '-'),
                  _buildDetailRow("Pembayaran", fullTx.metodePembayaran.toUpperCase()),
                  const Divider(height: 20),
                  
                  // Items
                  if (fullTx.items != null)
                    ...fullTx.items!.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.namaProduk, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text("${item.qty} x ${formatIDR(item.hargaProduk)}", style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Text(formatIDR(item.subtotal), style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                        
                  const Divider(height: 20),
                  _buildDetailRow("Total", formatIDR(fullTx.total), isBold: true),
                  _buildDetailRow("Bayar", formatIDR(fullTx.jumlahBayar)),
                  _buildDetailRow("Kembalian", formatIDR(fullTx.kembalian)),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text("TUTUP", style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      );
    } catch (e) {
      Get.back(); // close loading
      Get.snackbar('Error', 'Gagal memuat detail transaksi: $e');
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
    final dateDisplayFormat = DateFormat('dd-MM-yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Monitoring Transaksi",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Filter Tanggal',
          ),
        ],
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminTransaksi),
      body: Column(
        children: [
          // Filter Panel
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Column(
              children: [
                // Dropdowns Row
                Row(
                  children: [
                    // Toko
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedTokoId,
                            isExpanded: true,
                            hint: const Text("Toko: Semua", style: TextStyle(fontSize: 11)),
                            style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text("Toko: Semua")),
                              ..._tokoList.map((t) => DropdownMenuItem(value: t.id, child: Text(t.namaToko))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedTokoId = val;
                              });
                              _loadTransactions();
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Kasir
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedKasirId,
                            isExpanded: true,
                            hint: const Text("Kasir: Semua", style: TextStyle(fontSize: 11)),
                            style: const TextStyle(fontSize: 11, color: AppColors.textDark),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text("Kasir: Semua")),
                              ..._kasirList.map((k) => DropdownMenuItem(value: k.id, child: Text(k.namaLengkap))),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _selectedKasirId = val;
                              });
                              _loadTransactions();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Selected Date range feedback
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _startDate != null && _endDate != null
                          ? "Rentang: ${dateDisplayFormat.format(_startDate!)} s/d ${dateDisplayFormat.format(_endDate!)}"
                          : "Rentang: Semua",
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedTokoId = null;
                          _selectedKasirId = null;
                          final now = DateTime.now();
                          _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
                          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
                        });
                        _loadTransactions();
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                      child: const Text("Reset Filter", style: TextStyle(fontSize: 11, color: AppColors.primary)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              "Transaksi tidak ditemukan",
                              style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final tx = _transactions[index];
                          return Card(
                            elevation: 0.5,
                            color: AppColors.surface,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
                              onTap: () => _showTransactionDetails(tx),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tx.nomorTransaksi,
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                  ),
                                  Text(
                                    formatIDR(tx.total),
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 13, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${tx.namaToko} • Kasir: ${tx.namaKasir}",
                                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                      ),
                                      Text(
                                        tx.metodePembayaran.toUpperCase(),
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(tx.createdAt),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
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
    );
  }
}
