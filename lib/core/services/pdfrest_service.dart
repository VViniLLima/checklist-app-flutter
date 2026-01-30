import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PdfRestService {
  static const String baseUrl = 'https://api.pdfrest.com';

  String get _apiKey => dotenv.get('PDFREST_API_KEY', fallback: '');

  Future<String> ocrPdf(
    File pdfFile, {
    String languages = 'Portuguese,English',
  }) async {
    final url = Uri.parse('$baseUrl/pdf-with-ocr-text');
    final request = http.MultipartRequest('POST', url)
      ..headers['Accept'] = 'application/json'
      ..headers['Api-Key'] = _apiKey
      ..fields['languages'] = languages
      ..files.add(await http.MultipartFile.fromPath('file', pdfFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      final outputId = jsonResponse['outputId'];
      if (outputId != null) {
        return outputId as String;
      } else {
        throw Exception('OCR result is missing outputId');
      }
    } else {
      throw Exception('OCR Error: ${response.statusCode} - $responseBody');
    }
  }

  Future<Map<String, dynamic>> extractTextFromPdfId(String pdfId) async {
    final url = Uri.parse('$baseUrl/extracted-text');
    final request = http.MultipartRequest('POST', url)
      ..headers['Accept'] = 'application/json'
      ..headers['Api-Key'] = _apiKey
      ..fields['id'] = pdfId
      ..fields['full_text'] = 'document'
      ..fields['preserve_line_breaks'] = 'on';

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Extract Text Error: ${response.statusCode} - $responseBody',
      );
    }
  }
}
