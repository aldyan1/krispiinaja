class TransaksiModel {
  final String id;
  final String nomorTransaksi;
  final String? shiftId;
  final String kasirId;
  final String tokoId;
  final String metodePembayaran; // 'tunai' | 'transfer' | 'qris'
  final double total;
  final double jumlahBayar;
  final double kembalian;
  final DateTime createdAt;
  
  // Nested relation items
  List<DetailTransaksiModel>? items;

  // Joined fields
  final String? namaKasir;
  final String? namaToko;
  final String? tokoLokasi;
  final String? tokoTelepon;

  TransaksiModel({
    required this.id,
    required this.nomorTransaksi,
    this.shiftId,
    required this.kasirId,
    required this.tokoId,
    required this.metodePembayaran,
    required this.total,
    required this.jumlahBayar,
    required this.kembalian,
    required this.createdAt,
    this.items,
    this.namaKasir,
    this.namaToko,
    this.tokoLokasi,
    this.tokoTelepon,
  });

  factory TransaksiModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['detail_transaksi'] as List?;
    List<DetailTransaksiModel>? parsedItems = rawItems != null
        ? rawItems.map((item) => DetailTransaksiModel.fromJson(item)).toList()
        : null;

    return TransaksiModel(
      id: json['id'] as String,
      nomorTransaksi: json['nomor_transaksi'] as String,
      shiftId: json['shift_id'] as String?,
      kasirId: json['kasir_id'] as String,
      tokoId: json['toko_id'] as String,
      metodePembayaran: json['metode_pembayaran'] as String,
      total: (json['total'] as num).toDouble(),
      jumlahBayar: (json['jumlah_bayar'] as num).toDouble(),
      kembalian: (json['kembalian'] as num? ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: parsedItems,
      namaKasir: json['profiles']?['nama_lengkap'] as String?,
      namaToko: json['toko']?['nama_toko'] as String?,
      tokoLokasi: json['toko']?['lokasi'] as String?,
      tokoTelepon: json['toko']?['nomor_telepon'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomor_transaksi': nomorTransaksi,
      'shift_id': shiftId,
      'kasir_id': kasirId,
      'toko_id': tokoId,
      'metode_pembayaran': metodePembayaran,
      'total': total,
      'jumlah_bayar': jumlahBayar,
      'kembalian': kembalian,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class DetailTransaksiModel {
  final String id;
  final String transaksiId;
  final String? produkId;
  final String namaProduk;
  final double hargaProduk;
  final int qty;
  final double subtotal;
  final DateTime createdAt;

  DetailTransaksiModel({
    required this.id,
    required this.transaksiId,
    this.produkId,
    required this.namaProduk,
    required this.hargaProduk,
    required this.qty,
    required this.subtotal,
    required this.createdAt,
  });

  factory DetailTransaksiModel.fromJson(Map<String, dynamic> json) {
    return DetailTransaksiModel(
      id: json['id'] as String,
      transaksiId: json['transaksi_id'] as String,
      produkId: json['produk_id'] as String?,
      namaProduk: json['nama_produk'] as String,
      hargaProduk: (json['harga_produk'] as num).toDouble(),
      qty: json['qty'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaksi_id': transaksiId,
      'produk_id': produkId,
      'nama_produk': namaProduk,
      'harga_produk': hargaProduk,
      'qty': qty,
      'subtotal': subtotal,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
