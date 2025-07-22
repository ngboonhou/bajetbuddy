import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import '../models/receipt_data.dart';

// This service handles all communication with the Google Gemini API for OCR.
class GeminiOcrService {
  final String apiKey;
  final Uri endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent');

  GeminiOcrService(this.apiKey);

  // This function sends an image to the API and parses the returned JSON data.
  Future<ReceiptData> extractReceiptData(File imageFile) async {
    const String prompt = """
  Extract store name, date, line items, SST, service tax, and total from the receipt.
  Return ONLY a single, minified JSON object with the following schema:
  {
    "store_name": "string",
    "transaction_date": "YYYY-MM-DD",
    "line_items": [
      { "quantity": integer, "item_name": "string", "price": float }
    ],
    "sst": float,
    "service_tax": float,
    "total": float
  }
  Use null for any value that is not 
  found. If quantity is not specified, default to 1.
  """;

    final bytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(bytes);
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
            }
          ]
        }
      ],
      "generationConfig": {
        "response_mime_type": "application/json",
      }
    });

    int retries = 0;
    const int maxRetries = 3;

    while (retries < maxRetries) {
      final resp = await http.post(
        endpoint,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: body,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text == null) {
          throw Exception('Failed to parse content from Gemini response.');
        }
        return ReceiptData.fromJson(jsonDecode(text));
      }

      if (resp.statusCode == 429) {
        retries++;
        if (retries >= maxRetries) {
          throw Exception('Model is overloaded. Max retries reached.');
        }
        final delayInSeconds = 1 << retries;
        await Future.delayed(
            Duration(seconds: delayInSeconds, milliseconds: Random().nextInt(1000)));
      } else {
        throw Exception(
            'Gemini API failed with status ${resp.statusCode}: ${resp.body}');
      }
    }
    throw Exception('Failed to get a response from the Gemini API.');
  }
}