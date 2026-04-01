import 'package:flutter/material.dart';
import 'package:smet/firebase_options.dart';
import 'package:smet/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (kIsWeb) {
    usePathUrlStrategy();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: AppPages.router,
      theme: ThemeData(
        useMaterial3: true,
        // Merge with default text theme so icon / material defaults stay intact.
        textTheme: GoogleFonts.notoSansTextTheme(
          ThemeData(useMaterial3: true).textTheme,
        ),
      ),
    );
  }
}
