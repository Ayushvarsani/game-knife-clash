import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'ads/services/mobile_ads_initializer.dart';
// import 'ads/services/rewarded_ad_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use the Rajdhani font bundled in assets/fonts (registered in pubspec) and
  // never fetch it over the network. Removes the first-launch font download
  // delay and makes the app work offline.
  GoogleFonts.config.allowRuntimeFetching = false;

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const KnifeHitApp());

  // Ads disabled — uncomment to re-enable Mobile Ads SDK initialization.
  // MobileAdsInitializer.ensureInitialized();
  // RewardedAdService.instance.preload();
}

class KnifeHitApp extends StatelessWidget {
  const KnifeHitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Knife Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.rajdhaniTextTheme().apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
