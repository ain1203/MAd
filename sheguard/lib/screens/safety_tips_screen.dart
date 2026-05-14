import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SafetyTip {
  final String title;
  final String description;
  final String icon;

  SafetyTip({
    required this.title,
    required this.description,
    required this.icon,
  });

  factory SafetyTip.fromJson(Map<String, dynamic> json) {
    return SafetyTip(
      title: json['title'],
      description: json['description'],
      icon: json['icon'],
    );
  }
}

class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({super.key});

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  late Future<List<SafetyTip>> tips;

  @override
  void initState() {
    super.initState();
    tips = loadTips();
  }

  Future<List<SafetyTip>> loadTips() async {
    final String data =
        await rootBundle.loadString('assets/safety_tips.json');

    final List jsonResult = json.decode(data);

    return jsonResult.map((e) => SafetyTip.fromJson(e)).toList();
  }

  IconData getIcon(String name) {
    switch (name) {
      case "phone":
        return Icons.phone;
      case "security":
        return Icons.security;
      case "location":
        return Icons.location_on;
      case "night":
        return Icons.nightlight_round;
      case "walk":
        return Icons.directions_walk;
      case "car":
        return Icons.directions_car;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),

      // ───────────────── TOP BAR (HomeScreen style) ─────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // back to HomeScreen
          },
        ),
        title: const Text(
          "Safety Tips",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      // ───────────────── BODY ─────────────────
      body: FutureBuilder<List<SafetyTip>>(
        future: tips,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No Tips Found",
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final data = snapshot.data!;

          return Center(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final tip = data[index];

                return Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            getIcon(tip.icon),
                            color: const Color(0xFF6A1B9A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                tip.description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}