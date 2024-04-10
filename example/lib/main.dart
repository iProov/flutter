import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
        primarySwatch: Colors.blue,
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

  // This code is for demo purposes only. Do not make API calls from the device
  // in production!
  final _apiClient = const ApiClient(baseUrl: 'https://$hostname/api/v2', apiKey: apiKey, secret: secret);

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
        ProgressHud.showAndDismiss(ProgressHudType.error, event.reason);
      } else if (event is IProovEventError) {
        ProgressHud.showAndDismiss(ProgressHudType.error, event.error.title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return Scaffold(
      appBar: AppBar(
        title: const Text('iProov Example'),
      ),
      body: ProgressHud(
        isGlobalHud: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri("https://www.google.com")),
                  initialSettings: InAppWebViewSettings(useHybridComposition: false),
                ),
              ),
              TextButton(
                child: const Text(
                  '🚀 Launch',
                  style: TextStyle(fontSize: 20.0),
                ),
                onPressed: _scanInProgress
                    ? null
                    : () {
                        // Generate a random UUID as the User ID for testing purposes
                        final userId = const Uuid().v1();
                        _getTokenAndLaunchIProov(
                          // livenessAssurance or genuinePresenceAssurance
                          AssuranceType.genuinePresenceAssurance,
                          // enrol or verify
                          ClaimType.enrol,
                          userId,
                        );
                      },
              )
            ],
          ),
        ),
      ),
    );
  }
}
