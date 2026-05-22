import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const GuardianPulseApp(),
    ),
  );
}

class GuardianPulseApp extends StatelessWidget {
  const GuardianPulseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dynamic theme updating based on user preferences in AppState
    final state = Provider.of<AppState>(context);

    return MaterialApp(
      title: 'Guardian Pulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: state.darkTheme ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
