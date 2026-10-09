import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = SimonSettings();
  await settings.load();
  final audio = SimonAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  final store = StoreService();
  runApp(SimonApp(settings: settings, audio: audio, store: store));
}

class SimonApp extends StatefulWidget {
  final SimonSettings settings;
  final SimonAudio audio;
  final StoreService store;
  const SimonApp(
      {super.key,
      required this.settings,
      required this.audio,
      required this.store});

  @override
  State<SimonApp> createState() => _SimonAppState();
}

class _SimonAppState extends State<SimonApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Warm up the store in the background; the Pro screen shows an honest
    // "available after store setup" state until this resolves.
    widget.store.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Simon',
        debugShowCheckedModeBanner: false,
        home: SplashScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }
}
