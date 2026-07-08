import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cashier_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';
import 'checkout_dialog.dart';

class CashierHomeScreen extends StatelessWidget {
  const CashierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Put Controller
    final controller = Get.put(CashierController());
    final auth = AuthController.to;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Obx(() {
          final profile = auth.profile.value;
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile?.namaToko ?? "KrispiinAja POS",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Kasir: ${profile?.namaLengkap ?? ''}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Obx(() {
              final profile = auth.profile.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
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
                      "Selamat Bekerja,",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile?.namaLengkap ?? "Kasir",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (profile?.role ?? 'kasir').toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            ListTile(
              leading: const Icon(Icons.storefront_rounded, color: AppColors.primary),
              title: const Text("Kasir Utama", style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () => Get.back(),
            ),
            ListTile(
              leading: const Icon(Icons.analytics_outlined, color: AppColors.primary),
              title: const Text("Catatan Keuangan", style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.catatanKeuangan);
              },
            ),
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined, color: AppColors.primary),
              title: const Text("Catat Pengeluaran", style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.catatPengeluaran);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded, color: AppColors.primary),
              title: const Text("Transaksi Hari Ini", style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.transaksiHariIni);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.primary),
              title: const Text("Keluar Akun", style: TextStyle(fontFamily: 'Poppins', fontSize: 14)),
              onTap: () {
                Get.back();
                auth.handleLogout();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar Area
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: "Cari menu produk...",
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                fillColor: AppColors.background,
                filled: true,
              ),
            ),
          ),

          // Product List Grid
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (controller.filteredProducts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        "Menu tidak ditemukan",
                        style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: controller.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = controller.filteredProducts[index];
                  return Card(
                    elevation: 1,
                    color: AppColors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => controller.addToCart(product),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product Image
                          Expanded(
                            child: Stack(
                              children: [
                                SizedBox.expand(
                                  child: Container(
                                    color: Colors.grey[200],
                                    child: product.fotoUrl != null
                                        ? Image.network(
                                            product.fotoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const Icon(Icons.fastfood_rounded, size: 40, color: Colors.grey),
                                          )
                                        : const Icon(Icons.fastfood_rounded, size: 40, color: Colors.grey),
                                  ),
                                ),
                                // Availability Badge
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: product.isTersedia 
                                          ? AppColors.green.withOpacity(0.9) 
                                          : Colors.grey.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      product.isTersedia ? "Tersedia" : "Habis",
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Detail
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.namaProduk,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatIDR(product.hargaJual),
                                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                ),
                                const Divider(height: 16),
                                // Quick toggle switch for availability
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Status", style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                    SizedBox(
                                      height: 20,
                                      width: 36,
                                      child: Switch(
                                        value: product.isTersedia,
                                        activeColor: AppColors.green,
                                        onChanged: (val) {
                                          controller.toggleProductAvailability(product.id, !val);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
      // Cart Summary floating bottom sheet launcher bar
      bottomNavigationBar: Obx(() {
        final totalQty = controller.totalItemsInCart;
        if (totalQty == 0) return const SizedBox();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -2))
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$totalQty Item",
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
                      ),
                      Text(
                        formatIDR(controller.cartTotalPrice),
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openCartSheet(context, controller),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                  label: const Text(
                    "KERANJANG",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // Cart Bottom Sheet
  void _openCartSheet(BuildContext context, CashierController controller) {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Keranjang Belanja",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      controller.clearCart();
                      Get.back();
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.primary, size: 18),
                    label: const Text("Bersihkan", style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins', fontSize: 12)),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Item List
              Flexible(
                child: Obx(() {
                  final cartItems = controller.cart.entries.toList();
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final entry = cartItems[index];
                      final product = controller.products.firstWhereOrNull((p) => p.id == entry.key);
                      if (product == null) return const SizedBox();

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.namaProduk,
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                  ),
                                  Text(
                                    formatIDR(product.hargaJual),
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            // Counter
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary, size: 20),
                                  onPressed: () => controller.decreaseQty(product.id),
                                ),
                                Container(
                                  constraints: const BoxConstraints(minWidth: 24),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "${entry.value}",
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.green, size: 20),
                                  onPressed: () => controller.addToCart(product),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              const Divider(height: 24),

              // Checkout details summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Transaksi", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14)),
                  Obx(() => Text(
                        formatIDR(controller.cartTotalPrice),
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                      )),
                ],
              ),
              const SizedBox(height: 16),

              // Checkout submit
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // close bottomsheet
                    Get.dialog(const CheckoutDialog(), barrierDismissible: false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "LANJUT PEMBAYARAN",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}
