import 'package:bms/data/database/app_database.dart';
import 'package:bms/providers/pos_provider.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ignore: avoid_classes_with_only_static_members
abstract final class ReceiptPdf {
  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  static final _priceFmt = NumberFormat('#,##0.00');

  static String _f(double v) => _priceFmt.format(v);

  static Future<void> printOrPreview({
    required List<CartItem> items,
    required String invoiceNo,
    required String paymentMethod,
    required double subtotal,
    required double discountAmount,
    required double total,
    required double amountTendered,
    required double change,
    Customer? customer,
    String storeName = 'BMS Store',
    String storeAddress = '',
    String storePhone = '',
  }) async {
    final printers = await Printing.listPrinters();
    final doc = await _build(
      items: items,
      invoiceNo: invoiceNo,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
      amountTendered: amountTendered,
      change: change,
      customer: customer,
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
    );

    if (printers.isNotEmpty) {
      await Printing.directPrintPdf(
        printer: printers.first,
        onLayout: (_) async => Uint8List.fromList(doc),
      );
    } else {
      await Printing.layoutPdf(onLayout: (_) async => Uint8List.fromList(doc));
    }
  }

  static Future<List<int>> _build({
    required List<CartItem> items,
    required String invoiceNo,
    required String paymentMethod,
    required double subtotal,
    required double discountAmount,
    required double total,
    required double amountTendered,
    required double change,
    Customer? customer,
    required String storeName,
    required String storeAddress,
    required String storePhone,
  }) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final headerBytes = (await rootBundle.load('assets/images/receipt_header.png'))
        .buffer
        .asUint8List();
    final headerImage = pw.MemoryImage(headerBytes);

    const grey = PdfColor.fromInt(0xFF666666);
    final now = DateTime.now();

    // 57.5mm paper, 48mm effective print width, 4.75mm side margins
    // margin is set on pw.Page (not format) so it's actually applied to content
    const printerFormat = PdfPageFormat(
      57.5 * PdfPageFormat.mm,
      double.infinity,
    );
    const hMargin = 4.75 * PdfPageFormat.mm; // ≈ 13.5pt each side
    const vMargin = 3.0 * PdfPageFormat.mm;  // ≈ 8.5pt top/bottom

