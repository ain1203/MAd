import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // ─── CONFIGURATION ───
  // Replace this with your actual Gemini API Key from Google AI Studio
  static const String _apiKey = 'AIzaSyBE3pIDuAJaF7WjcxcPtvjQBODXpEn54u8'; 
  
  // Model name (gemini-1.5-flash is recommended for speed and cost)
  static const String _modelName = 'gemini-1.5-flash';

  // System Prompt for Women's Safety Assistant
  static const String _systemPrompt = '''
You are "SheGuard AI", a dedicated safety assistant for women. 
Your goal is to provide practical, immediate, and compassionate safety advice.
Guidelines:
1. Keep responses short, direct, and actionable.
2. If the user is in immediate danger, prioritize telling them to use the SOS button or call emergency services (15/112).
3. Offer tips on safe travel, digital safety, and handling harassment.
4. Maintain a supportive and empowering tone.
5. Never provide medical or legal advice that replaces professional help.
''';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _initializeModel();
  }

  void _initializeModel() {
    try {
      debugPrint('🤖 Gemini: Initializing model...');
      _model = GenerativeModel(
        model: 'models/$_modelName', // Added models/ prefix for better compatibility
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemPrompt),
        safetySettings: [
          // Adjusting safety settings because a safety app needs to talk about "dangerous" topics
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        ],
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 250,
        ),
      );
      
      _chat = _model.startChat();
      debugPrint('✅ Gemini: Initialization successful');
    } catch (e) {
      debugPrint('❌ Gemini Initialization Error: $e');
    }
  }

  /// Sends a message to Gemini and returns the response string.
  /// Handles all common API and network errors gracefully.
  Future<String> sendMessage(String message) async {
    // Basic validation
    if (_apiKey == 'YOUR_API_KEY_HERE' || _apiKey.isEmpty) {
      return 'API Key not configured. Please add your Gemini API key in gemini_service.dart.';
    }

    if (message.trim().isEmpty) {
      return 'Please enter a message.';
    }

    try {
      debugPrint('🤖 Gemini: Sending message - "$message"');
      final content = Content.text(message);
      final response = await _chat.sendMessage(content);

      final text = response.text;
      
      if (text == null || text.isEmpty) {
        debugPrint('⚠️ Gemini: Received null/empty response. This usually means the safety filter blocked it.');
        return 'I\'m sorry, I cannot respond to that. Please try asking in a different way or use the SOS button if you are in danger.';
      }

      debugPrint('✅ Gemini: Received response');
      return text.trim();
    } catch (e) {
      debugPrint('❌ Gemini Error: $e');
      
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('quota') || errorString.contains('429')) {
        return 'I\'ve reached my limit for now. Please try again in a few minutes.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        return 'Connection error. Please check your internet and try again.';
      } else if (errorString.contains('location') || errorString.contains('unsupported')) {
        return 'Gemini is not yet available in your region.';
      } else if (errorString.contains('argument') || errorString.contains('invalid')) {
        return 'There was an issue with the request. Please try a different question.';
      } else {
        return 'The AI service is temporarily unavailable. If you are in danger, please use the SOS button immediately.';
      }
    }
  }

  /// Clears the current chat history
  void resetChat() {
    _chat = _model.startChat();
  }
}
