import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../data/database/app_database.dart';

abstract final class InvoicePdf {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _timeFmt = DateFormat('hh:mm a');

  // Primary brand color
  static const _brand = PdfColor.fromInt(0xFF1565C0);
  static const _brandLight = PdfColor.fromInt(0xFFE3F2FD);
  static const _textPrimary = PdfColor.fromInt(0xFF1A1A2E);
  static const _textSecondary = PdfColor.fromInt(0xFF6B7280);
  static const _rowAlt = PdfColor.fromInt(0xFFF5F7FA);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _errorRed = PdfColor.fromInt(0xFFC62828);

  // PdfColors doesn't support alpha shades directly - define them manually.
  static const _white70 = PdfColor(1, 1, 1, 0.7);
  static const _white60 = PdfColor(1, 1, 1, 0.6);

  static (PdfColor bg, PdfColor fg) _statusColors(String status) => switch (status) {
        'paid'    => (const PdfColor.fromInt(0xFFE8F5E9), const PdfColor.fromInt(0xFF2E7D32)),
        'partial' => (const PdfColor.fromInt(0xFFFFF8E1), const PdfColor.fromInt(0xFFF57F17)),
        'void'    => (const PdfColor.fromInt(0xFFFFEBEE), _errorRed),
        'open'    => (const PdfColor.fromInt(0xFFE3F2FD), const PdfColor.fromInt(0xFF0277BD)),
        _         => (const PdfColor.fromInt(0xFFEEF2F7), _textSecondary),
      };

