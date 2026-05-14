import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CHATBOT SERVICE - Handles API calls and logic
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotService {
  static final ChatbotService _instance = ChatbotService._internal();

  factory ChatbotService() {
    return _instance;
  }

  ChatbotService._internal();

  // Get API key from environment or fallback
  String get _geminiApiKey {
    final envKey = dotenv.env['GEMINI_API_KEY'];
    if (envKey != null && envKey.isNotEmpty && envKey != 'AIzaSyBTOmMsiIdFoGCpLBGQERRHD2vDooXWPp4') {
      return envKey;
    }
    // Fallback for testing (NEVER use this in production)
    return 'YOUR_API_KEY_HERE';
  }

  final String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

  /// Predefined Safety Knowledge Base
  static const Map<String, String> safetyResponses = {
    'harassment':
        'I\'m sorry you\'re experiencing this. 1. Move to a crowded area. 2. Call a friend or family member. 3. If you feel in immediate danger, use the SOS button on the home screen.',
    'unsafe':
        'If you feel unsafe, please head to the nearest "Safe Zone" like a shop, police station, or hospital. Keep your SOS button ready.',
    'stalk':
        'If you think you are being followed: 1. Do not go home. 2. Go to a public place with many people. 3. Call the police or a trusted contact immediately.',
    'emergency':
        'In case of an emergency, please dial 15 (Police) or use the SheGuard SOS button immediately to alert your contacts.',
    'help':
        'I am here to help. You can ask about safety tips, what to do in dangerous situations, or how to use the app features.',
    'threat':
        'Take every threat seriously. Document the threat if possible and report it to the local authorities immediately.',
    'police':
        'The emergency number for the police is 15. You should also share your live location with your emergency contacts via the app.',
    'danger':
        'DANGER DETECTED: Please stay calm, move towards light/people, and hold the SOS button for 3 seconds to alert your circle.',
    'tips': 'Safety Tips: 1. Trust your instincts. 2. Keep your phone charged. 3. Share your location with trusted contacts. 4. Practice awareness of your surroundings.',
    'alone':
        'If you\'re going out alone: 1. Inform a trusted contact. 2. Share your live location. 3. Keep your phone visible and charged. 4. Avoid isolated areas.',
  };

  /// Check if API key is configured
  bool get isApiKeyConfigured {
    return _geminiApiKey != 'YOUR_API_KEY_HERE' && _geminiApiKey.isNotEmpty;
  }

  /// Get response from Gemini AI
  Future<String> getAIResponse(String prompt) async {
    if (!isApiKeyConfigured) {
      return 'API key not configured. Please check your .env file or environment variables.';
    }

    try {
      final Uri fullUri = Uri.parse('$_geminiBaseUrl?key=$_geminiApiKey');

      debugPrint('🤖 Chatbot: Sending request to Gemini...');
      
      final response = await http
          .post(
            fullUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {
                      "text":
                          "You are a professional women's safety assistant for the SafeHer app. Provide compassionate, practical, and safety-focused advice. Always prioritize the user's safety. User Query: $prompt"
                    }
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 500,
              }
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('✅ Chatbot: Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return _parseGeminiResponse(response.body);
      } else {
        return _handleApiError(response.statusCode, response.body);
      }
    } on http.ClientException catch (e) {
      debugPrint('❌ Chatbot: Network error - $e');
      return 'Network error. Please check your internet connection and try again.';
    } catch (e) {
      debugPrint('❌ Chatbot Exception: $e');
      return 'An unexpected error occurred. If you\'re in danger, please use the SOS button.';
    }
  }

  /// Parse Gemini API response
  String _parseGeminiResponse(String responseBody) {
    try {
      final data = jsonDecode(responseBody);

      if (data is! Map) {
        debugPrint('❌ Unexpected response type: ${data.runtimeType}');
        return 'Could not parse response. Please try again.';
      }

      final candidates = data['candidates'];
      if (candidates == null || candidates is! List || candidates.isEmpty) {
        debugPrint('❌ No candidates in response');
        return 'Received empty response. Please try again.';
      }

      final firstCandidate = candidates[0];
      final content = firstCandidate['content'];
      if (content == null || content is! Map) {
        debugPrint('❌ No content in candidate');
        return 'Invalid response format. Please try again.';
      }

      final parts = content['parts'];
      if (parts == null || parts is! List || parts.isEmpty) {
        debugPrint('❌ No parts in content');
        return 'Received empty content. Please try again.';
      }

      final text = parts[0]['text'];
      if (text == null || text is! String || text.isEmpty) {
        debugPrint('❌ No text in parts');
        return 'Received empty text. Please try again.';
      }

      return text.trim();
    } catch (e) {
      debugPrint('❌ Error parsing response: $e\nResponse: $responseBody');
      return 'Error processing response. Please try again.';
    }
  }

  /// Handle API errors
  String _handleApiError(int statusCode, String responseBody) {
    debugPrint('🚨 Chatbot API Error: $statusCode - $responseBody');

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please rephrase your question.';
      case 401:
      case 403:
        return 'Authentication error. API key may be invalid or expired.';
      case 429:
        return 'Rate limit exceeded. Please wait a moment and try again.';
      case 500:
      case 502:
      case 503:
        return 'The AI service is temporarily unavailable. Please try again later.';
      default:
        return 'Error: HTTP $statusCode. Please try again.';
    }
  }

  /// Get local response based on keywords
  String? getLocalResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    for (var entry in safetyResponses.entries) {
      if (lowerMessage.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHATBOT SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final ChatbotService _chatbotService = ChatbotService();
  
  final List<Map<String, String>> _messages = [
    {
      'sender': 'bot',
      'text':
          'Hello! 👋 I\'m your SafeHer AI Safety Assistant. I\'m here to provide safety tips, emergency guidance, and support. How can I help you stay safe today?'
    }
  ];
  
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _apiKeyConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkApiKeyConfiguration();
  }

  void _checkApiKeyConfiguration() {
    setState(() {
      _apiKeyConfigured = _chatbotService.isApiKeyConfigured;
    });

    if (!_apiKeyConfigured) {
      debugPrint('⚠️  Warning: Gemini API key not configured');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Handle user message with hybrid approach
  Future<void> _handleUserMessage(String text) async {
    String? botResponse;

    // 1. Try keyword matching first (faster, reliable)
    botResponse = _chatbotService.getLocalResponse(text);

    // 2. Fall back to AI if no keyword match and API is configured
    if (botResponse == null && _apiKeyConfigured) {
      botResponse = await _chatbotService.getAIResponse(text);
    } else if (botResponse == null) {
      botResponse =
          'I couldn\'t find a specific answer to your question. Please try rephrasing or contact emergency services if you need immediate help.';
    }

    setState(() {
      _messages.add({'sender': 'bot', 'text': botResponse!});
      _isTyping = false;
    });
    _scrollToBottom();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': text});
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();
    _handleUserMessage(text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_apiKeyConfigured) _buildApiKeyWarning(),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['sender'] == 'user';
                      return _buildMessageBubble(msg['text']!, isUser);
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SafeHer AI Assistant',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'Online | Secure',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF6A1B9A),
      foregroundColor: Colors.white,
      elevation: 2,
    );
  }

  // ── API Key Warning ─────────────────────────────────────────────────────────
  Widget _buildApiKeyWarning() {
    return Container(
      color: Colors.orange[100],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.orange[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'API key not configured. Using basic safety responses only.',
              style: TextStyle(color: Colors.orange[900], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 40,
              color: Color(0xFF6A1B9A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chat with SafeHer Assistant',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask about safety tips, emergency guidance, or app features',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ── Message Bubble ──────────────────────────────────────────────────────────
  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6A1B9A) : const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Typing Indicator ────────────────────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Row(
        children: [
          const Text(
            'Assistant is thinking',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 20,
            height: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                3,
                (i) => ScaleTransition(
                  scale: Tween(begin: 0.8, end: 1.2).animate(
                    CurvedAnimation(
                      parent: AlwaysStoppedAnimation(0.5),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Area ──────────────────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Ask about safety...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF6A1B9A),
            child: IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}