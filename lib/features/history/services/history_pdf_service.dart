import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../../shopping_list/models/shopping_list.dart';
import '../../shopping_list/models/shopping_item.dart';
import '../../../core/theme/app_colors.dart';

/// Service for generating, sharing, and saving PDF documents for historical shopping lists
class HistoryPdfService {
  /// Generates a PDF document for a historical shopping list
  ///
  /// Returns a File object containing the generated PDF
  Future<File> generateHistoryListPdf(
    ShoppingList list,
    List<ShoppingItem> items,
  ) async {
    final pdf = pw.Document();

    // Format date
    final dateStr = list.purchaseDate != null
        ? DateFormat('dd/MM/yyyy').format(list.purchaseDate!)
        : DateFormat('dd/MM/yyyy').format(list.createdAt);

    // Format total
    final totalSpentFormatted = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
    ).format(list.totalSpent ?? 0.0);

    // Filter checked items
    final checkedItems = items.where((i) => i.isChecked).toList();

    // Build PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(list, dateStr),
              pw.SizedBox(height: 24),

              // Summary Card
              _buildSummaryCard(list, dateStr, checkedItems.length),
              pw.SizedBox(height: 24),

              // Items Section
              _buildItemsSection(checkedItems),
              pw.SizedBox(height: 24),

              // Total Row
              _buildTotalRow(totalSpentFormatted),
              pw.SizedBox(height: 24),

              // Footer
              _buildFooter(dateStr),
            ],
          );
        },
      ),
    );

    // Save to temporary file
    final bytes = await pdf.save();
    final filename = _sanitizeFilename(list.name);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$filename.pdf');
    await file.writeAsBytes(bytes);

    return file;
  }

  /// Shares the PDF using the device's native share sheet
  Future<void> shareHistoryListPdf(
    ShoppingList list,
    List<ShoppingItem> items,
  ) async {
    try {
      final file = await generateHistoryListPdf(list, items);
      final bytes = await file.readAsBytes();

      await Printing.sharePdf(
        bytes: bytes,
        filename: file.path.split('/').last,
      );
    } catch (e) {
      throw Exception('Não foi possível compartilhar o arquivo: $e');
    }
  }

  /// Saves the PDF to the device's Downloads folder
  /// Falls back to application documents directory if Downloads is unavailable
  ///
  /// Returns the path where the file was saved
  Future<String> saveHistoryListPdf(
    ShoppingList list,
    List<ShoppingItem> items,
  ) async {
    try {
      // Generate PDF to temp file
      final tempFile = await generateHistoryListPdf(list, items);
      final bytes = await tempFile.readAsBytes();

      // Try to get Downloads directory first
      Directory saveDir;
      try {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          saveDir = downloadsDir;
        } else {
          saveDir = await getApplicationDocumentsDirectory();
        }
      } catch (e) {
        // Downloads directory not available, fall back to app documents
        saveDir = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final filename = _sanitizeFilename(list.name);
      final savedFile = File('${saveDir.path}/$filename.pdf');

      // Write bytes to file
      await savedFile.writeAsBytes(bytes);

      // Verify file was actually written
      if (!await savedFile.exists()) {
        throw Exception('Arquivo não foi salvo corretamente');
      }

      // Get file size to verify it's not empty
      final fileSize = await savedFile.length();
      if (fileSize == 0) {
        throw Exception('Arquivo salvo está vazio');
      }

      return savedFile.path;
    } catch (e) {
      throw Exception('Não foi possível salvar o arquivo: $e');
    }
  }

  /// Sanitizes the list name for use as a filename
  String _sanitizeFilename(String name) {
    // Replace spaces with underscores
    String sanitized = name.replaceAll(' ', '_');
    // Remove characters that are not alphanumeric, underscore, or hyphen
    sanitized = sanitized.replaceAll(RegExp(r'[^\w-]'), '');
    // Ensure it's not empty
    if (sanitized.isEmpty) {
      sanitized = 'lista_historico';
    }
    return 'lista_historico_$sanitized';
  }

  /// Builds the header section of the PDF
  pw.Widget _buildHeader(ShoppingList list, String dateStr) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Shopping cart icon (colored circle with text)
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            color: PdfColor.fromInt(AppColors.primaryLight.value),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text('🛒', style: pw.TextStyle(fontSize: 28)),
          ),
        ),
        pw.SizedBox(height: 16),

        // List name (centered)
        pw.Center(
          child: pw.Text(
            list.name,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(AppColors.textPrimary.value),
            ),
          ),
        ),
        pw.SizedBox(height: 4),

        // Subtitle
        pw.Text(
          'Lista salva no histórico',
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColor.fromInt(AppColors.textSecondary.value),
          ),
        ),
      ],
    );
  }

  /// Builds the summary card section
  pw.Widget _buildSummaryCard(
    ShoppingList list,
    String dateStr,
    int itemCount,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF7F9FC),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE0E0E0), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: '📍',
            label: 'Local da compra:',
            value: list.purchaseLocation ?? 'Não informado',
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow(icon: '📅', label: 'Data da compra:', value: dateStr),
          pw.SizedBox(height: 10),
          _buildInfoRow(
            icon: '🛒',
            label: 'Itens:',
            value: '$itemCount produtos',
          ),
        ],
      ),
    );
  }

  /// Builds an info row with icon, label, and value
  pw.Widget _buildInfoRow({
    required String icon,
    required String label,
    required String value,
  }) {
    return pw.Row(
      children: [
        pw.Text(icon, style: pw.TextStyle(fontSize: 14)),
        pw.SizedBox(width: 8),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColor.fromInt(AppColors.textSecondary.value),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(AppColors.textPrimary.value),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the items section
  pw.Widget _buildItemsSection(List<ShoppingItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Divider
        pw.Divider(color: PdfColor.fromInt(0xFFE0E0E0), thickness: 1),
        pw.SizedBox(height: 16),

        // Items
        ...items.map((item) => _buildItemRow(item)).toList(),

        pw.SizedBox(height: 16),

        // Divider
        pw.Divider(color: PdfColor.fromInt(0xFFE0E0E0), thickness: 1),
      ],
    );
  }

  /// Builds a single item row
  pw.Widget _buildItemRow(ShoppingItem item) {
    final quantityText = item.quantityValue % 1 == 0
        ? '${item.quantityValue.toInt()} ${item.quantityUnit}'
        : '${item.quantityValue} ${item.quantityUnit}';

    final priceText = item.totalValue > 0
        ? NumberFormat.currency(
            locale: 'pt_BR',
            symbol: r'R$',
          ).format(item.totalValue)
        : '-';

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(AppColors.textPrimary.value),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  quantityText,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(AppColors.textSecondary.value),
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            priceText,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(AppColors.textPrimary.value),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the total row
  pw.Widget _buildTotalRow(String totalSpentFormatted) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'Total',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.textPrimary.value),
          ),
        ),
        pw.Text(
          totalSpentFormatted,
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(AppColors.primary.value),
          ),
        ),
      ],
    );
  }

  /// Builds the footer
  pw.Widget _buildFooter(String dateStr) {
    return pw.Center(
      child: pw.Text(
        'COMPRA SALVA • ${dateStr.toUpperCase()}',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromInt(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
