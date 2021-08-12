import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
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

  void getToken(String userID, ClaimType claimType, AssuranceType assuranceType) async {
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
      subscription = IProov.events.listen(handleResponse);
    }

    IProov.launch(apiClient.baseUrl, token, options);
  }

  void handleResponse(IProovEvent response) {
    if (response is IProovEventProgress) {
      ProgressHud.show(ProgressHudType.progress, response.message);
      ProgressHud.updateProgress(response.progress, response.message);
    } else if (response is IProovEventSuccess) {
      ProgressHud.showAndDismiss(ProgressHudType.success, "Success!");
    } else if (response is IProovEventFailure) {
      ProgressHud.showAndDismiss(ProgressHudType.error, response.reason);
    } else if (response is IProovEventError) {
      ProgressHud.showAndDismiss(ProgressHudType.error, response.exception.toString());
    } else if (response is IProovEventConnecting) {
      ProgressHud.show(ProgressHudType.loading, "Connecting...");
    } else if (response is IProovEventConnected) {
      ProgressHud.dismiss();
    } else if (response is IProovEventCancelled) {
      ProgressHud.dismiss();
    }
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
                    // UserID needs to change each time for enrol, unless already registered when can keep with verify
                    getToken('${random.nextInt(1000000)}flutter-example@iproov.com', ClaimType.enrol, AssuranceType.genuinePresenceAssurance);
                  },
                )
              ]
            )
          )
        )
    );
  }
}