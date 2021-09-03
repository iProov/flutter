import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:iproov_flutter/iproov_flutter.dart';
import 'package:iproov_sdk_example/api_client.dart';

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
      home: MyHomePage(title: 'iProov Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  // TODO: Add your credentials here:
  ApiClient apiClient = ApiClient(
      "https://eu.rp.secure.iproov.me/api/v2/",
      "< YOUR API KEY >",
      "< YOUR SECRET >"
  );

  Future<String> futureToken;
  Random random = new Random();
  StreamSubscription<IProovEvent> subscription;

  void getTokenAndLaunchIProov(AssuranceType assuranceType, ClaimType claimType, String userId) async {

    String token;
    try {
      token = await apiClient.getToken(assuranceType, claimType, userId);
    } on Exception catch (e) {

      showDialog(context: context, builder: (context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              }
            )
          ]
        );
      });

      return;
    }

    var options = Options();

    // Examples:
    // options.ui.lineColor = Colors.red;
    // options.ui.backgroundColor = Colors.teal;
    // options.ui.genuinePresenceAssurance.notReadyTintColor = Colors.red;
    // options.ui.genuinePresenceAssurance.progressBarColor = Colors.cyan;
    // options.ui.genuinePresenceAssurance.readyTintColor = Colors.lightGreen;
    // options.ui.livenessAssurance.primaryTintColor = Colors.grey;
    // options.ui.livenessAssurance.secondaryTintColor = Colors.yellow;

    launchIProov(token, options);
  }

  void launchIProov(String token, Options options) {
    if (subscription == null) {
      subscription = IProov.events.listen((event) {
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

    IProov.launch(apiClient.baseUrl, token, options);
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
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
                    style: TextStyle(
                      fontSize: 20.0,
                    ),
                  ),
                  onPressed: () {
                    String userId = Uuid().v1();  // Generate a random UUID as the User ID for testing purposes
                    getTokenAndLaunchIProov(
                      AssuranceType.genuinePresenceAssurance, // livenessAssurance or genuinePresenceAssurance
                      ClaimType.enrol, // enrol or verify
                      userId);
                  },
                )
              ]
            )
          )
        )
    );
  }
}