import 'dart:math';

import 'package:flutter/material.dart';
import 'package:iproov_sdk/iproov_sdk.dart';
import 'package:iproov_sdk_example/api-client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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

  IProovApiClient tokenApi = IProovApiClient();
  Future<String> futureToken;
  Random random = new Random();

  @override
  void initState() {
    super.initState();
    IProov.iProovListenerEventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
  }

  void getToken(String userID, ClaimType claimType, AssuranceType assuranceType) async {
    String token = await tokenApi.getToken(userID, claimType, assuranceType);
    Options options = Options();

    // You can just use Flutter/Dart Colors for all Color types
    // options.ui.lineColor = Colors.red;

    // For certificates you add them to the android/app/src/main/res/raw folder and reference them here like below (no extension)
    // options.network.certificates = [ "raw/customer__certificate" ];

    // For font assets in the android/app/src/main/assets folder we just give the full name plus extension
    // options.ui.fontPath = "montserrat_regular.ttf";

    // For font resources in the android/app/src/main/res/font folder we just give the name without extension
    // options.ui.fontResource = "montserrat_bold";

    // For logo, only logoImageResource is available, in the android/app/src/main/res/drawable folder we just give the name without extension
    // options.ui.logoImageResource = "ic_launcher";

    IProov.launch(tokenApi.baseUrl, token, options);
  }

  void _onEvent(Object event) {
    // This is where responses come back
    if (event is Map<String, dynamic>) {
      double progress = event["progress"];
      String message = event["message"];
      print("onEvent Progress=$progress message=$message");
    } else
      print("onEvent $event");
  }

  void _onError(Object error) {
    // This is where errors come back
    print("onError $error");
  }

  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
            child: Column(
              children: <Widget>[
                FlatButton(
                  color: Colors.red,
                  child: Text(
                    'Launch',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.white,
                    ),
                  ),
                  onPressed: () {
                    // UserID needs to change each time for enrol, unless already registered when can keep with verify
                    getToken('${random.nextInt(1000000)}ksdgfgsjs@ssdguh.ldfgl', ClaimType.ENROL, AssuranceType.GENUINE_PRESENCE_ASSURANCE);
                  },
                )
              ]
            )
        )
    );
  }
}