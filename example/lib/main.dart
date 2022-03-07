import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iproov_flutter/iproov_flutter.dart';
import 'package:iproov_sdk_example/api_client.dart';
import 'package:iproov_sdk_example/api_keys.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key key}) : super(key: key);

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
  const MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _scanInProgress = false;

  // This code is for demo purposes only. Do not make API calls from the device
  // in production!
  ApiClient apiClient = ApiClient(
    "https://eu.rp.secure.iproov.me/api/v2/",
    apiKey,
    secret,
  );

  void getTokenAndLaunchIProov(
      AssuranceType assuranceType, ClaimType claimType, String userId) async {
    setState(() => _scanInProgress = true);
    ProgressHud.show(ProgressHudType.loading, "Getting token...");

    String token;

    try {
      token = await apiClient.getToken(assuranceType, claimType, userId);
    } on Exception catch (e) {
      setState(() => _scanInProgress = false);
      ProgressHud.dismiss();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        },
      );

      return;
    }

    final options = Options();
    options.ui.floatingPromptEnabled = true;
    // Example configuration
    // options.ui.lineColor = Colors.red;
    // options.ui.backgroundColor = Colors.teal;
    // options.ui.genuinePresenceAssurance.autoStartDisabled = true;
    // options.ui.genuinePresenceAssurance.notReadyTintColor = Colors.red;
    // options.ui.genuinePresenceAssurance.progressBarColor = Colors.cyan;
    // options.ui.genuinePresenceAssurance.readyTintColor = Colors.lightGreen;
    // options.ui.livenessAssurance.primaryTintColor = Colors.grey;
    // options.ui.livenessAssurance.secondaryTintColor = Colors.yellow;
    launchIProov(token, options);
  }

  void launchIProov(String token, Options options) {
    IProov.launch(
      streamingUrl: apiClient.baseUrl,
      token: token,
      options: options,
      callback: (event) {
        if (event.isFinal) {
          setState(() => _scanInProgress = false);
        }

        if (event is IProovEventConnecting) {
          ProgressHud.show(ProgressHudType.loading, "Connecting...");
        } else if (event is IProovEventConnected) {
          ProgressHud.dismiss();
        } else if (event is IProovEventProgress) {
          ProgressHud.show(ProgressHudType.progress, event.message);
          ProgressHud.updateProgress(event.progress, event.message);
        } else if (event is IProovEventCancelled) {
          ProgressHud.dismiss();
        } else if (event is IProovEventSuccess) {
          ProgressHud.showAndDismiss(ProgressHudType.success, "Success!");
        } else if (event is IProovEventFailure) {
          ProgressHud.showAndDismiss(ProgressHudType.error, event.reason);
        } else if (event is IProovEventError) {
          ProgressHud.showAndDismiss(
              ProgressHudType.error, event.error.title ?? "Error");
        }
      },
    );
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
                        getTokenAndLaunchIProov(
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
