import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/supabase_service.dart';
import '../../models/produk_model.dart';
import '../../models/toko_model.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';
import 'admin_dashboard_screen.dart';

class AdminProdukScreen extends StatefulWidget {
  const AdminProdukScreen({super.key});

  @override
  State<AdminProdukScreen> createState() => _AdminProdukScreenState();
}

class _AdminProdukScreenState extends State<AdminProdukScreen> {
  final SupabaseService _db = SupabaseService.instance;
  
  bool _isLoading = true;
  List<TokoModel> _tokoList = [];
  List<ProdukModel> _productList = [];
  String? _selectedTokoId; // for filtering

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      _tokoList = await _db.getAllToko();
      if (_tokoList.isNotEmpty) {
        // Default select first store
        _selectedTokoId = _tokoList.first.id;
        await _loadProducts();
      } else {
        setState(() {
          _productList = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal memuat data awal: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    if (_selectedTokoId == null) return;
    final list = await _db.getProducts(_selectedTokoId);
    setState(() {
      _productList = list;
      _isLoading = false;
    });
  }

  void _openProductDialog({ProdukModel? product}) {
    if (_tokoList.isEmpty) {
      Get.snackbar('Perhatian', 'Harap daftarkan toko cabang terlebih dahulu.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: product?.namaProduk ?? '');
    final priceCtrl = TextEditingController(text: product?.hargaJual.toStringAsFixed(0) ?? '');
    final descCtrl = TextEditingController(text: product?.deskripsi ?? '');
    
    String? currentTokoId = product?.tokoId ?? _selectedTokoId;
    String? selectedPhotoUrl = product?.fotoUrl;
    
    // For handling image picks
    Uint8List? pickedFileBytes;
    String? pickedFileName;
    bool isUploadingImg = false;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          
          Future<void> pickImage() async {
            final ImagePicker picker = ImagePicker();
            final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (image != null) {
              final bytes = await image.readAsBytes();
              setDialogState(() {
                pickedFileBytes = bytes;
                pickedFileName = "${DateTime.now().millisecondsSinceEpoch}_${image.name}";
                selectedPhotoUrl = null; // override URL with bytes preview
              });
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              product == null ? "Tambah Produk Menu" : "Ubah Detail Menu",
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toko Selector
                    DropdownButtonFormField<String>(
                      value: currentTokoId,
                      decoration: const InputDecoration(labelText: "Toko Cabang"),
                      items: _tokoList.map((toko) => DropdownMenuItem(
                            value: toko.id,
                            child: Text(toko.namaToko, style: const TextStyle(fontSize: 13)),
                          )).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          currentTokoId = val;
                        });
                      },
                      validator: (v) => v == null ? 'Pilih toko wajib' : null,
                    ),
                    const SizedBox(height: 12),

                    // Name
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: "Nama Produk", hintText: "e.g. Ayam Geprek Krispi"),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama produk wajib' : null,
                    ),
                    const SizedBox(height: 12),

                    // Price
                    TextFormField(
                      controller: priceCtrl,
                      decoration: const InputDecoration(labelText: "Harga Jual (Rp)", hintText: "e.g. 15000"),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => v == null || v.trim().isEmpty ? 'Harga produk wajib' : null,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: "Deskripsi (Opsional)"),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Image picker block
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: pickedFileBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(pickedFileBytes!, fit: BoxFit.cover),
                                )
                              : selectedPhotoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(selectedPhotoUrl!, fit: BoxFit.cover),
                                    )
                                  : const Icon(Icons.add_photo_alternate_rounded, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: isUploadingImg ? null : pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: AppColors.textDark,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: const Text("Pilih Foto", style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text("BATAL", style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: isUploadingImg
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => isUploadingImg = true);
                          
                          try {
                            String? finalPhotoUrl = selectedPhotoUrl;
                            
                            // If user picked a new file, upload it first
                            if (pickedFileBytes != null && pickedFileName != null) {
                              finalPhotoUrl = await _db.uploadImage(pickedFileBytes!, pickedFileName!);
                            }

                            final double price = double.tryParse(priceCtrl.text) ?? 0;

                            if (product == null) {
                              await _db.createProduct(
                                tokoId: currentTokoId!,
                                nama: nameCtrl.text.trim(),
                                harga: price,
                                deskripsi: descCtrl.text.trim(),
                                fotoUrl: finalPhotoUrl,
                              );
                              Get.back(); // close dialog first
                              _loadProducts(); // reload
                              Get.snackbar(
                                'Sukses',
                                'Produk berhasil dibuat.',
                                backgroundColor: Colors.green[100],
                                colorText: Colors.green[900],
                              );
                            } else {
                              await _db.updateProduct(
                                id: product.id,
                                tokoId: currentTokoId!,
                                nama: nameCtrl.text.trim(),
                                harga: price,
                                deskripsi: descCtrl.text.trim(),
                                fotoUrl: finalPhotoUrl,
                                status: product.status,
                              );
                              Get.back(); // close dialog first
                              _loadProducts(); // reload
                              Get.snackbar(
                                'Sukses',
                                'Produk berhasil diubah.',
                                backgroundColor: Colors.green[100],
                                colorText: Colors.green[900],
                              );
                            }
                          } catch (e) {
                            Get.snackbar('Gagal Menyimpan', e.toString());
                          } finally {
                            setDialogState(() => isUploadingImg = false);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: isUploadingImg
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SIMPAN"),
              ),
            ],
          );
        }
      ),
      barrierDismissible: false,
    );
  }

  void _deleteProduct(String id) {
    Get.defaultDialog(
      title: "Hapus Menu?",
      middleText: "Produk menu yang dihapus tidak dapat dipulihkan. Lanjutkan?",
      textCancel: "Batal",
      textConfirm: "Hapus",
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () async {
        Get.back();
        setState(() => _isLoading = true);
        try {
          await _db.deleteProduct(id);
          Get.snackbar('Sukses', 'Produk berhasil dihapus');
          _loadProducts();
        } catch (e) {
          Get.snackbar('Gagal', e.toString());
          setState(() => _isLoading = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Kelola Produk Menu",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      drawer: const AdminDrawer(currentRoute: AppRoutes.adminProduk),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        onPressed: () => _openProductDialog(),
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(
        children: [
          // Store Selector dropdown filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Pilih Toko Cabang:",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedTokoId,
                      hint: const Text("Pilih Toko", style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textDark),
                      items: _tokoList.map((t) => DropdownMenuItem<String?>(
                            value: t.id,
                            child: Text(t.namaToko),
                          )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTokoId = val;
                          _isLoading = true;
                        });
                        _loadProducts();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product List view
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _tokoList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_rounded, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              "Harap tambahkan Toko Cabang terlebih dahulu.",
                              style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : _productList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fastfood_rounded, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                const Text(
                                  "Belum ada menu produk terdaftar di toko ini",
                                  style: TextStyle(fontFamily: 'Poppins', color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _productList.length,
                            itemBuilder: (context, index) {
                              final p = _productList[index];
                              return Card(
                                elevation: 0.5,
                                color: AppColors.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    children: [
                                      // Image preview
                                      Container(
                                        width: 55,
                                        height: 55,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[150],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: p.fotoUrl != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(p.fotoUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.fastfood_rounded, color: Colors.grey)),
                                              )
                                            : const Icon(Icons.fastfood_rounded, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 14),

                                      // Detail
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.namaProduk,
                                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                            ),
                                            Text(
                                              formatIDR(p.hargaJual),
                                              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Text("Status: ", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  p.isTersedia ? "Tersedia" : "Habis",
                                                  style: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: p.isTersedia ? AppColors.green : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Actions
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                                            onPressed: () => _openProductDialog(product: p),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_rounded, color: AppColors.primary, size: 20),
                                            onPressed: () => _deleteProduct(p.id),
                                          ),
                                        ],
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
