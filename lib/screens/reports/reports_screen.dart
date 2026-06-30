import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/app_state.dart';
import '../../services/pdf_report_service.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override State<ReportsScreen> createState() => _ReportsScreenState();
}

enum _Preset { today, last7, last30, thisMonth, lastMonth, custom }

class _ReportsScreenState extends State<ReportsScreen> {
  _Preset _preset = _Preset.last7;
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _applyPreset(_Preset.last7);
  }

  void _applyPreset(_Preset p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    setState(() {
      _preset = p;
      switch (p) {
        case _Preset.today:
          _startDate = today;
          _endDate = today;
          break;
        case _Preset.last7:
          _startDate = today.subtract(const Duration(days: 6));
          _endDate = today;
          break;
        case _Preset.last30:
          _startDate = today.subtract(const Duration(days: 29));
          _endDate = today;
          break;
        case _Preset.thisMonth:
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = today;
          break;
        case _Preset.lastMonth:
          final lastMonth = DateTime(now.year, now.month - 1);
          _startDate = DateTime(lastMonth.year, lastMonth.month, 1);
          _endDate = DateTime(now.year, now.month, 0); // last day of prev month
          break;
        case _Preset.custom:
          break;
      }
    });
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(primary: AppTheme.teal, surface: AppTheme.navyCard, onSurface: AppTheme.textPrimary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _preset = _Preset.custom;
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  List<dynamic> _filteredSales(AppState state) {
    return state.sales.where((s) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      return !d.isBefore(_startDate) && !d.isAfter(_endDate);
    }).toList();
  }

  Future<void> _downloadPdf(AppState state) async {
    final sales = _filteredSales(state).cast<dynamic>();
    final user = FirebaseAuth.instance.currentUser;
    final businessName = (user?.displayName?.isNotEmpty ?? false)
        ? '${user!.displayName}\'s Business'
        : 'My Business';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.teal)),
    );

    try {
      final bytes = await PdfReportService.generateReport(
        businessName: businessName,
        startDate: _startDate,
        endDate: _endDate,
        sales: sales.cast(),
        settings: state.settings,
      );

      final fileName = 'BizSplit_Report_${DateFormat('yyyyMMdd').format(_startDate)}.pdf';

      // Try the public Downloads folder first (Android), fall back to app documents
      Directory? dir;
      try {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
          dir = await getApplicationDocumentsDirectory();
        }
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.pop(context); // close loading

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${dir.path.contains('Download') ? 'Downloads' : 'app storage'}'),
            backgroundColor: AppTheme.profit,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => Printing.layoutPdf(onLayout: (_) async => bytes),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  Future<void> _generateAndShare(AppState state) async {
    final sales = _filteredSales(state).cast<dynamic>();
    final user = FirebaseAuth.instance.currentUser;
    final businessName = (user?.displayName?.isNotEmpty ?? false)
        ? '${user!.displayName}\'s Business'
        : 'My Business';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.teal)),
    );

    try {
      final bytes = await PdfReportService.generateReport(
        businessName: businessName,
        startDate: _startDate,
        endDate: _endDate,
        sales: sales.cast(),
        settings: state.settings,
      );

      if (mounted) Navigator.pop(context); // close loading dialog

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'BizSplit_Report_${DateFormat('yyyyMMdd').format(_startDate)}.pdf',
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate report: $e')),
        );
      }
    }
  }

  Future<void> _previewPdf(AppState state) async {
    final sales = _filteredSales(state).cast<dynamic>();
    final user = FirebaseAuth.instance.currentUser;
    final businessName = (user?.displayName?.isNotEmpty ?? false)
        ? '${user!.displayName}\'s Business'
        : 'My Business';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PdfPreviewScreen(
          generate: () => PdfReportService.generateReport(
            businessName: businessName,
            startDate: _startDate,
            endDate: _endDate,
            sales: sales.cast(),
            settings: state.settings,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sales = _filteredSales(state);
    final fmt = NumberFormat('#,##0.00');
    final currency = state.settings.currency;

    double revenue = 0, profit = 0;
    for (final s in sales) {
      revenue += s.totalRevenue;
      profit += s.totalProfit;
    }

    final dateFmt = DateFormat('MMM d, yyyy');
    final rangeLabel = DateUtils.isSameDay(_startDate, _endDate)
        ? dateFmt.format(_startDate)
        : '${dateFmt.format(_startDate)} — ${dateFmt.format(_endDate)}';

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // ── Date range presets ───────────────────────────
          const Text('Date Range', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _presetChip('Today', _Preset.today),
              _presetChip('Last 7 days', _Preset.last7),
              _presetChip('Last 30 days', _Preset.last30),
              _presetChip('This month', _Preset.thisMonth),
              _presetChip('Last month', _Preset.lastMonth),
              GestureDetector(
                onTap: _pickCustomRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _preset == _Preset.custom ? AppTheme.teal.withOpacity(0.15) : AppTheme.navyCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _preset == _Preset.custom ? AppTheme.teal : const Color(0xFF1D3A4F), width: _preset == _Preset.custom ? 1.5 : 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: _preset == _Preset.custom ? AppTheme.teal : AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text('Custom', style: TextStyle(color: _preset == _Preset.custom ? AppTheme.teal : AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Selected range display ───────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.navyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5),
            ),
            child: Column(children: [
              Row(children: [
                const Icon(Icons.date_range_outlined, color: AppTheme.teal, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(rangeLabel, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14))),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _statBox('Revenue', '$currency${fmt.format(revenue)}', AppTheme.revenue)),
                const SizedBox(width: 10),
                Expanded(child: _statBox('Profit', '$currency${fmt.format(profit)}', AppTheme.profit)),
                const SizedBox(width: 10),
                Expanded(child: _statBox('Sales', '${sales.length}', AppTheme.biz)),
              ]),
            ]),
          ),

          const SizedBox(height: 28),

          if (sales.isEmpty)
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(color: AppTheme.navyCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1D3A4F), width: 0.5)),
              child: Column(children: [
                const Icon(Icons.description_outlined, color: AppTheme.textMuted, size: 36),
                const SizedBox(height: 10),
                const Text('No sales in this date range', style: TextStyle(color: AppTheme.textMuted, fontSize: 13), textAlign: TextAlign.center),
              ]),
            )
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _previewPdf(state),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview Report'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _downloadPdf(state),
                icon: const Icon(Icons.download_outlined, size: 18, color: AppTheme.teal),
                label: const Text('Download PDF', style: TextStyle(color: AppTheme.teal)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.teal),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _generateAndShare(state),
                icon: const Icon(Icons.share_outlined, size: 18, color: AppTheme.textSecondary),
                label: const Text('Share PDF', style: TextStyle(color: AppTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1D3A4F)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _presetChip(String label, _Preset preset) {
    final sel = _preset == preset;
    return GestureDetector(
      onTap: () => _applyPreset(preset),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? AppTheme.teal.withOpacity(0.15) : AppTheme.navyCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? AppTheme.teal : const Color(0xFF1D3A4F), width: sel ? 1.5 : 0.5),
        ),
        child: Text(label, style: TextStyle(color: sel ? AppTheme.teal : AppTheme.textSecondary, fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
      ]),
    );
  }
}

// ── PDF Preview Screen ────────────────────────────────────
class _PdfPreviewScreen extends StatelessWidget {
  final Future<Uint8List> Function() generate;
  const _PdfPreviewScreen({required this.generate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Report Preview')),
      body: PdfPreview(
        build: (format) => generate(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfPreviewPageDecoration: const BoxDecoration(),
      ),
    );
  }
}