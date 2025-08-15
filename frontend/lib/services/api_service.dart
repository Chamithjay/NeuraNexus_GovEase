import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:io';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> submitGrade1Application(
      Map<String, String> fields, List<File> files) async {
    var uri = Uri.parse('$baseUrl/grade1-admission/apply');
    var request = http.MultipartRequest('POST', uri);

    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    for (var file in files) {
      request.files.add(await http.MultipartFile.fromPath(
        'files',
        file.path,
        contentType: MediaType('application', 'octet-stream'),
      ));
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit application');
    }
  }

  static Future<Map<String, dynamic>> createPaypalOrder(String amount) async {
    var uri = Uri.parse('$baseUrl/paypal/create-order');
    var response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'amount': amount, 'currency': 'LKR'}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create PayPal order');
    }
  }
}
