import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'mindshift_reflection_store.dart';
import 'main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MindShiftApp());
}

class MindShiftApp extends StatelessWidget {
  const MindShiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReflectionStore()..load(),
      child: MaterialApp(
        title: 'Mind Journal AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainShell(),
      ),
    );
  }
}