import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/supabase_service.dart';
import '../models/produk_model.dart';
import '../models/transaksi_model.dart';
import 'auth_controller.dart';
import 'shift_controller.dart';
import '../utils/app_routes.dart';

class CashierController extends GetxController {
  static CashierController get to => Get.find();

  final SupabaseService _db = SupabaseService.instance;

  var isLoading = false.obs;
  var isSubmitting = false.obs;
  var products = <ProdukModel>[].obs;
  var filteredProducts = <ProdukModel>[].obs;
  
  // Cart: Map of {Product ID : Quantity}
  var cart = <String, int>{}.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    filterProducts(searchController.text);
  }

  Future<void> loadProducts() async {
    final profile = AuthController.to.profile.value;
    if (profile == null || profile.tokoId == null) return;

    isLoading.value = true;
    try {
      final list = await _db.getProducts(profile.tokoId);
      products.value = list;
      filterProducts(searchController.text);
    } catch (e) {
      debugPrint('Load Products Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void filterProducts(String query) {
    if (query.trim().isEmpty) {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products
          .where((p) => p.namaProduk.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  // Cart operations
  void addToCart(ProdukModel product) {
    if (!product.isTersedia) {
      Get.snackbar(
        'Produk Habis',
        'Produk ${product.namaProduk} sedang tidak tersedia.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
      );
      return;
    }

    final currentQty = cart[product.id] ?? 0;
    cart[product.id] = currentQty + 1;
  }

  void decreaseQty(String productId) {
    final currentQty = cart[productId] ?? 0;
    if (currentQty <= 1) {
      cart.remove(productId);
    } else {
      cart[productId] = currentQty - 1;
    }
  }

  void removeProductFromCart(String productId) {
    cart.remove(productId);
  }

  void clearCart() {
    cart.clear();
  }

  // Calculate stats
  int get totalItemsInCart {
    return cart.values.fold(0, (sum, qty) => sum + qty);
  }

  double get cartTotalPrice {
    double total = 0;
    cart.forEach((productId, qty) {
      final product = products.firstWhereOrNull((p) => p.id == productId);
      if (product != null) {
        total += product.hargaJual * qty;
      }
    });
    return total;
  }

  List<Map<String, dynamic>> get cartItemsDetail {
    final List<Map<String, dynamic>> items = [];
    cart.forEach((productId, qty) {
      final product = products.firstWhereOrNull((p) => p.id == productId);
      if (product != null) {
        items.add({
          'produk_id': product.id,
          'nama_produk': product.namaProduk,
          'harga_produk': product.hargaJual,
          'qty': qty,
          'subtotal': product.hargaJual * qty,
        });
      }
    });
    return items;
  }

  // Toggle availability status (cashier shortcut)
  Future<void> toggleProductAvailability(String productId, bool isCurrentlyAvailable) async {
    final newStatus = isCurrentlyAvailable ? 'habis' : 'tersedia';
    try {
      await _db.updateProductStatus(productId, newStatus);
      // Update local status
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = products[index].copyWith(status: newStatus);
        filterProducts(searchController.text);
      }
      Get.snackbar(
        'Status Diperbarui',
        'Menu kini ditandai sebagai ${newStatus == 'tersedia' ? 'Tersedia' : 'Habis'}',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      Get.snackbar('Gagal Update Status', e.toString());
    }
  }

  // Checkout submission
  Future<void> handleCheckout({
    required String paymentMethod,
    required double jumlahBayar,
  }) async {
    if (cart.isEmpty) {
      Get.snackbar('Keranjang Kosong', 'Tambahkan produk ke keranjang terlebih dahulu.');
      return;
    }

    final double total = cartTotalPrice;
    final double kembalian = paymentMethod.toLowerCase() == 'tunai' 
        ? jumlahBayar - total 
        : 0;

    if (paymentMethod.toLowerCase() == 'tunai' && jumlahBayar < total) {
      Get.snackbar('Pembayaran Kurang', 'Jumlah bayar tidak mencukupi total transaksi.');
      return;
    }

    final profile = AuthController.to.profile.value;
    final shift = ShiftController.to.activeShift.value;

    if (profile == null) return;

    isSubmitting.value = true;
    try {
      final TransaksiModel transaction = await _db.createTransaction(
        shiftId: shift?.id,
        kasirId: profile.id,
        tokoId: profile.tokoId!,
        metodePembayaran: paymentMethod,
        total: total,
        jumlahBayar: paymentMethod.toLowerCase() == 'tunai' ? jumlahBayar : total,
        kembalian: kembalian,
        items: cartItemsDetail,
      );

      // Reset cart
      clearCart();

      // Go to receipt page
      Get.offNamed(AppRoutes.detailTransaksi, arguments: transaction);
    } catch (e) {
      Get.snackbar('Checkout Gagal', e.toString(),
          backgroundColor: Colors.red[100], colorText: Colors.red[900]);
    } finally {
      isSubmitting.value = false;
    }
  }
}
