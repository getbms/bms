// dart run tool/preview_receipt.dart
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _priceFmt = NumberFormat('#,##0.00');
String _f(double v) => _priceFmt.format(v);

const _headerSvg = '''
<svg viewBox="0 0 220 80" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="17" r="13" fill="#FFCCAA"/>
  <path d="M47 14 Q60 1 73 14 Q70 3 60 2 Q50 3 47 14Z" fill="#3D1A00"/>
  <ellipse cx="47" cy="21" rx="4" ry="9" fill="#3D1A00"/>
  <ellipse cx="73" cy="21" rx="4" ry="9" fill="#3D1A00"/>
  <circle cx="55" cy="18" r="1.5" fill="#5D4037"/>
  <circle cx="65" cy="18" r="1.5" fill="#5D4037"/>
  <path d="M55 23 Q60 27 65 23" stroke="#E57373" stroke-width="1.5" fill="none" stroke-linecap="round"/>
  <rect x="56" y="28" width="8" height="8" rx="3" fill="#FFCCAA"/>
  <path d="M46 37 Q60 31 74 37 L76 56 Q60 63 44 56Z" fill="#E91E8C"/>
  <path d="M53 36 Q60 40 67 36" stroke="#FCE4EC" stroke-width="1.5" fill="none"/>
  <path d="M44 56 Q60 65 76 56 L80 76 Q60 84 40 76Z" fill="#C2185B"/>
  <path d="M46 42 Q39 54 36 63" stroke="#FFCCAA" stroke-width="7" stroke-linecap="round" fill="none"/>
  <ellipse cx="35" cy="65" rx="5" ry="4" fill="#FFCCAA"/>
  <path d="M74 42 Q87 46 104 48" stroke="#FFCCAA" stroke-width="7" stroke-linecap="round" fill="none"/>
  <ellipse cx="106" cy="48" rx="5" ry="4" fill="#FFCCAA"/>
  <ellipse cx="50" cy="78" rx="8" ry="3" fill="#3D1A00"/>
  <ellipse cx="66" cy="78" rx="8" ry="3" fill="#3D1A00"/>
  <circle cx="90" cy="24" r="2.5" fill="#FFD700"/>
  <circle cx="96" cy="15" r="1.8" fill="#FFD700"/>
  <circle cx="86" cy="35" r="1.5" fill="#FFD700"/>
  <circle cx="100" cy="31" r="1" fill="#FFD700"/>
  <rect x="104" y="46" width="30" height="4" rx="2" fill="#78909C"/>
  <rect x="130" y="46" width="4" height="13" rx="2" fill="#78909C"/>
  <path d="M118 59 L122 77 L183 77 L186 59Z" fill="#E3F2FD" stroke="#1565C0" stroke-width="1.5"/>
  <line x1="140" y1="59" x2="138" y2="77" stroke="#90CAF9" stroke-width="0.8"/>
  <line x1="159" y1="59" x2="159" y2="77" stroke="#90CAF9" stroke-width="0.8"/>
  <line x1="119" y1="68" x2="185" y2="68" stroke="#90CAF9" stroke-width="0.8"/>
  <rect x="124" y="61" width="14" height="14" rx="2" fill="#EF5350"/>
  <line x1="131" y1="61" x2="131" y2="75" stroke="#C62828" stroke-width="0.8"/>
  <rect x="141" y="63" width="14" height="12" rx="2" fill="#66BB6A"/>
  <path d="M144 63 Q148 57 152 63" stroke="#2E7D32" stroke-width="1.5" fill="none"/>
  <rect x="158" y="58" width="15" height="17" rx="2" fill="#FFA726"/>
  <line x1="165" y1="58" x2="165" y2="75" stroke="#E65100" stroke-width="0.8"/>
  <circle cx="128" cy="81" r="5.5" fill="#546E7A"/>
  <circle cx="128" cy="81" r="2.2" fill="#90A4AE"/>
  <circle cx="173" cy="81" r="5.5" fill="#546E7A"/>
  <circle cx="173" cy="81" r="2.2" fill="#90A4AE"/>
  <circle cx="205" cy="38" r="2" fill="#FFD700"/>
  <circle cx="212" cy="52" r="1.5" fill="#FFD700"/>
  <circle cx="208" cy="64" r="1" fill="#FFD700"/>
</svg>
''';

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
              height: 68,
              child: pw.SvgImage(svg: _headerSvg),
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
