import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';
import '../models/toko_model.dart';
import '../models/profile_model.dart';
import '../models/produk_model.dart';
import '../models/shift_model.dart';
import '../models/transaksi_model.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, String namaLengkap) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'nama_lengkap': namaLengkap},
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<ProfileModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;
    
    final response = await _client
        .from('profiles')
        .select('*, toko(*)')
        .eq('id', user.id)
        .maybeSingle();
        
    if (response == null) return null;
    return ProfileModel.fromJson(response);
  }

  // ==========================================
  // MANAJEMEN TOKO (ADMIN)
  // ==========================================

  Future<List<TokoModel>> getAllToko() async {
    final List response = await _client
        .from('toko')
        .select()
        .order('nama_toko', ascending: true);
    return response.map((json) => TokoModel.fromJson(json)).toList();
  }

  Future<void> createToko(String nama, String lokasi, String telp, bool aktif) async {
    await _client.from('toko').insert({
      'nama_toko': nama,
      'lokasi': lokasi,
      'nomor_telepon': telp,
      'status_aktif': aktif,
    });
  }

  Future<void> updateToko(String id, String nama, String lokasi, String telp, bool aktif) async {
    await _client.from('toko').update({
      'nama_toko': nama,
      'lokasi': lokasi,
      'nomor_telepon': telp,
      'status_aktif': aktif,
    }).eq('id', id);
  }

  Future<void> deleteToko(String id) async {
    // Check if store has transactions
    final txs = await _client.from('transaksi').select('id').eq('toko_id', id).limit(1);
    if (txs.isNotEmpty) {
      throw Exception('Toko tidak dapat dihapus karena memiliki riwayat transaksi.');
    }
    await _client.from('toko').delete().eq('id', id);
  }

  // ==========================================
  // MANAJEMEN KASIR (ADMIN)
  // ==========================================

  Future<List<ProfileModel>> getAllCashiers() async {
    final List response = await _client
        .from('profiles')
        .select('*, toko(*)')
        .eq('role', 'kasir')
        .order('nama_lengkap', ascending: true);
    return response.map((json) => ProfileModel.fromJson(json)).toList();
  }

  Future<void> createCashier({
    required String email,
    required String password,
    required String nama,
    required String tokoId,
  }) async {
    final response = await _client.rpc(
      'admin_create_cashier',
      params: {
        'cashier_email': email,
        'cashier_password': password,
        'cashier_nama': nama,
        'cashier_toko_id': tokoId,
      },
    );
    
    if (response != null && response['success'] == false) {
      throw Exception(response['error'] ?? 'Gagal membuat kasir baru');
    }
  }

  Future<void> updateCashierProfile({
    required String id,
    required String nama,
    required String email,
    required String tokoId,
    required String status,
  }) async {
    // Update profile
    await _client.from('profiles').update({
      'nama_lengkap': nama,
      'email': email,
      'toko_id': tokoId,
      'status': status,
    }).eq('id', id);
  }

  Future<void> deactivateCashier(String id, String status) async {
    await _client.from('profiles').update({'status': status}).eq('id', id);
  }

  // ==========================================
  // MANAJEMEN PRODUK (ADMIN & KASIR)
  // ==========================================

  Future<List<ProdukModel>> getProducts(String? tokoId) async {
    var query = _client.from('produk').select('*, toko(*)');
    if (tokoId != null) {
      query = query.eq('toko_id', tokoId);
    }
    final List response = await query.order('nama_produk', ascending: true);
    return response.map((json) => ProdukModel.fromJson(json)).toList();
  }

  Future<void> createProduct({
    required String tokoId,
    required String nama,
    required double harga,
    String? deskripsi,
    String? fotoUrl,
  }) async {
    await _client.from('produk').insert({
      'toko_id': tokoId,
      'nama_produk': nama,
      'harga_jual': harga,
      'deskripsi': deskripsi,
      'foto_url': fotoUrl,
      'status': 'tersedia',
    });
  }

  Future<void> updateProduct({
    required String id,
    required String tokoId,
    required String nama,
    required double harga,
    String? deskripsi,
    String? fotoUrl,
    required String status,
  }) async {
    await _client.from('produk').update({
      'toko_id': tokoId,
      'nama_produk': nama,
      'harga_jual': harga,
      'deskripsi': deskripsi,
      'foto_url': fotoUrl,
      'status': status,
    }).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('produk').delete().eq('id', id);
  }

  Future<void> updateProductStatus(String id, String status) async {
    await _client.from('produk').update({'status': status}).eq('id', id);
  }

  // File Upload
  Future<String?> uploadImage(Uint8List fileBytes, String fileName) async {
    try {
      final path = 'product_photos/$fileName';
      await _client.storage.from('produk-images').uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(upsert: true, cacheControl: '3600'),
          );
      return _client.storage.from('produk-images').getPublicUrl(path);
    } catch (e) {
      // In case bucket is not created or permissions error, fallback gracefully
      debugPrint('Storage Upload Error: $e');
      return null;
    }
  }

  // ==========================================
  // SHIFT MANAGEMENT (CASH DRAWER)
  // ==========================================

  Future<ShiftModel?> getActiveShift(String kasirId) async {
    final response = await _client
        .from('shift_kasir')
        .select('*, profiles(nama_lengkap), toko(nama_toko)')
        .eq('kasir_id', kasirId)
        .eq('status', 'buka')
        .maybeSingle();
    if (response == null) return null;
    return ShiftModel.fromJson(response);
  }

  Future<ShiftModel> openShift(String kasirId, String tokoId, double modalAwal) async {
    // 1. Update toko's uang_laci to modalAwal
    await _client.from('toko').update({
      'uang_laci': modalAwal,
    }).eq('id', tokoId);

    // 2. Insert shift_kasir
    final response = await _client.from('shift_kasir').insert({
      'kasir_id': kasirId,
      'toko_id': tokoId,
      'modal_awal': modalAwal,
      'total_penjualan_tunai': 0,
      'total_pengeluaran': 0,
      'total_seharusnya': modalAwal,
      'status': 'buka',
    }).select('*, profiles(nama_lengkap), toko(nama_toko)').single();
    return ShiftModel.fromJson(response);
  }

  Future<void> closeShift({
    required String shiftId,
    required String tokoId,
    required double uangFisik,
    required double totalPenjualanTunai,
    required double totalPengeluaran,
    required double totalSeharusnya,
  }) async {
    final double selisih = uangFisik - totalSeharusnya;

    // 1. Update shift status to closed
    await _client.from('shift_kasir').update({
      'waktu_tutup': DateTime.now().toIso8601String(),
      'total_penjualan_tunai': totalPenjualanTunai,
      'total_pengeluaran': totalPengeluaran,
      'total_seharusnya': totalSeharusnya,
      'uang_fisik': uangFisik,
      'selisih': selisih,
      'status': 'tutup',
    }).eq('id', shiftId);

    // 2. Sync toko's uang_laci to counted physical cash
    await _client.from('toko').update({
      'uang_laci': uangFisik,
    }).eq('id', tokoId);
  }

  Future<List<ShiftModel>> getShiftHistory(String? tokoId) async {
    var query = _client.from('shift_kasir').select('*, profiles(nama_lengkap), toko(nama_toko)');
    if (tokoId != null) {
      query = query.eq('toko_id', tokoId);
    }
    final List response = await query.order('waktu_buka', ascending: false);
    return response.map((json) => ShiftModel.fromJson(json)).toList();
  }

  // ==========================================
  // MANAJEMEN UANG LACI (ADMIN)
  // ==========================================

  Future<double> calculateExpectedUangLaci(String tokoId) async {
    // 1. Get the latest shift for this store
    final latestShiftResponse = await _client
        .from('shift_kasir')
        .select()
        .eq('toko_id', tokoId)
        .order('waktu_buka', ascending: false)
        .limit(1)
        .maybeSingle();

    if (latestShiftResponse == null) {
      // No shifts ever, let's sum all cash sales and subtract all expenses
      final List txSumResponse = await _client
          .from('transaksi')
          .select('total')
          .eq('toko_id', tokoId)
          .eq('metode_pembayaran', 'tunai');
      final double totalSales = txSumResponse.fold(0.0, (sum, item) => sum + (item['total'] as num).toDouble());

      final List expSumResponse = await _client
          .from('pengeluaran')
          .select('nominal')
          .eq('toko_id', tokoId);
      final double totalExpenses = expSumResponse.fold(0.0, (sum, item) => sum + (item['nominal'] as num).toDouble());

      return totalSales - totalExpenses;
    }

    final String status = latestShiftResponse['status'] as String;
    final double startingCash = (latestShiftResponse[status == 'buka' ? 'modal_awal' : 'uang_fisik'] as num?)?.toDouble() ?? 0.0;
    final String timeFrom = latestShiftResponse[status == 'buka' ? 'waktu_buka' : 'waktu_tutup'] as String;

    // Fetch cash sales after timeFrom
    final List txSumResponse = await _client
        .from('transaksi')
        .select('total')
        .eq('toko_id', tokoId)
        .eq('metode_pembayaran', 'tunai')
        .gt('created_at', timeFrom);
    final double totalSales = txSumResponse.fold(0.0, (sum, item) => sum + (item['total'] as num).toDouble());

    // Fetch expenses after timeFrom
    final List expSumResponse = await _client
        .from('pengeluaran')
        .select('nominal')
        .eq('toko_id', tokoId)
        .gt('created_at', timeFrom);
    final double totalExpenses = expSumResponse.fold(0.0, (sum, item) => sum + (item['nominal'] as num).toDouble());

    return startingCash + totalSales - totalExpenses;
  }

  Future<void> syncUangLaci(String tokoId) async {
    final double expected = await calculateExpectedUangLaci(tokoId);
    await _client.from('toko').update({
      'uang_laci': expected,
    }).eq('id', tokoId);
  }

  Future<void> updateUangLaci(String tokoId, double nominal) async {
    await _client.from('toko').update({
      'uang_laci': nominal,
    }).eq('id', tokoId);
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  Future<TransaksiModel> createTransaction({
    required String? shiftId,
    required String kasirId,
    required String tokoId,
    required String metodePembayaran,
    required double total,
    required double jumlahBayar,
    required double kembalian,
    required List<Map<String, dynamic>> items, // contains produk_id, nama_produk, harga_produk, qty, subtotal
  }) async {
    // Generate transaction number: TRX-YYYYMMDD-HHMMSS
    final now = DateTime.now();
    final formattedDate = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final formattedTime = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    final String trxNo = "TRX-$formattedDate-$formattedTime";

    // 1. Insert transaction
    final trxResponse = await _client.from('transaksi').insert({
      'nomor_transaksi': trxNo,
      'shift_id': shiftId,
      'kasir_id': kasirId,
      'toko_id': tokoId,
      'metode_pembayaran': metodePembayaran.toLowerCase(),
      'total': total,
      'jumlah_bayar': jumlahBayar,
      'kembalian': kembalian,
      'created_at': now.toIso8601String(),
    }).select('*, profiles(nama_lengkap), toko(nama_toko, lokasi, nomor_telepon)').single();

    final trxId = trxResponse['id'] as String;

    // 2. Insert items details
    final List<Map<String, dynamic>> detailRows = items.map((item) => {
      'transaksi_id': trxId,
      'produk_id': item['produk_id'],
      'nama_produk': item['nama_produk'],
      'harga_produk': item['harga_produk'],
      'qty': item['qty'],
      'subtotal': item['subtotal'],
      'created_at': now.toIso8601String(),
    }).toList();

    await _client.from('detail_transaksi').insert(detailRows);

    // 3. Update Shift cash drawer if payment is cash ('tunai')
    if (metodePembayaran.toLowerCase() == 'tunai' && shiftId != null) {
      final shiftData = await _client.from('shift_kasir').select('total_penjualan_tunai, total_seharusnya').eq('id', shiftId).single();
      final double currentCashSales = (shiftData['total_penjualan_tunai'] as num).toDouble();
      final double currentExpected = (shiftData['total_seharusnya'] as num).toDouble();

      await _client.from('shift_kasir').update({
        'total_penjualan_tunai': currentCashSales + total,
        'total_seharusnya': currentExpected + total,
      }).eq('id', shiftId);
    }

    // Fetch full transaction details with items
    final fullTrx = await _client
        .from('transaksi')
        .select('*, profiles(nama_lengkap), toko(nama_toko, lokasi, nomor_telepon), detail_transaksi(*)')
        .eq('id', trxId)
        .single();

    return TransaksiModel.fromJson(fullTrx);
  }

  Future<List<TransaksiModel>> getTransactions({
    String? tokoId,
    String? kasirId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = _client.from('transaksi').select('*, profiles(nama_lengkap), toko(nama_toko, lokasi, nomor_telepon)');
    
    if (tokoId != null) query = query.eq('toko_id', tokoId);
    if (kasirId != null) query = query.eq('kasir_id', kasirId);
    if (startDate != null) {
      query = query.gte('created_at', startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.lte('created_at', endDate.toIso8601String());
    }

    final List response = await query.order('created_at', ascending: false);
    return response.map((json) => TransaksiModel.fromJson(json)).toList();
  }

  Future<TransaksiModel> getTransactionById(String transactionId) async {
    final response = await _client
        .from('transaksi')
        .select('*, profiles(nama_lengkap), toko(nama_toko, lokasi, nomor_telepon), detail_transaksi(*)')
        .eq('id', transactionId)
        .single();
    return TransaksiModel.fromJson(response);
  }

  Future<void> createPengeluaran({
    required String shiftId,
    required String tokoId,
    required String kasirId,
    required double nominal,
    required String deskripsi,
  }) async {
    await _client.from('pengeluaran').insert({
      'shift_id': shiftId,
      'toko_id': tokoId,
      'kasir_id': kasirId,
      'nominal': nominal,
      'deskripsi': deskripsi,
    });
  }

  Future<void> updatePengeluaran({
    required String id,
    required double nominal,
    required String deskripsi,
  }) async {
    await _client.from('pengeluaran').update({
      'nominal': nominal,
      'deskripsi': deskripsi,
    }).eq('id', id);
  }

  Future<void> deletePengeluaran(String id) async {
    await _client.from('pengeluaran').delete().eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getTodayExpenses(String tokoId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final List response = await _client
        .from('pengeluaran')
        .select('*, profiles(nama_lengkap)')
        .eq('toko_id', tokoId)
        .gte('created_at', todayStart.toIso8601String())
        .lte('created_at', todayEnd.toIso8601String())
        .order('created_at', ascending: false);
    return response.cast<Map<String, dynamic>>();
  }

  Future<Map<String, double>> getTodayFinancialSummary(String tokoId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    // 1. Fetch store for current uang_laci
    final storeRes = await _client
        .from('toko')
        .select('uang_laci')
        .eq('id', tokoId)
        .single();
    final double uangLaci = (storeRes['uang_laci'] as num? ?? 0).toDouble();

    // 2. Fetch today's transactions for this store
    final txRes = await _client
        .from('transaksi')
        .select('total, metode_pembayaran')
        .eq('toko_id', tokoId)
        .gte('created_at', todayStart.toIso8601String())
        .lte('created_at', todayEnd.toIso8601String());

    double cashIncome = 0;
    double danaIncome = 0; // QRIS + Transfer
    for (var tx in txRes) {
      final double total = (tx['total'] as num? ?? 0).toDouble();
      final String method = (tx['metode_pembayaran'] as String? ?? 'tunai').toLowerCase();
      if (method == 'tunai') {
        cashIncome += total;
      } else {
        danaIncome += total; // qris / transfer
      }
    }

    // 3. Fetch today's expenses for this store
    final expRes = await _client
        .from('pengeluaran')
        .select('nominal')
        .eq('toko_id', tokoId)
        .gte('created_at', todayStart.toIso8601String())
        .lte('created_at', todayEnd.toIso8601String());

    double totalPengeluaran = 0;
    for (var exp in expRes) {
      totalPengeluaran += (exp['nominal'] as num? ?? 0).toDouble();
    }

    return {
      'uang_laci': uangLaci,
      'pendapatan_dana': danaIncome,
      'pendapatan_keseluruhan': cashIncome + danaIncome,
      'total_pengeluaran': totalPengeluaran,
    };
  }
}
