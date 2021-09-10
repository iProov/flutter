import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:flutter/material.dart';
import 'package:iproov_flutter/iproov_flutter.dart';
import 'package:iproov_sdk_example/api_client.dart';
import 'package:iproov_sdk_example/api_keys.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iProov Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _scanInProgress = false;

  // ! This code is for demo purposes only. Do not hardcode your API keys in production.
  // TODO: Add your credentials here:
  ApiClient apiClient = ApiClient(
    "https://eu.rp.secure.iproov.me/api/v2/",
    kApiKey,
    kSecret,
  );

  void getTokenAndLaunchIProov(
      AssuranceType assuranceType, ClaimType claimType, String userId) async {
    try {
      setState(() => _scanInProgress = true);
      final token = await apiClient.getToken(assuranceType, claimType, userId);
      final options = Options();
      // Example configuration
      // final options = Options(
      //   ui: UiOptions(
      //     lineColor: Colors.red,
      //     backgroundColor: Colors.teal,
      //     genuinePresenceAssurance: GenuinePresenceAssuranceUiOptions(
      //       autoStartDisabled: true,
      //       notReadyTintColor: Colors.red,
      //       progressBarColor: Colors.cyan,
      //       readyTintColor: Colors.lightGreen,
      //     ),
      //     livenessAssurance: LivenessAssuranceUiOptions(
      //       primaryTintColor: Colors.grey,
      //       secondaryTintColor: Colors.yellow,
      //     ),
      //   ),
      // );
      await launchIProov(token, options);
    } on Exception catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                child: Text("OK"),
                onPressed: () => Navigator.pop(context),
              )
            ],
          );
        },
      );
    } finally {
      setState(() => _scanInProgress = false);
    }
  }

  Future<void> launchIProov(String token, Options options) async {
    final iProov =
        IProov(streamingUrl: apiClient.baseUrl, token: token, options: options);
    await iProov.launch((event) {
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
        ProgressHud.showAndDismiss(ProgressHudType.error, event.error.message);
      }
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('iProov Example'),
      ),
      body: ProgressHud(
        isGlobalHud: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              TextButton(
                child: Text(
                  '🚀 Launch',
                  style: TextStyle(fontSize: 20.0),
                ),
                onPressed: _scanInProgress
                    ? null
                    : () {
                        final userId = Uuid()
                            .v1(); // Generate a random UUID as the User ID for testing purposes
                        getTokenAndLaunchIProov(
                          AssuranceType
                              .genuinePresenceAssurance, // livenessAssurance or genuinePresenceAssurance
                          ClaimType.enrol, // enrol or verify
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
