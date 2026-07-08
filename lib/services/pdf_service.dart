import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/transaksi_model.dart';
import '../utils/constants.dart';

class PdfService {
  static final PdfService instance = PdfService._internal();
  PdfService._internal();

  // Generate Receipt PDF bytes
  Future<Uint8List> generateReceiptPdf(TransaksiModel trx) async {
    final pdf = pw.Document();
    
    // Convert DateTime
    final String formattedDate = "${trx.createdAt.day}-${trx.createdAt.month}-${trx.createdAt.year} ${trx.createdAt.hour.toString().padLeft(2, '0')}:${trx.createdAt.minute.toString().padLeft(2, '0')}";

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 2 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Header
              pw.Text(
                "KRISPIINAJA",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              ),
              pw.Text(
                trx.namaToko ?? "Toko KrispiinAja",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
              ),
              if (trx.tokoLokasi != null)
                pw.Text(
                  trx.tokoLokasi!,
                  style: const pw.TextStyle(fontSize: 6),
                  textAlign: pw.TextAlign.center,
                ),
              if (trx.tokoTelepon != null)
                pw.Text(
                  "Telp: ${trx.tokoTelepon!}",
                  style: const pw.TextStyle(fontSize: 6),
                ),
              pw.Divider(thickness: 0.5),

              // Transaction Info
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("No: ${trx.nomorTransaksi}", style: const pw.TextStyle(fontSize: 6)),
                    pw.Text("Kasir: ${trx.namaKasir ?? '-'}", style: const pw.TextStyle(fontSize: 6)),
                    pw.Text("Waktu: $formattedDate", style: const pw.TextStyle(fontSize: 6)),
                  ],
                ),
              ),
              pw.Divider(thickness: 0.5),

              // Items
              pw.ListView.builder(
                itemCount: trx.items?.length ?? 0,
                itemBuilder: (context, index) {
                  final item = trx.items![index];
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 0.5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(item.namaProduk, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text("${item.qty} x ${formatIDR(item.hargaProduk)}", style: const pw.TextStyle(fontSize: 6)),
                            pw.Text(formatIDR(item.subtotal), style: const pw.TextStyle(fontSize: 6)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              pw.Divider(thickness: 0.5),

              // Calculations
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Total", style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.Text(formatIDR(trx.total), style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Bayar (${trx.metodePembayaran.toUpperCase()})", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text(formatIDR(trx.jumlahBayar), style: const pw.TextStyle(fontSize: 6)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Kembalian", style: const pw.TextStyle(fontSize: 6)),
                  pw.Text(formatIDR(trx.kembalian), style: const pw.TextStyle(fontSize: 6)),
                ],
              ),
              pw.Divider(thickness: 0.5),

              // Footer
              pw.SizedBox(height: 2),
              pw.Text(
                "Kasir Cepat, Bisnis Hebat",
                style: pw.TextStyle(fontSize: 6, fontStyle: pw.FontStyle.italic),
              ),
              pw.Text(
                "Terima Kasih atas Kunjungan Anda!",
                style: const pw.TextStyle(fontSize: 5),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Print Receipt PDF directly to a printer / preview
  Future<void> printReceipt(TransaksiModel trx) async {
    final pdfBytes = await generateReceiptPdf(trx);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Struk-${trx.nomorTransaksi}',
    );
  }

  // Share Receipt PDF File
  Future<void> shareReceiptPdf(TransaksiModel trx) async {
    final pdfBytes = await generateReceiptPdf(trx);
    final String formattedDate = "${trx.createdAt.day}-${trx.createdAt.month}-${trx.createdAt.year}";
    
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'Struk-${trx.nomorTransaksi}.pdf',
    );
  }

  // Create WhatsApp Text Receipt
  String generateWhatsAppTextReceipt(TransaksiModel trx) {
    final String formattedDate = "${trx.createdAt.day}-${trx.createdAt.month}-${trx.createdAt.year} ${trx.createdAt.hour.toString().padLeft(2, '0')}:${trx.createdAt.minute.toString().padLeft(2, '0')}";
    
    final buffer = StringBuffer();
    buffer.writeln("*=== KRISPIINAJA ===*");
    buffer.writeln("*${trx.namaToko ?? 'Toko KrispiinAja'}*");
    if (trx.tokoLokasi != null) buffer.writeln(trx.tokoLokasi);
    if (trx.tokoTelepon != null) buffer.writeln("Telp: ${trx.tokoTelepon}");
    buffer.writeln("--------------------------------");
    buffer.writeln("No. Trx: `${trx.nomorTransaksi}`");
    buffer.writeln("Kasir: ${trx.namaKasir ?? '-'}");
    buffer.writeln("Waktu: $formattedDate");
    buffer.writeln("--------------------------------");
    
    if (trx.items != null) {
      for (var item in trx.items!) {
        buffer.writeln("*${item.namaProduk}*");
        buffer.writeln("  ${item.qty} x ${formatIDR(item.hargaProduk)} = ${formatIDR(item.subtotal)}");
      }
    }
    buffer.writeln("--------------------------------");
    buffer.writeln("*Total:* ${formatIDR(trx.total)}");
    buffer.writeln("Bayar (${trx.metodePembayaran.toUpperCase()}): ${formatIDR(trx.jumlahBayar)}");
    buffer.writeln("Kembalian: ${formatIDR(trx.kembalian)}");
    buffer.writeln("--------------------------------");
    buffer.writeln("_Kasir Cepat, Bisnis Hebat_");
    buffer.writeln("Terima Kasih atas Kunjungan Anda!");
    
    return buffer.toString();
  }

  // Share to WhatsApp
  Future<void> shareToWhatsApp(TransaksiModel trx, String? customerPhone) async {
    final text = generateWhatsAppTextReceipt(trx);
    final encodedText = Uri.encodeComponent(text);
    
    var url = "https://wa.me/?text=$encodedText";
    if (customerPhone != null && customerPhone.trim().isNotEmpty) {
      var phone = customerPhone.replaceAll(RegExp(r'\D'), '');
      if (phone.startsWith('0')) {
        phone = '62${phone.substring(1)}';
      }
      url = "https://api.whatsapp.com/send?phone=$phone&text=$encodedText";
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to share sheet
      await Share.share(text);
    }
  }
}
