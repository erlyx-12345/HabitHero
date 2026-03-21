import 'dart:convert';
import 'package:http/http.dart' as http;

class QuoteApiService {
  // Use /quotes to get a list of 50 real quotes for the rotation
  static Future<List<Map<String, String>>> getQuoteBatch() async {
    try {
      final response = await http.get(Uri.parse('https://zenquotes.io/api/quotes'));
      
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((q) => {
          'quote': q['q']?.toString() ?? "Keep going!",
          'author': q['a']?.toString() ?? "Friend"
        }).toList();
      }
    } catch (e) {
      // Fallback if the internet is acting up
      return [{
        'quote': "The secret of your future is hidden in your daily routine.",
        'author': "Mike Murdock"
      }];
    }
    return [];
  }
}