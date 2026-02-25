import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteApiService {
  static Future<Map<String, String>> getQuote() async {
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/today'));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return {
          'quote': data[0]['q']?.toString() ?? "The secret of your future is hidden in your daily routine.",
          'author': data[0]['a']?.toString() ?? "Mike Murdock"
        };
      }
    } catch (e) {
      return {
        'quote': "The secret of your future is hidden in your daily routine.",
        'author': "Mike Murdock"
      };
    }
    return {
      'quote': "The secret of your future is hidden in your daily routine.",
      'author': "Mike Murdock"
    };
  }
}