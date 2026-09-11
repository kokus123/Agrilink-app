import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiConfig.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyPreset(String url) {
    setState(() {
      _controller.text = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.dns_rounded, color: Colors.green),
          SizedBox(width: 8),
          Text(
            'Configuration API',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adresse du serveur Laravel :',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'http://10.0.2.2:8000/api',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Raccourcis rapides :',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Émulateur Android (8000)'),
                  onPressed: () =>
                      _applyPreset('http://10.0.2.2:8000/api'),
                ),
                ActionChip(
                  label: const Text('Émulateur Android (8001)'),
                  onPressed: () =>
                      _applyPreset('http://10.0.2.2:8001/api'),
                ),
                ActionChip(
                  label: const Text('Localhost / Web (8000)'),
                  onPressed: () =>
                      _applyPreset('http://127.0.0.1:8000/api'),
                ),
                ActionChip(
                  label: const Text('Localhost / Web (8001)'),
                  onPressed: () =>
                      _applyPreset('http://127.0.0.1:8001/api'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await authProvider.resetBaseUrl();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Réinitialiser'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            final newUrl = _controller.text.trim();
            if (newUrl.isNotEmpty) {
              await authProvider.updateBaseUrl(newUrl);
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
