import 'package:get/get.dart';
import '../views/auth/splash_screen.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/admin/admin_dashboard_screen.dart';
import '../views/admin/admin_toko_screen.dart';
import '../views/admin/admin_produk_screen.dart';
import '../views/admin/admin_kasir_screen.dart';
import '../views/admin/admin_transaksi_screen.dart';
import '../views/admin/admin_laporan_screen.dart';
import '../views/admin/admin_uang_laci_screen.dart';
import '../views/cashier/buka_shift_screen.dart';
import '../views/cashier/tutup_shift_screen.dart';
import '../views/cashier/cashier_home_screen.dart';
import '../views/cashier/detail_transaksi_screen.dart';
import '../views/cashier/catatan_keuangan_screen.dart';
import '../views/cashier/transaksi_hari_ini_screen.dart';
import '../views/cashier/catat_pengeluaran_screen.dart';
import '../views/cashier/expense_form_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  
  static const String adminDashboard = '/admin/dashboard';
  static const String adminToko = '/admin/toko';
  static const String adminProduk = '/admin/produk';
  static const String adminKasir = '/admin/kasir';
  static const String adminTransaksi = '/admin/transaksi';
  static const String adminLaporan = '/admin/laporan';
  static const String adminUangLaci = '/admin/uang-laci';
  
  static const String bukaShift = '/cashier/buka-shift';
  static const String tutupShift = '/cashier/tutup-shift';
  static const String cashierHome = '/cashier/home';
  static const String detailTransaksi = '/cashier/detail-transaksi';
  static const String catatanKeuangan = '/cashier/catatan-keuangan';
  static const String transaksiHariIni = '/cashier/transaksi-hari-ini';
  static const String catatPengeluaran = '/cashier/pengeluaran';
  static const String expenseForm = '/cashier/pengeluaran/form';

  static final routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    
    GetPage(name: adminDashboard, page: () => const AdminDashboardScreen()),
    GetPage(name: adminToko, page: () => const AdminTokoScreen()),
    GetPage(name: adminProduk, page: () => const AdminProdukScreen()),
    GetPage(name: adminKasir, page: () => const AdminKasirScreen()),
    GetPage(name: adminTransaksi, page: () => const AdminTransaksiScreen()),
    GetPage(name: adminLaporan, page: () => const AdminLaporanScreen()),
    GetPage(name: adminUangLaci, page: () => const AdminUangLaciScreen()),
    
    GetPage(name: bukaShift, page: () => const BukaShiftScreen()),
    GetPage(name: tutupShift, page: () => const TutupShiftScreen()),
    GetPage(name: cashierHome, page: () => const CashierHomeScreen()),
    GetPage(name: detailTransaksi, page: () => const DetailTransaksiScreen()),
    GetPage(name: catatanKeuangan, page: () => const CatatanKeuanganScreen()),
    GetPage(name: transaksiHariIni, page: () => const TransaksiHariIniScreen()),
    GetPage(name: catatPengeluaran, page: () => const CatatPengeluaranScreen()),
    GetPage(name: expenseForm, page: () => const ExpenseFormScreen()),
  ];
}
