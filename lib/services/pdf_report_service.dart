import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../models/settings.dart';

class PdfReportService {
  static const _navy = PdfColor.fromInt(0xFF0D1F2D);
  static const _teal = PdfColor.fromInt(0xFF1D9E75);
  static const _tealLight = PdfColor.fromInt(0xFF5DCAA5);
  static const _gray = PdfColor.fromInt(0xFF6B7280);
  static const _lightGray = PdfColor.fromInt(0xFFF3F4F6);
  static const _darkText = PdfColor.fromInt(0xFF111827);
  static const _danger = PdfColor.fromInt(0xFFE85A5A);
  static const _biz = PdfColor.fromInt(0xFF9B7FE8);

  static Future<Uint8List> generateReport({
    required String businessName,
    required DateTime startDate,
    required DateTime endDate,
    required List<Sale> sales,
    required AppSettings settings,
  }) async {
    final doc = pw.Document();
    final fmt = NumberFormat('#,##0.00');
    final currency = settings.currency;
    String f(double v) => '$currency${fmt.format(v)}';

    // ── Calculate totals ──────────────────────────────────
    double revenue = 0, cost = 0, profit = 0;
    for (final s in sales) {
      revenue += s.totalRevenue;
      cost += s.totalCost;
      profit += s.totalProfit;
    }
    final business = profit * (settings.businessPercent / 100);
    final personal = profit * (settings.personalPercent / 100);
    final savings = personal * (settings.personalSavingsPercent / 100);
    final spending = personal * (settings.personalUsePercent / 100);

    // ── Top items ──────────────────────────────────────────
    final Map<String, double> itemTotals = {};
    final Map<String, int> itemQty = {};
    for (final s in sales) {
      itemTotals[s.itemName] = (itemTotals[s.itemName] ?? 0) + s.totalRevenue;
      itemQty[s.itemName] = (itemQty[s.itemName] ?? 0) + s.quantitySold;
    }
    final topItems = itemTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final dateFmt = DateFormat('MMM d, yyyy');
    final isMultiDay = !DateUtils_isSameDay(startDate, endDate);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => _buildHeader(businessName, startDate, endDate, isMultiDay, dateFmt),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),

          // ── Summary cards ──────────────────────────────
          pw.Row(children: [
            _summaryBox('Revenue', f(revenue), _navy, _tealLight),
            pw.SizedBox(width: 10),
            _summaryBox('Profit', f(profit), _navy, _teal),
          ]),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _summaryBox('Business', f(business), _navy, _biz),
            pw.SizedBox(width: 10),
            _summaryBox('Personal', f(personal), _navy, PdfColor.fromInt(0xFFE87B5A)),
          ]),

          pw.SizedBox(height: 24),

          // ── Profit Split breakdown ──────────────────────
          pw.Text('Profit Split Breakdown', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _darkText)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB), width: 0.5),
            columnWidths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1)},
            children: [
              _tableHeaderRow(['Category', 'Percentage', 'Amount']),
              _tableRow(['Business Fund', '${settings.businessPercent.toInt()}%', f(business)]),
              _tableRow(['Personal Savings', '${settings.personalSavingsPercent.toInt()}% of personal', f(savings)]),
              _tableRow(['Personal Spending', '${settings.personalUsePercent.toInt()}% of personal', f(spending)]),
              _tableRow(['Cost of Goods Sold', '—', f(cost)]),
            ],
          ),

          pw.SizedBox(height: 24),

          // ── Top selling items ────────────────────────────
          if (topItems.isNotEmpty) ...[
            pw.Text('Top Selling Items', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _darkText)),
            pw.SizedBox(height: 10),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB), width: 0.5),
              columnWidths: {0: const pw.FlexColumnWidth(3), 1: const pw.FlexColumnWidth(1), 2: const pw.FlexColumnWidth(1.5)},
              children: [
                _tableHeaderRow(['Item', 'Qty Sold', 'Revenue']),
                ...topItems.take(10).map((e) => _tableRow([e.key, '${itemQty[e.key]}', f(e.value)])),
              ],
            ),
            pw.SizedBox(height: 24),
          ],

          // ── Full sales list ───────────────────────────────
          pw.Text('Sales Records (${sales.length})', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _darkText)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE5E7EB), width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(0.8),
              3: const pw.FlexColumnWidth(1.2),
              4: const pw.FlexColumnWidth(1.2),
            },
            children: [
              _tableHeaderRow(['Date', 'Item', 'Qty', 'Sold @', 'Profit']),
              ...sales.map((s) => _tableRow([
                DateFormat('MMM d').format(s.date),
                s.itemName,
                '${s.quantitySold}',
                f(s.sellingPrice),
                f(s.totalProfit),
              ])),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  static bool DateUtils_isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static pw.Widget _buildHeader(String businessName, DateTime start, DateTime end, bool multiDay, DateFormat fmt) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _navy, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Row(children: [
              pw.Text('Biz', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _darkText)),
              pw.Text('Split', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: _teal)),
            ]),
            pw.SizedBox(height: 2),
            pw.Text(businessName, style: pw.TextStyle(fontSize: 11, color: _gray)),
          ]),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text('Sales Report', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _darkText)),
            pw.SizedBox(height: 2),
            pw.Text(
              multiDay ? '${fmt.format(start)} — ${fmt.format(end)}' : fmt.format(start),
              style: const pw.TextStyle(fontSize: 10, color: _gray),
            ),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB), width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by BizSplit', style: const pw.TextStyle(fontSize: 8, color: _gray)),
          pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: _gray)),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor bg, PdfColor accent) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(width: 6, height: 6, decoration: pw.BoxDecoration(color: accent, shape: pw.BoxShape.circle)),
          pw.SizedBox(height: 8),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 2),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.white)),
        ]),
      ),
    );
  }

  static pw.TableRow _tableHeaderRow(List<String> cells) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: _lightGray),
      children: cells.map((c) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: pw.Text(c, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _darkText)),
      )).toList(),
    );
  }

  static pw.TableRow _tableRow(List<String> cells) {
    return pw.TableRow(
      children: cells.map((c) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(c, style: const pw.TextStyle(fontSize: 9, color: _darkText)),
      )).toList(),
    );
  }
}