  static Future<pw.Document> build({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Customer? customer,
    required String cashierName,
  }) async {
    final doc = pw.Document(
      title: invoice.invoiceNo,
      author: 'BMS - Business Manager',
    );

    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final fontSemiBold = await PdfGoogleFonts.interMedium();
    final isVoid = invoice.status == 'void';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (ctx) => pw.Stack(
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(font, fontBold, invoice, cashierName),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _buildBillTo(font, fontBold, fontSemiBold, customer),
                      pw.SizedBox(height: 24),
                      _buildItemsTable(font, fontBold, fontSemiBold, items),
                      pw.SizedBox(height: 20),
                      _buildTotals(font, fontBold, fontSemiBold, invoice),
                      pw.SizedBox(height: 20),
                      _buildPaymentInfo(font, fontBold, fontSemiBold, invoice),
                      if (invoice.voidReason != null) ...[
                        pw.SizedBox(height: 16),
                        _buildVoidInfo(font, fontBold, invoice),
                      ],
                    ],
                  ),
                ),
                pw.Expanded(child: pw.SizedBox()),
                _buildFooter(font, fontSemiBold, invoice),
              ],
            ),
            if (isVoid) _buildVoidWatermark(fontBold),
          ],
        ),
      ),
    );

    return doc;
  }


  static pw.Widget _buildHeader(
    pw.Font font,
    pw.Font fontBold,
    Invoice invoice,
    String cashier,
  ) {
    final date = invoice.createdAt;
    return pw.Container(
      color: _brand,
      padding: const pw.EdgeInsets.fromLTRB(40, 32, 40, 28),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BMS',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 28,
                    color: PdfColors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Business Manager',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 11,
                    color: _white70,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 22,
                  color: PdfColors.white,
                  letterSpacing: 2,
                ),
              ),
              pw.SizedBox(height: 6),
              _headerField(font, fontBold, 'Invoice No', invoice.invoiceNo),
              pw.SizedBox(height: 3),
              _headerField(font, fontBold, 'Date', _dateFmt.format(date)),
              pw.SizedBox(height: 3),
              _headerField(font, fontBold, 'Time', _timeFmt.format(date)),
              pw.SizedBox(height: 3),
              _headerField(font, fontBold, 'Cashier', cashier),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _headerField(pw.Font font, pw.Font fontBold, String label, String value) =>
      pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$label: ',
            style: pw.TextStyle(font: font, fontSize: 9, color: _white60),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
          ),
        ],
      );


  static pw.Widget _buildBillTo(
    pw.Font font,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    Customer? customer,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _brandLight,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8,
                  color: _brand,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                customer?.name ?? 'Walk-in Customer',
                style: pw.TextStyle(font: fontBold, fontSize: 13, color: _textPrimary),
              ),
              if (customer?.phone != null)
                pw.Text(
                  customer!.phone!,
                  style: pw.TextStyle(font: font, fontSize: 10, color: _textSecondary),
                ),
              if (customer?.address != null)
                pw.Text(
                  customer!.address!,
                  style: pw.TextStyle(font: font, fontSize: 10, color: _textSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }


  static pw.Widget _buildItemsTable(
    pw.Font font,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    List<InvoiceItem> items,
  ) {
    pw.Widget cell(
      String text, {
      pw.Font? f,
      double size = 9,
      pw.Alignment align = pw.Alignment.centerLeft,
      PdfColor color = _textPrimary,
    }) =>
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Align(
            alignment: align,
            child: pw.Text(text, style: pw.TextStyle(font: f ?? font, fontSize: size, color: color)),
          ),
        );

    final headers = ['#', 'Description', 'Qty', 'Unit Price', 'Discount', 'Amount'];
    final aligns = [
      pw.Alignment.center,
      pw.Alignment.centerLeft,
      pw.Alignment.center,
      pw.Alignment.centerRight,
      pw.Alignment.centerRight,
      pw.Alignment.centerRight,
    ];

    return pw.Table(
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(65),
        4: const pw.FixedColumnWidth(55),
        5: const pw.FixedColumnWidth(70),
      },
      border: pw.TableBorder(
        bottom: const pw.BorderSide(color: _border),
        horizontalInside: const pw.BorderSide(color: _border, width: 0.5),
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _brand),
          children: [
            for (int i = 0; i < headers.length; i++)
              cell(headers[i], f: fontBold, color: PdfColors.white, align: aligns[i]),
          ],
        ),
        // Data rows
        for (int i = 0; i < items.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(color: i.isOdd ? _rowAlt : PdfColors.white),
            children: [
              cell('${i + 1}', align: pw.Alignment.center),
              cell(items[i].productName),
              cell(items[i].qty % 1 == 0
                  ? items[i].qty.toInt().toString()
                  : items[i].qty.toStringAsFixed(2),
                  align: pw.Alignment.center),
              cell(CurrencyUtils.format(items[i].unitPrice), align: pw.Alignment.centerRight),
              cell(
                items[i].discountPercent > 0
                    ? '${items[i].discountPercent.toStringAsFixed(0)}%'
                    : '-',
                align: pw.Alignment.centerRight,
              ),
              cell(
                CurrencyUtils.format(items[i].subtotal),
                f: fontSemiBold,
                align: pw.Alignment.centerRight,
              ),
            ],
          ),
      ],
    );
  }


  static pw.Widget _buildTotals(
    pw.Font font,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    Invoice invoice,
  ) {
    pw.Widget row(String label, String value, {bool bold = false, PdfColor? color}) =>
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: bold ? fontBold : font,
                    fontSize: bold ? 10 : 9,
                    color: color ?? _textSecondary)),
            pw.Text(value,
                style: pw.TextStyle(
                    font: bold ? fontBold : fontSemiBold,
                    fontSize: bold ? 11 : 9,
                    color: color ?? _textPrimary)),
          ],
        );

    final balance = invoice.total - invoice.paidAmount;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 240,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _border),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          children: [
            row('Subtotal', CurrencyUtils.format(invoice.subtotal)),
            if (invoice.discountAmount > 0) ...[
              pw.SizedBox(height: 5),
              row('Discount', '- ${CurrencyUtils.format(invoice.discountAmount)}',
                  color: _errorRed),
            ],
            pw.SizedBox(height: 8),
            pw.Container(height: 1, color: _border),
            pw.SizedBox(height: 8),
            row('TOTAL', CurrencyUtils.format(invoice.total), bold: true, color: _brand),
            pw.SizedBox(height: 5),
            row('Amount Received', CurrencyUtils.format(invoice.paidAmount)),
            if (balance > 0) ...[
              pw.SizedBox(height: 5),
              row('Balance Due', CurrencyUtils.format(balance), color: _errorRed),
            ],
          ],
        ),
      ),
    );
  }


  static pw.Widget _buildPaymentInfo(
    pw.Font font,
    pw.Font fontBold,
    pw.Font fontSemiBold,
    Invoice invoice,
  ) {
    final methodLabel = _paymentLabel(invoice.paymentType);
    final (statusBg, statusFg) = _statusColors(invoice.status);

    return pw.Row(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: _brandLight,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Payment: ',
                  style: pw.TextStyle(font: font, fontSize: 9, color: _textSecondary)),
              pw.Text(methodLabel,
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: _brand)),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: pw.BoxDecoration(
            color: statusBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            invoice.status.toUpperCase(),
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: statusFg),
          ),
        ),
      ],
    );
  }


  static pw.Widget _buildVoidInfo(pw.Font font, pw.Font fontBold, Invoice invoice) =>
      pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFFEBEE),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: _errorRed, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('VOID REASON',
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: _errorRed,
                    letterSpacing: 1)),
            pw.SizedBox(height: 4),
            pw.Text(invoice.voidReason ?? '',
                style: pw.TextStyle(font: font, fontSize: 9, color: _textPrimary)),
            if (invoice.voidApprovedBy != null) ...[
              pw.SizedBox(height: 4),
              pw.Text('Approved by: ${invoice.voidApprovedBy}',
                  style: pw.TextStyle(font: font, fontSize: 9, color: _textSecondary)),
            ],
          ],
        ),
      );


  static pw.Widget _buildVoidWatermark(pw.Font fontBold) => pw.Center(
        child: pw.Transform.rotate(
          angle: -0.5,
          child: pw.Opacity(
            opacity: 0.08,
            child: pw.Text(
              'VOID',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 120,
                color: _errorRed,
                letterSpacing: 8,
              ),
            ),
          ),
        ),
      );


  static pw.Widget _buildFooter(pw.Font font, pw.Font fontSemiBold, Invoice invoice) =>
      pw.Container(
        color: const PdfColor.fromInt(0xFFF5F7FA),
        padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Thank you for your business!',
              style: pw.TextStyle(font: fontSemiBold, fontSize: 10, color: _brand),
            ),
            pw.Text(
              invoice.invoiceNo,
              style: pw.TextStyle(font: font, fontSize: 9, color: _textSecondary),
            ),
          ],
        ),
      );


  static String _paymentLabel(String type) => switch (type) {
        'cash' => 'Cash',
        'card' => 'Card',
        'cheque' => 'Cheque',
        'credit' => 'Credit',
        'mixed' => 'Mixed',
        _ => type,
      };

}
