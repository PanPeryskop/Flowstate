import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowstate/services/database_service.dart';
import 'package:flowstate/screens/home/home_screen.dart';
import 'package:flowstate/theme/flowstate_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final databaseService = DatabaseService();
  await databaseService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (context) => databaseService,
      child: const FlowstateApp(),
    ),
  );
}

class FlowstateApp extends StatelessWidget {
  const FlowstateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flowstate',
      theme: FlowstateTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}