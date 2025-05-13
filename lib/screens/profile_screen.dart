import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String firstName = '';
  String lastName = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await AuthService.getUserProfile();
      setState(() {
        firstName = user['firstname'];
        lastName = user['lastname'];
        email = user['email'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  void _confirmPassword(String message, Function(String password) onConfirmed) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Identity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Enter your password',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              onConfirmed(passwordController.text.trim());
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _editField(String title, String initialValue, Function(String) onSave, {bool isEmail = false}) {
    final controller = TextEditingController(text: initialValue);

    // Map display labels to backend field names
    final fieldMap = {
      'First Name': 'firstname',
      'Last Name': 'lastname',
      'Email': 'email',
    };
    final fieldKey = fieldMap[title] ?? title.toLowerCase();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                Navigator.pop(ctx);
                if (isEmail) {
                  _confirmPassword(
                    'Please enter your password to confirm email change.',
                        (password) async {
                      try {
                        final updated = await AuthService.updateEmailWithPassword(
                          oldEmail: email,
                          newEmail: newValue,
                          password: password,
                        );
                        if (updated) {
                          setState(() => email = newValue);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email updated successfully')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                  );
                } else {
                  try {
                    final updated = await AuthService.updateUserField(fieldKey, newValue);
                    if (updated) {
                      onSave(newValue);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Updated successfully')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoTile({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(label, style: const TextStyle(color: Colors.grey)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: onEdit,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF2449D8),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoTile(
            label: 'First Name',
            value: firstName,
            icon: Icons.person,
            onEdit: () => _editField('First Name', firstName, (val) => setState(() => firstName = val)),
          ),
          _buildInfoTile(
            label: 'Last Name',
            value: lastName,
            icon: Icons.person_outline,
            onEdit: () => _editField('Last Name', lastName, (val) => setState(() => lastName = val)),
          ),
          _buildInfoTile(
            label: 'Email',
            value: email,
            icon: Icons.email,
            onEdit: () => _editField('Email', email, (val) => setState(() => email = val), isEmail: true),
          ),
        ],
      ),
    );
  }
}
