import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IpInputScreen extends StatefulWidget {
  const IpInputScreen({super.key});

  @override
  State<IpInputScreen> createState() => _IpInputScreenState();
}

class _IpInputScreenState extends State<IpInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitIP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final ip = _ipController.text.trim();
    try {
      final res = await http.post(
        Uri.parse('http://localhost:5000/api/devices/set-ip'), // update if needed
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ip': ip}),
      );

      if (res.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _errorMessage = 'Erreur : ${jsonDecode(res.body)['error']}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connexion échouée : $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Entrez l'adresse IP de la carte", style: TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ipController,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Adresse IP',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Veuillez entrer une adresse IP';
                    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                    if (!ipRegex.hasMatch(value)) return 'Format IP invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _submitIP,
                  child: const Text('Enregistrer et continuer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
