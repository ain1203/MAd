import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Main Scaffold: Jo Home aur Safety Bot tabs ko manage karta hai.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const PlaceholderScreen(title: 'Home Screen'),
    const ChatbotPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Safety Bot'),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(title, style: const TextStyle(fontSize: 20, color: Colors.deepPurple)),
      ),
    );
  }
}

/// Chatbot Page: OpenRouter aur Firestore integration ke sath.
class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // TODO: Apni OpenRouter ki API Key yahan dalein (sk-or-v1-...)
  final String _openRouterKey = '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';

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _controller.clear();

    try {
      // 1. Firestore se context data fetch karna
      final contextData = await _fetchKnowledgeBaseContext(text);

      final systemInstruction = 
          "You are SafeHer Assistant, a women safety AI. Use this context to answer: $contextData. "
          "Reply in Roman Urdu if the user asks in Roman Urdu, and English if they ask in English. "
          "Keep answers concise, empathetic, and highly focused on safety/legal advice.";

      // 2. OpenRouter Endpoint URL
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      // 3. Request Headers aur Body (OpenAI Standard Format)
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openRouterKey',
          'HTTP-Referer': 'https://safeher-app.com', 
          'X-Title': 'SafeHer App',
        },
        body: jsonEncode({
          "model": "openrouter/free",// OpenRouter ka bilkul free Gemini model
          "messages": [
            {
              "role": "system",
              "content": systemInstruction
            },
            {
              "role": "user",
              "content": text
            }
          ],
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final botReply = responseData['choices'][0]['message']['content'];

        setState(() {
          _messages.add({'role': 'bot', 'content': botReply.toString().trim()});
        });
      } else {
        setState(() {
          _messages.add({
            'role': 'bot', 
            'content': 'OpenRouter Error (${response.statusCode}): ${response.body}'
          });
        });
      }

    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'content': 'Connection Error: $e'});
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _fetchKnowledgeBaseContext(String userQuery) async {
    try {
      Query query = FirebaseFirestore.instance.collection('knowledge_base');
      final snapshot = await query.limit(3).get();
      
      if (snapshot.docs.isEmpty) return "No specific knowledge base records found.";

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return "";
        final q = data['question'] ?? data['english_q'] ?? 'No Question';
        final a = data['answer'] ?? data['urdu_a'] ?? 'No Answer';
        return "Q: $q\nA: $a";
      }).join('\n\n');
    } catch (e) {
      return "Knowledge base temporarily unavailable.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('SafeHer AI Assistant'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(color: Colors.deepPurple),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content']!, isUser);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          content,
          style: TextStyle(
            color: isUser 
                ? Colors.white 
                : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87), 
            fontSize: 15
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 4, 
            offset: const Offset(0, -2)
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}