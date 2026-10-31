import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/weight_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'theme/palette.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError =
      (d) => debugPrint('FlutterError: ${d.exceptionAsString()}');

  final auth = AuthService();
  await auth.init();
  await NotificationService.instance.init();

  runApp(WeightApp(auth: auth));
}

class WeightApp extends StatelessWidget {
  final AuthService auth;
  const WeightApp({super.key, required this.auth});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weight Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kBlue,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      // Logged in → tracker, logged out → login.
      home: ListenableBuilder(
        listenable: auth,
        builder: (_, __) {
          final me = auth.current;
          if (me == null) return LoginScreen(auth: auth);
          return WeightScreen(key: ValueKey(me.username), auth: auth);
        },
      ),
    );
  }
}
