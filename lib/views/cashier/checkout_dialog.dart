import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/cashier_controller.dart';
import '../../utils/constants.dart';

class CheckoutDialog extends StatefulWidget {
  const CheckoutDialog({super.key});

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final _payAmountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'tunai'; // default
  double _payAmount = 0;
  double _total = 0;
  double _kembalian = 0;

  @override
  void initState() {
    super.initState();
    _total = CashierController.to.cartTotalPrice;
    _payAmountController.text = _total.toStringAsFixed(0);
    _payAmount = _total;
    _payAmountController.addListener(_calculateChange);
  }

  @override
  void dispose() {
    _payAmountController.removeListener(_calculateChange);
    _payAmountController.dispose();
    super.dispose();
  }

  void _calculateChange() {
    final text = _payAmountController.text;
    final val = double.tryParse(text.replaceAll(RegExp(r'\D'), '')) ?? 0;
    setState(() {
      _payAmount = val;
      _kembalian = _payAmount - _total;
    });
  }

  void _selectMethod(String method) {
    setState(() {
      _paymentMethod = method;
      if (method != 'tunai') {
        _payAmountController.text = _total.toStringAsFixed(0);
        _payAmount = _total;
        _kembalian = 0;
      }
    });
  }

  void _setAmount(double amount) {
    setState(() {
      _payAmountController.text = amount.toStringAsFixed(0);
    });
  }

  void _submit() {
    if (_paymentMethod == 'tunai') {
      if (_formKey.currentState!.validate()) {
        if (_payAmount < _total) {
          Get.snackbar('Validasi', 'Jumlah bayar kurang!');
          return;
        }
        CashierController.to.handleCheckout(
          paymentMethod: _paymentMethod,
          jumlahBayar: _payAmount,
        );
      }
    } else {
      CashierController.to.handleCheckout(
        paymentMethod: _paymentMethod,
        jumlahBayar: _total,
      );
    }
  }

  List<double> _getDenominations() {
    final List<double> list = [_total]; // Pas
    
    // Standard cash suggestions higher than total
    final List<double> standardDenoms = [10000, 20000, 50000, 100000];
    for (var d in standardDenoms) {
      if (d > _total && !list.contains(d)) {
        list.add(d);
      }
    }
    // Sort and limit to 4 suggestions
    list.sort();
    return list.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = CashierController.to;
    final denoms = _getDenominations();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Pilih Pembayaran",
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(height: 12),
              const SizedBox(height: 12),

              // Total display
              Center(
                child: Column(
                  children: [
                    const Text(
                      "TOTAL TRANSAKSI",
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5),
                    ),
                    Text(
                      formatIDR(_total),
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment method selectors
              const Text(
                "Metode Pembayaran",
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildMethodBtn('tunai', Icons.money_rounded, "Tunai")),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMethodBtn('transfer', Icons.account_balance_rounded, "Transfer")),
                  const SizedBox(width: 8),
                  Expanded(child: _buildMethodBtn('qris', Icons.qr_code_rounded, "QRIS")),
                ],
              ),
              const SizedBox(height: 20),

              // Cash Pay Form details
              if (_paymentMethod == 'tunai') ...[
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Uang Diterima (Jumlah Bayar)",
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _payAmountController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        decoration: InputDecoration(
                          prefixText: "Rp ",
                          prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jumlah bayar wajib diisi';
                          }
                          final clean = double.tryParse(value.replaceAll(RegExp(r'\D'), ''));
                          if (clean == null || clean < _total) {
                            return 'Uang bayar kurang dari total belanja';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Denomination chips
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: denoms.map((d) {
                          final label = d == _total ? "Uang Pas" : formatIDR(d);
                          return ActionChip(
                            label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.primary.withOpacity(0.06),
                            side: const BorderSide(color: Colors.transparent),
                            onPressed: () => _setAmount(d),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Change display
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Kembalian", style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textMuted)),
                          Text(
                            formatIDR(_kembalian >= 0 ? _kembalian : 0),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _kembalian >= 0 ? AppColors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Transfer/QRIS placeholder note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _paymentMethod == 'qris' ? Icons.qr_code_scanner_rounded : Icons.info_outline_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _paymentMethod == 'qris'
                              ? "Tunjukkan kode QRIS toko ke pelanggan. Pembayaran akan divalidasi manual."
                              : "Minta pelanggan mentransfer ke rekening toko. Pembayaran akan divalidasi manual.",
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(() {
                  final loading = controller.isSubmitting.value;
                  return ElevatedButton(
                    onPressed: loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 2),
                          )
                        : const Text(
                            "SELESAI & BAYAR",
                            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodBtn(String method, IconData icon, String label) {
    final bool isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () => _selectMethod(method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.onPrimary : AppColors.textDark, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.onPrimary : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
