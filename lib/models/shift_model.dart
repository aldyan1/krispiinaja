class ShiftModel {
  final String id;
  final String kasirId;
  final String tokoId;
  final DateTime waktuBuka;
  final DateTime? waktuTutup;
  final double modalAwal;
  final double totalPenjualanTunai;
  final double totalPengeluaran;
  final double totalSeharusnya;
  final double? uangFisik;
  final double? selisih;
  final String status; // 'buka' | 'tutup'
  final DateTime createdAt;

  // Joined properties
  final String? namaKasir;
  final String? namaToko;

  ShiftModel({
    required this.id,
    required this.kasirId,
    required this.tokoId,
    required this.waktuBuka,
    this.waktuTutup,
    required this.modalAwal,
    required this.totalPenjualanTunai,
    required this.totalPengeluaran,
    required this.totalSeharusnya,
    this.uangFisik,
    this.selisih,
    required this.status,
    required this.createdAt,
    this.namaKasir,
    this.namaToko,
  });

  bool get isOpen => status == 'buka';

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      kasirId: json['kasir_id'] as String,
      tokoId: json['toko_id'] as String,
      waktuBuka: DateTime.parse(json['waktu_buka'] as String),
      waktuTutup: json['waktu_tutup'] != null
          ? DateTime.parse(json['waktu_tutup'] as String)
          : null,
      modalAwal: (json['modal_awal'] as num).toDouble(),
      totalPenjualanTunai: (json['total_penjualan_tunai'] as num? ?? 0).toDouble(),
      totalPengeluaran: (json['total_pengeluaran'] as num? ?? 0).toDouble(),
      totalSeharusnya: (json['total_seharusnya'] as num? ?? 0).toDouble(),
      uangFisik: json['uang_fisik'] != null
          ? (json['uang_fisik'] as num).toDouble()
          : null,
      selisih: json['selisih'] != null
          ? (json['selisih'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? 'buka',
      createdAt: DateTime.parse(json['created_at'] as String),
      namaKasir: json['profiles']?['nama_lengkap'] as String?, // handles join queries
      namaToko: json['toko']?['nama_toko'] as String?, // handles join queries
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kasir_id': kasirId,
      'toko_id': tokoId,
      'waktu_buka': waktuBuka.toIso8601String(),
      'waktu_tutup': waktuTutup?.toIso8601String(),
      'modal_awal': modalAwal,
      'total_penjualan_tunai': totalPenjualanTunai,
      'total_pengeluaran': totalPengeluaran,
      'total_seharusnya': totalSeharusnya,
      'uang_fisik': uangFisik,
      'selisih': selisih,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
