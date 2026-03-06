import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'package:checklist_app/config/n8n_config.dart';

class N8nUploadService {
  /// Uploads a PDF file to the local extraction service at /extract-json.
  ///
  /// Sends a multipart POST request with the PDF file under the field name
  /// defined by [kN8nFileFieldName] ('file').
  ///
  /// Returns the response body string on success.
  /// Throws an exception on failure.
  Future<String> uploadPdf({required String filePath}) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Arquivo não encontrado: $filePath');
    }

    try {
      // Create a multipart request to the local /extract-json endpoint
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(kLocalExtractEndpoint),
      );

      // Add the file to the request using the 'file' field name
      // Explicitly set content type to application/pdf to avoid octet-stream error
      final multipartFile = await http.MultipartFile.fromPath(
        kN8nFileFieldName,
        file.path,
        filename: p.basename(file.path),
        contentType: MediaType('application', 'pdf'),
      );
      request.files.add(multipartFile);

      // Send the request with a timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          throw Exception(
            'Tempo esgotado ao aguardar resposta do servidor (120s)',
          );
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      } else {
        throw Exception(
          'Falha no processamento. Status: ${response.statusCode}\nResposta: ${response.body}',
        );
      }
    } on SocketException {
      throw Exception(
        'Erro de conexão. Verifique se o servidor local está acessível em $kLocalExtractBaseUrl.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Ocorreu um erro inesperado: $e');
    }
  }
}
