import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text("Dark Mode"),
            trailing: Switch(
              value: false,
              onChanged: (_) {},
            ),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("Clear all data"),
            onTap: () {
              // depois podemos ligar ao store
            },
          ),

          const Divider(),

          const SizedBox(height: 20),

          Center(
            child: Text(
              "MindShift v1.0",
              style: TextStyle(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}