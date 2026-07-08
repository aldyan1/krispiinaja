import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../services/supabase_service.dart';
import '../../models/toko_model.dart';
import '../../models/shift_model.dart';
import '../../models/transaksi_model.dart';
import '../../models/produk_model.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final SupabaseService _db = SupabaseService.instance;
  
  bool _isLoading = true;
  List<TokoModel> _tokoList = [];
  String? _selectedTokoId; // null means 'Semua Toko'
  
  // Dashboard Metrics
  double _todaySales = 0;
  int _todayTransactions = 0;
  int _activeCashiersCount = 0;
  String _topProduct = '-';
  int _topProductQty = 0;
  double _todayRevenue = 0;
  double _drawerExpectedCash = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load store list
      _tokoList = await _db.getAllToko();
      
      // 2. Fetch transaction metrics today
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final transactions = await _db.getTransactions(
        tokoId: _selectedTokoId,
        startDate: todayStart,
        endDate: todayEnd,
      );
      
      _todayTransactions = transactions.length;
      _todaySales = transactions.fold(0.0, (sum, tx) => sum + tx.total);
      
      // Income equals total sales
      _todayRevenue = _todaySales;

      // 3. Fetch active cash drawers (shifts)
      final allShifts = await _db.getShiftHistory(_selectedTokoId);
      final activeShifts = allShifts.where((s) => s.isOpen).toList();
      _activeCashiersCount = activeShifts.map((s) => s.kasirId).toSet().length;
      _drawerExpectedCash = activeShifts.fold(0.0, (sum, s) => sum + s.totalSeharusnya);

      // 4. Calculate top product
      // Fetch details of today's transactions
      final Map<String, int> productSales = {};
      for (var tx in transactions) {
        // Fetch items for each transaction
        final fullTx = await _db.getTransactionById(tx.id);
        if (fullTx.items != null) {
          for (var item in fullTx.items!) {
            productSales[item.namaProduk] = (productSales[item.namaProduk] ?? 0) + item.qty;
          }
        }
      }

      if (productSales.isNotEmpty) {
        final sorted = productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        _topProduct = sorted.first.key;
        _topProductQty = sorted.first.value;
      } else {
        _topProduct = '-';
        _topProductQty = 0;
      }

    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminDashboard),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Halo, Admin",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.textDark),
                      ),
                      Text(
                        "Pantau performa bisnis KrispiinAja hari ini.",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  // Store selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedTokoId,
                        hint: const Text("Semua Toko", style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textDark),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text("Semua Toko"),
                          ),
                          ..._tokoList.map((toko) => DropdownMenuItem<String?>(
                                value: toko.id,
                                child: Text(toko.namaToko),
                              )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedTokoId = val;
                          });
                          _loadDashboardData();
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ))
              else ...[
                // Metrics grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.45,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildMetricCard(
                      "Penjualan Hari Ini",
                      formatIDR(_todaySales),
                      Icons.trending_up_rounded,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      "Total Transaksi",
                      "$_todayTransactions TRX",
                      Icons.receipt_long_rounded,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      "Kasir Aktif",
                      "$_activeCashiersCount Orang",
                      Icons.people_rounded,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      "Pendapatan Bersih",
                      formatIDR(_todayRevenue),
                      Icons.account_balance_wallet_rounded,
                      Colors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Detailed full width stats
                _buildDrawerExpectedCashCard(),
                const SizedBox(height: 16),
                _buildTopProductCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerExpectedCashCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.all_inbox_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Ringkasan Uang Laci Aktif", style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    formatIDR(_drawerExpectedCash),
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProductCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.star_rounded, color: Colors.amber),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Produk Terlaris Hari Ini", style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    _topProduct,
                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                  ),
                  if (_topProductQty > 0)
                    Text(
                      "Terjual $_topProductQty porsi",
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.green, fontWeight: FontWeight.bold),
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

// Global Drawer Component
class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final auth = AuthController.to;

    return Drawer(
      child: Container(
        color: AppColors.surface,
        child: Column(
          children: [
            // Drawer Header (Custom Centered Design)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 50, bottom: 24),
              decoration: const BoxDecoration(
                color: AppColors.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(8),
                    alignment: Alignment.center,
                    child: Image.asset(
                      'assets/images/pok.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Admin Krispiinaja",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Options
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.dashboard_rounded,
                    title: "Dashboard",
                    route: AppRoutes.adminDashboard,
                  ),
                  _buildDrawerItem(
                    icon: Icons.store_rounded,
                    title: "Kelola Toko (Cabang)",
                    route: AppRoutes.adminToko,
                  ),
                  _buildDrawerItem(
                    icon: Icons.fastfood_rounded,
                    title: "Kelola Produk Menu",
                    route: AppRoutes.adminProduk,
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_rounded,
                    title: "Kelola Kasir",
                    route: AppRoutes.adminKasir,
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long_rounded,
                    title: "Monitoring Transaksi",
                    route: AppRoutes.adminTransaksi,
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    title: "Laporan Penjualan",
                    route: AppRoutes.adminLaporan,
                  ),
                  _buildDrawerItem(
                    icon: Icons.monetization_on_rounded,
                    title: "Kelola Uang Laci",
                    route: AppRoutes.adminUangLaci,
                  ),
                ],
              ),
            ),

            const Divider(),
            // Logout
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.primary),
              title: const Text(
                "Keluar",
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Get.back();
                auth.handleLogout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String route,
  }) {
    final bool isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textDark,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.06),
      onTap: () {
        if (isSelected) {
          Get.back();
        } else {
          Get.offAllNamed(route);
        }
      },
    );
  }
}
