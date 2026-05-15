import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  // ─── CONFIGURATION ───
  // Ensure your API Key is kept secure and active
  static const String _apiKey = 'AIzaSyBE3pIDuAJaF7WjcxcPtvjQBODXpEn54u8'; 
  
  // Clean model identifier matching active free-tier routing parameters
  static const String _modelName = 'gemini-3-flash';

  // System Prompt for Women's Safety Assistant (SheGuard AI)
  static const String _systemPrompt = '''
You are "SafeHer AI", a dedicated safety assistant for women. 
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
      debugPrint('🤖 Gemini: Initializing model: $_modelName...');
      
      // Removed the manual 'models/' string appendment to prevent route duplication errors 
      // on sandbox platforms and explicit proxy wrappers.
      _model = GenerativeModel(
        model: _modelName, 
        apiKey: _apiKey,
        systemInstruction: Content.system(_systemPrompt),
        safetySettings: [
          // Keeping restrictions relaxed so a safety app can process sensitive or toxic terms safely
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        ],
        generationConfig: GenerationConfig(
          temperature: 0.5, // Lowered slightly to ensure more deterministic, high-grounded safety tips
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
    if (_apiKey.isEmpty || _apiKey.startsWith('YOUR_')) {
      return 'API Key not configured. Please add a valid Gemini API key in gemini_service.dart.';
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
        debugPrint('⚠️ Gemini: Received null/empty response. Safety filters triggered.');
        return 'I\'m sorry, I cannot respond to that safely. Please try rephrasing your concern, or tap the SOS button if you are in immediate danger.';
      }

      debugPrint('✅ Gemini: Received response');
      return text.trim();
    } catch (e) {
      debugPrint('❌ Gemini Error: $e');
      
      final errorString = e.toString().toLowerCase();
      
      // Fine-tuned error handlers matching public platform messages
      if (errorString.contains('quota') || errorString.contains('429')) {
        return 'System limits reached. Please wait a moment or utilize standard emergency tools.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        return 'Connection error. Please check your internet connectivity and try again.';
      } else if (errorString.contains('location') || errorString.contains('unsupported')) {
        return 'Gemini access constraints hit. Please fallback to direct local features.';
      } else {
        return 'The assistant service is experiencing routing adjustments. If you are in critical danger, use the SOS alerts immediately.';
      }
    }
  }

  /// Clears the current chat history
  void resetChat() {
    _chat = _model.startChat();
  }
}