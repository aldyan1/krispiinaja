import 'toko_model.dart';

class ProfileModel {
  final String id;
  final String namaLengkap;
  final String email;
  final String role; // 'admin' | 'kasir'
  final String? tokoId;
  final String status; // 'aktif' | 'nonaktif'
  final DateTime createdAt;
  
  // Custom joined field
  final String? namaToko;
  final TokoModel? toko;

  ProfileModel({
    required this.id,
    required this.namaLengkap,
    required this.email,
    required this.role,
    this.tokoId,
    required this.status,
    required this.createdAt,
    this.namaToko,
    this.toko,
  });

  bool get isAdmin => role == 'admin';
  bool get isKasir => role == 'kasir';
  bool get isActive => status == 'aktif';

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      tokoId: json['toko_id'] as String?,
      status: json['status'] as String? ?? 'aktif',
      createdAt: DateTime.parse(json['created_at'] as String),
      namaToko: json['toko']?['nama_toko'] as String?, // handles join queries
      toko: json['toko'] != null ? TokoModel.fromJson(json['toko']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'email': email,
      'role': role,
      'toko_id': tokoId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
