// dart run tool/preview_receipt.dart
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _priceFmt = NumberFormat('#,##0.00');
String _f(double v) => _priceFmt.format(v);

void main() async {
  // ── Sample data ─────────────────────────────────────────────────────────────
  const storeName = 'BMS Store';
  const storeAddress = '123 Main Street, Colombo';
  const storePhone = '077 123 4567';
  const invoiceNo = 'INV-000042';
  const customerName = 'Kasun Perera';
  const paymentMethod = 'CASH';
  const total = 3450.00;
  const amountTendered = 4000.00;
  const change = 550.00;

  final items = [
    _Item('Anchor Milk Powder 400g', 2, 750.00),
    _Item('Milo Tin 400g', 1, 890.00),
    _Item('Sunlight Soap 100g', 3, 85.00),
    _Item('Dettol 250ml', 1, 460.00),
    _Item('Panadol 10 Tab', 2, 55.00),
  ];

  // ── Build PDF ────────────────────────────────────────────────────────────────
  final doc = pw.Document();
  final font = pw.Font.helvetica();
  final fontBold = pw.Font.helveticaBold();
  final headerBytes = File('assets/images/receipt_header.png').readAsBytesSync();
  final headerImage = pw.MemoryImage(headerBytes);
  const grey = PdfColor.fromInt(0xFF666666);
  final now = DateTime.now();
  final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.roll80,
      margin: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Illustration header
          pw.Center(
            child: pw.SizedBox(
              height: 72,
              child: pw.Image(headerImage, fit: pw.BoxFit.contain),
            ),
          ),
          pw.SizedBox(height: 4),

          // Store header
          pw.Center(child: pw.Text(storeName, style: pw.TextStyle(font: fontBold, fontSize: 13))),
          pw.SizedBox(height: 2),
          pw.Center(child: pw.Text(storeAddress, style: pw.TextStyle(font: font, fontSize: 7, color: grey), textAlign: pw.TextAlign.center)),
          pw.SizedBox(height: 1),
          pw.Center(child: pw.Text('Tel: $storePhone', style: pw.TextStyle(font: font, fontSize: 7, color: grey))),
          pw.SizedBox(height: 6),
          _dashed(),
          pw.SizedBox(height: 4),

          // Meta
          _row2(font, 'Invoice:', invoiceNo),
          pw.SizedBox(height: 2),
          _row2(font, 'Date:', dateFmt.format(now)),
          pw.SizedBox(height: 2),
          _row2(font, 'Customer:', customerName),
          pw.SizedBox(height: 4),
          _dashed(),
          pw.SizedBox(height: 4),

          // Column headers
          pw.Row(children: [
            pw.Expanded(flex: 4, child: pw.Text('Item', style: pw.TextStyle(font: fontBold, fontSize: 7.5))),
            pw.SizedBox(width: 28, child: pw.Text('Qty', style: pw.TextStyle(font: fontBold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
            pw.SizedBox(width: 38, child: pw.Text('Price', style: pw.TextStyle(font: fontBold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
            pw.SizedBox(width: 42, child: pw.Text('Amount', style: pw.TextStyle(font: fontBold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
          ]),
          pw.SizedBox(height: 3),
          _dashed(),
          pw.SizedBox(height: 3),

          // Items
          for (final item in items)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(item.name, style: pw.TextStyle(font: fontBold, fontSize: 7.5), maxLines: 2),
                pw.Row(children: [
                  pw.Expanded(child: pw.SizedBox()),
                  pw.SizedBox(width: 28, child: pw.Text('${item.qty}', style: pw.TextStyle(font: font, fontSize: 7.5), textAlign: pw.TextAlign.right)),
                  pw.SizedBox(width: 38, child: pw.Text(_f(item.price), style: pw.TextStyle(font: font, fontSize: 7.5), textAlign: pw.TextAlign.right)),
                  pw.SizedBox(width: 42, child: pw.Text(_f(item.qty * item.price), style: pw.TextStyle(font: fontBold, fontSize: 7.5), textAlign: pw.TextAlign.right)),
                ]),
              ]),
            ),

          pw.SizedBox(height: 4),
          _dashed(),
          pw.SizedBox(height: 4),

          // Total
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('TOTAL', style: pw.TextStyle(font: fontBold, fontSize: 10)),
            pw.Text('Rs. ${_f(total)}', style: pw.TextStyle(font: fontBold, fontSize: 10)),
          ]),
          pw.SizedBox(height: 4),
          _dashed(),
          pw.SizedBox(height: 4),

          // Payment
          _row2(font, 'Payment:', paymentMethod),
          pw.SizedBox(height: 2),
          _row2(font, 'Tendered:', 'Rs. ${_f(amountTendered)}'),
          pw.SizedBox(height: 2),
          _row2(font, 'Change:', 'Rs. ${_f(change)}'),

          pw.SizedBox(height: 8),
          _dashed(),
          pw.SizedBox(height: 8),

          pw.Center(child: pw.Text('Thank you for your purchase!', style: pw.TextStyle(font: font, fontSize: 7.5, color: grey))),
          pw.SizedBox(height: 2),
          pw.Center(child: pw.Text('Please come again', style: pw.TextStyle(font: font, fontSize: 7, color: grey))),
        ],
      ),
    ),
  );

  final bytes = await doc.save();
  final outPath = '${Platform.environment['HOME']}/Downloads/receipt_preview.pdf';
  await File(outPath).writeAsBytes(bytes);
  print('Saved: $outPath');
}

class _Item {
  const _Item(this.name, this.qty, this.price);
  final String name;
  final int qty;
  final double price;
}

pw.Widget _dashed() => pw.CustomPaint(
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

pw.Widget _row2(pw.Font font, String label, String value) =>
    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
      pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8)),
      pw.Text(value, style: pw.TextStyle(font: font, fontSize: 8)),
    ]);
