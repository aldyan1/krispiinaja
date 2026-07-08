class ProdukModel {
  final String id;
  final String tokoId;
  final String namaProduk;
  final double hargaJual;
  final String? deskripsi;
  final String? fotoUrl;
  final String status; // 'tersedia' | 'habis'
  final DateTime createdAt;

  // Helper field
  final String? namaToko;

  ProdukModel({
    required this.id,
    required this.tokoId,
    required this.namaProduk,
    required this.hargaJual,
    this.deskripsi,
    this.fotoUrl,
    required this.status,
    required this.createdAt,
    this.namaToko,
  });

  bool get isTersedia => status == 'tersedia';

  factory ProdukModel.fromJson(Map<String, dynamic> json) {
    return ProdukModel(
      id: json['id'] as String,
      tokoId: json['toko_id'] as String,
      namaProduk: json['nama_produk'] as String,
      hargaJual: (json['harga_jual'] as num).toDouble(),
      deskripsi: json['deskripsi'] as String?,
      fotoUrl: json['foto_url'] as String?,
      status: json['status'] as String? ?? 'tersedia',
      createdAt: DateTime.parse(json['created_at'] as String),
      namaToko: json['toko']?['nama_toko'] as String?, // handles join queries
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toko_id': tokoId,
      'nama_produk': namaProduk,
      'harga_jual': hargaJual,
      'deskripsi': deskripsi,
      'foto_url': fotoUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ProdukModel copyWith({
    String? id,
    String? tokoId,
    String? namaProduk,
    double? hargaJual,
    String? deskripsi,
    String? fotoUrl,
    String? status,
    DateTime? createdAt,
    String? namaToko,
  }) {
    return ProdukModel(
      id: id ?? this.id,
      tokoId: tokoId ?? this.tokoId,
      namaProduk: namaProduk ?? this.namaProduk,
      hargaJual: hargaJual ?? this.hargaJual,
      deskripsi: deskripsi ?? this.deskripsi,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      namaToko: namaToko ?? this.namaToko,
    );
  }
}
