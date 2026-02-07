import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  test('List Gemini Models via HttpClient', () async {
    final apiKey = 'AIzaSyCMBQs0bUUSABfp-u312iMP40V3_27i4lQ';
    final request = await HttpClient().getUrl(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'));
    final response = await request.close();
    
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final json = jsonDecode(responseBody);
      final models = json['models'] as List;
      print('Available Models for this Key:');
      for (var m in models) {
        if (m['name'].toString().contains('gemini')) {
          print(m['name']);
        }
      }
    } else {
      print('FAILED HTTP: ${response.statusCode} $responseBody');
    }
  });
}
