import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

final chatServiceProvider = Provider((ref) => ChatService());

class ChatService {
  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192',
          'messages': [
            {
              'role': 'system',
              'content': 'You are Hayat AI, a helpful assistant for a blood donation app. Your goal is to encourage blood donation, explain the process, and help users find hospitals. Be concise, friendly, and use emojis.'
            },
            {
              'role': 'user',
              'content': message
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to load response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }
}
