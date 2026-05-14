import 'package:flutter/material.dart';
import 'package:sheguard/screens/home_screen.dart';
import 'package:sheguard/screens/alerts_history_screen.dart';

// ───────────────── DATA MODEL ─────────────────
class Contact {
  final String name;
  final String phone;
  final String relation;

  Contact({required this.name, required this.phone, required this.relation});
}

class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  // Circle is index 2 in the nav bar

  final List<Contact> _contacts = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  void _addContact() {
    if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
      setState(() {
        _contacts.add(Contact(
          name: _nameController.text,
          phone: _phoneController.text,
          relation: _relationController.text,
        ));
      });
      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();
      Navigator.pop(context);
    }
  }

  void _showAddContactSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Add Emergency Contact",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, "Full Name", Icons.person),
            const SizedBox(height: 12),
            _buildTextField(
              _phoneController,
              "Phone Number",
              Icons.phone,
              inputType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _relationController,
              "Relation (e.g. Mom, Friend)",
              Icons.family_restroom,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _addContact,
                child: const Text("Save to Circle",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6A1B9A)),
        filled: true,
        fillColor: const Color(0xFFF3E5F5).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Bottom Nav — identical to HomeScreen ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),

      // ───────────────── APP BAR ─────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF6A1B9A),
        elevation: 0,
        leading: Navigator.canPop(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            )
          : null,
        title: const Text(
          "My Circle",
          style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),

      // ───────────────── BODY ─────────────────
      body: _contacts.isEmpty
          ? const Center(
              child: Text(
                "No contacts added yet",
                style: TextStyle(color: Colors.black54, fontSize: 15),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 20),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
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
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFFF3E5F5),
                          child: Icon(Icons.person,
                              color: Color(0xFF6A1B9A)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              Text(
                                "${contact.relation} • ${contact.phone}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () {
                            setState(
                                () => _contacts.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

      // ───────────────── FAB ─────────────────
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF6A1B9A),
        onPressed: _showAddContactSheet,
        label: const Text("Add Contact",
            style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),

      // ───────────────── NAV BAR ─────────────────
    );
  }
}