    doc.addPage(
      pw.Page(
        pageFormat: printerFormat,
        margin: const pw.EdgeInsets.fromLTRB(hMargin, vMargin, hMargin, vMargin),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Illustration
            pw.Center(
              child: pw.SizedBox(
                height: 52,
                child: pw.Image(headerImage),
              ),
            ),
            pw.SizedBox(height: 3),

            // Store name
            pw.Center(
              child: pw.Text(
                storeName,
                style: pw.TextStyle(font: fontBold, fontSize: 11),
              ),
            ),
            if (storeAddress.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Center(
                child: pw.Text(
                  storeAddress,
                  style: pw.TextStyle(font: font, fontSize: 6.5, color: grey),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
            if (storePhone.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Center(
                child: pw.Text(
                  'Tel: $storePhone',
                  style: pw.TextStyle(font: font, fontSize: 6.5, color: grey),
                ),
              ),
            ],
            pw.SizedBox(height: 5),
            _dashedLine(),
            pw.SizedBox(height: 4),

            // Invoice meta
            _row2(font, 'Invoice:', invoiceNo),
            pw.SizedBox(height: 2),
            _row2(font, 'Date:', _dateFmt.format(now)),
            if (customer != null) ...[
              pw.SizedBox(height: 2),
              _row2(font, 'Customer:', customer.name),
            ],
            pw.SizedBox(height: 4),
            _dashedLine(),
            pw.SizedBox(height: 4),

            // Column headers
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Text('Item',
                      style: pw.TextStyle(font: fontBold, fontSize: 6.5)),
                ),
                pw.SizedBox(
                  width: 20,
                  child: pw.Text('Qty',
                      style: pw.TextStyle(font: fontBold, fontSize: 6.5),
                      textAlign: pw.TextAlign.right),
                ),
                pw.SizedBox(
                  width: 30,
                  child: pw.Text('Price',
                      style: pw.TextStyle(font: fontBold, fontSize: 6.5),
                      textAlign: pw.TextAlign.right),
                ),
                pw.SizedBox(
                  width: 34,
                  child: pw.Text('Amt',
                      style: pw.TextStyle(font: fontBold, fontSize: 6.5),
                      textAlign: pw.TextAlign.right),
                ),
              ],
            ),
            pw.SizedBox(height: 3),
            _dashedLine(),
            pw.SizedBox(height: 3),

            // Items
            ...items.map((item) => _ItemRow(item: item, font: font, fontBold: fontBold)),

            pw.SizedBox(height: 4),
            _dashedLine(),
            pw.SizedBox(height: 4),

            // Totals
            if (discountAmount > 0) ...[
              _row2(font, 'Subtotal', 'Rs. ${_f(subtotal)}'),
              pw.SizedBox(height: 2),
              _row2(font, 'Discount', '- Rs. ${_f(discountAmount)}'),
              pw.SizedBox(height: 2),
            ],
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 9)),
                pw.Text('Rs. ${_f(total)}', style: pw.TextStyle(font: fontBold, fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 4),
            _dashedLine(),
            pw.SizedBox(height: 4),

            // Payment
            _row2(font, 'Payment:', paymentMethod.toUpperCase()),
            if (paymentMethod == 'cash' && amountTendered > 0) ...[
              pw.SizedBox(height: 2),
              _row2(font, 'Tendered:', 'Rs. ${_f(amountTendered)}'),
              pw.SizedBox(height: 2),
              _row2(font, 'Change:', 'Rs. ${_f(change > 0 ? change : 0)}'),
            ],

            pw.SizedBox(height: 6),
            _dashedLine(),
            pw.SizedBox(height: 6),

            // Footer
            pw.Center(
              child: pw.Text(
                'Thank you for your purchase!',
                style: pw.TextStyle(font: font, fontSize: 7, color: grey),
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Center(
              child: pw.Text(
                'Please come again',
                style: pw.TextStyle(font: font, fontSize: 6.5, color: grey),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _dashedLine() => pw.CustomPaint(
        size: const PdfPoint(double.infinity, 1),
        painter: (canvas, size) {
          canvas.setStrokeColor(PdfColors.grey400);
          canvas.setLineWidth(0.5);
          var x = 0.0;
          while (x < size.x) {
            canvas.moveTo(x, 0);
            canvas.lineTo(x + 3, 0);
            x += 6;
          }
          canvas.strokePath();
        },
      );

  static pw.Widget _row2(pw.Font font, String label, String value,
          {double fontSize = 6.5}) =>
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: fontSize)),
          pw.Text(value, style: pw.TextStyle(font: font, fontSize: fontSize)),
        ],
      );
}

class _ItemRow extends pw.StatelessWidget {
  _ItemRow({required this.item, required this.font, required this.fontBold});

  final CartItem item;
  final pw.Font font;
  final pw.Font fontBold;

  @override
  pw.Widget build(pw.Context context) {
    final qtyStr = item.qty % 1 == 0
        ? item.qty.toStringAsFixed(0)
        : item.qty.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '');

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(item.product.name,
              style: pw.TextStyle(font: fontBold, fontSize: 6.5), maxLines: 2),
          pw.Row(
            children: [
              pw.Expanded(child: pw.SizedBox()),
              pw.SizedBox(
                width: 20,
                child: pw.Text(qtyStr,
                    style: pw.TextStyle(font: font, fontSize: 6.5),
                    textAlign: pw.TextAlign.right),
              ),
              pw.SizedBox(
                width: 30,
                child: pw.Text(ReceiptPdf._f(item.unitPrice),
                    style: pw.TextStyle(font: font, fontSize: 6.5),
                    textAlign: pw.TextAlign.right),
              ),
              pw.SizedBox(
                width: 34,
                child: pw.Text(ReceiptPdf._f(item.lineTotal),
                    style: pw.TextStyle(font: fontBold, fontSize: 6.5),
                    textAlign: pw.TextAlign.right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
