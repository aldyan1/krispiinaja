import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/transaksi_model.dart';
import '../../services/pdf_service.dart';
import '../../utils/constants.dart';
import '../../utils/app_routes.dart';

class DetailTransaksiScreen extends StatefulWidget {
  const DetailTransaksiScreen({super.key});

  @override
  State<DetailTransaksiScreen> createState() => _DetailTransaksiScreenState();
}

class _DetailTransaksiScreenState extends State<DetailTransaksiScreen> {
  final _phoneController = TextEditingController();
  late TransaksiModel _trx;

  @override
  void initState() {
    super.initState();
    _trx = Get.arguments as TransaksiModel;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _shareWA() {
    PdfService.instance.shareToWhatsApp(_trx, _phoneController.text);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Get.offAllNamed(AppRoutes.cashierHome);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            "Detail Transaksi",
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.home_rounded),
            onPressed: () => Get.offAllNamed(AppRoutes.cashierHome),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Virtual Receipt Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Header
                      const Text(
                        "KRISPIINAJA",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary, letterSpacing: 0.5),
                      ),
                      Text(
                        _trx.namaToko ?? "Toko KrispiinAja",
                        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      if (_trx.tokoLokasi != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            _trx.tokoLokasi!,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (_trx.tokoTelepon != null)
                        Text(
                          "Telp: ${_trx.tokoTelepon!}",
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      // Info
                      _buildReceiptInfoRow("No. Transaksi", _trx.nomorTransaksi),
                      _buildReceiptInfoRow("Tanggal", dateFormat.format(_trx.createdAt)),
                      _buildReceiptInfoRow("Kasir", _trx.namaKasir ?? '-'),
                      _buildReceiptInfoRow("Pembayaran", _trx.metodePembayaran.toUpperCase()),
                      
                      const SizedBox(height: 12),
                      const Text(
                        "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      // Items list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _trx.items?.length ?? 0,
                        itemBuilder: (context, index) {
                          final item = _trx.items![index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.namaProduk,
                                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${item.qty} x ${formatIDR(item.hargaProduk)}",
                                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted),
                                    ),
                                    Text(
                                      formatIDR(item.subtotal),
                                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),

                      // Calculations
                      _buildCalculationRow("Total Belanja", formatIDR(_trx.total), isBold: true),
                      _buildCalculationRow("Bayar (${_trx.metodePembayaran.toUpperCase()})", formatIDR(_trx.jumlahBayar)),
                      _buildCalculationRow("Kembalian", formatIDR(_trx.kembalian), isPrimary: _trx.kembalian > 0),
                      
                      const SizedBox(height: 16),
                      Text(
                        "Terima Kasih atas Kunjungan Anda!",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // WhatsApp Share panel card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Kirim Struk via WhatsApp",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: "No. HP Pembeli (e.g. 0812xxx)",
                                prefixIcon: const Icon(Icons.phone_rounded, size: 18),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _shareWA,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: const Icon(Icons.send_rounded, size: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // PDF Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => PdfService.instance.printReceipt(_trx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.print_rounded, size: 18),
                      label: const Text(
                        "Cetak Struk",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => PdfService.instance.shareReceiptPdf(_trx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        "Bagikan PDF",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Back to Home
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.cashierHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "TRANSAKSI BARU",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, {bool isBold = false, bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isPrimary ? AppColors.primary : AppColors.textDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isBold ? 13 : 11,
              fontWeight: FontWeight.bold,
              color: isPrimary ? AppColors.primary : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
