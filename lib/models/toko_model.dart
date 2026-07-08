class TokoModel {
  final String id;
  final String namaToko;
  final String lokasi;
  final String nomorTelepon;
  final bool statusAktif;
  final double uangLaci;
  final DateTime createdAt;

  TokoModel({
    required this.id,
    required this.namaToko,
    required this.lokasi,
    required this.nomorTelepon,
    required this.statusAktif,
    required this.uangLaci,
    required this.createdAt,
  });

  factory TokoModel.fromJson(Map<String, dynamic> json) {
    return TokoModel(
      id: json['id'] as String,
      namaToko: json['nama_toko'] as String,
      lokasi: json['lokasi'] as String,
      nomorTelepon: json['nomor_telepon'] as String,
      statusAktif: json['status_aktif'] as bool? ?? true,
      uangLaci: (json['uang_laci'] as num? ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_toko': namaToko,
      'lokasi': lokasi,
      'nomor_telepon': nomorTelepon,
      'status_aktif': statusAktif,
      'uang_laci': uangLaci,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
