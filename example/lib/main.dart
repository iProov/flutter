import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iproov_api_client/iproov_api_client.dart';
import 'package:iproov_flutter/iproov_flutter.dart';
import 'package:uuid/uuid.dart';

import 'credentials.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iProov Example',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B5EFF)),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5EFF),
          brightness: Brightness.dark,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _scanInProgress = false;
  String? _nativeSdkVersion;

  // This code is for demo purposes only. Do not make API calls from the device
  // in production!
  final _apiClient = const ApiClient(baseUrl: 'https://$hostname/api/v2', apiKey: apiKey, secret: secret);

  @override
  void initState() {
    super.initState();
    IProov.nativeSdkVersion().then((version) => setState(() => _nativeSdkVersion = version));
  }

  void _getTokenAndLaunchIProov(AssuranceType assuranceType, ClaimType claimType, String userId) async {
    setState(() => _scanInProgress = true);
    ProgressHud.show(ProgressHudType.loading, 'Getting token...');

    String token;

    try {
      token = await _apiClient.getToken(
        assuranceType: assuranceType,
        claimType: claimType,
        userId: userId,
      );
    } catch (e) {
      setState(() => _scanInProgress = false);
      ProgressHud.dismiss();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        },
      );

      return;
    }

    // TODO: Customize your options here
    const options = Options();

    _launchIProov(token, options);
  }

  void _launchIProov(String token, Options options) {
    final stream = IProov.launch(streamingUrl: 'wss://$hostname/ws', token: token, options: options);

    stream.listen((event) {
      if (event.isFinal) {
        setState(() => _scanInProgress = false);
      }

      if (event is IProovEventConnecting) {
        ProgressHud.show(ProgressHudType.loading, 'Connecting...');
      } else if (event is IProovEventConnected) {
        ProgressHud.dismiss();
      } else if (event is IProovEventProcessing) {
        ProgressHud.show(ProgressHudType.progress, event.message);
        ProgressHud.updateProgress(event.progress, event.message);
      } else if (event is IProovEventCanceled) {
        ProgressHud.showAndDismiss(ProgressHudType.success, 'Canceled by ${event.canceler.name}');
      } else if (event is IProovEventSuccess) {
        ProgressHud.showAndDismiss(ProgressHudType.success, 'Success!');
      } else if (event is IProovEventFailure) {
        final reasons = event.reasons.map((e) => e.feedbackCode).join('\n');
        ProgressHud.showAndDismiss(ProgressHudType.error, reasons);
      } else if (event is IProovEventError) {
        ProgressHud.showAndDismiss(ProgressHudType.error, event.error.title);
      }
    });
  }

  void _launch() {
    final userId = const Uuid().v1();
    _getTokenAndLaunchIProov(
      AssuranceType.genuinePresenceAssurance,
      ClaimType.enrol,
      userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('iProov Example'),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanInProgress ? null : _launch,
        icon: _scanInProgress ? null : const Icon(Icons.face_retouching_natural),
        label: Text(_scanInProgress ? 'Scanning…' : 'Launch'),
      ),
      body: ProgressHud(
        isGlobalHud: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Stack(
              children: [
                // Hero, centered on the full screen.
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28.0),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.face_retouching_natural,
                          size: 72.0,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 28.0),
                      Text(
                        'iProov Face SDK',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Version footer, pinned to the bottom (clear of the Launch button).
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: Text(
                      'Native SDK version: ${_nativeSdkVersion ?? '…'}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
