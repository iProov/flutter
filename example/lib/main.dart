import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:bmprogresshud/bmprogresshud.dart';
import 'package:iproov_sdk/iproov_sdk.dart';
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

  void getTokenAndLaunchIProov(String userID, ClaimType claimType, AssuranceType assuranceType) async {
    String token = await apiClient.getToken(userID, claimType, assuranceType);
    Options options = Options();

    // You can just use Flutter/Dart Colors for all Color types
    //   options.ui.lineColor = Colors.red;

    // For certificates you add them to the android/app/src/main/res/raw folder and reference them here like below (no extension)
    //   options.network.certificates = [ "raw/customer__certificate" ];

    // For font assets in the android/app/src/main/assets folder we just give the full name plus extension
    //   options.ui.fontPath = "montserrat_regular.ttf";

    // For font resources in the android/app/src/main/res/font folder we just give the name without extension
    //   options.ui.fontResource = "montserrat_bold";

    // For logo, only logoImageResource is available, in the android/app/src/main/res/drawable folder we just give the name without extension
    //   options.ui.logoImageResource = "ic_launcher";

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
          ProgressHud.showAndDismiss(ProgressHudType.error, event.exception.toString());
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
                        userId,
                        ClaimType.enrol, // enrol or verify
                        AssuranceType.genuinePresenceAssurance); // livenessAssurance or genuinePresenceAssurance
                  },
                )
              ]
            )
          )
        )
    );
  }
}