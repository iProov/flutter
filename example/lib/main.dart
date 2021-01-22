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

  TokenApi tokenApi;
  Future<String> futureToken;

  @override
  void initState() {
    super.initState();
    IProovSDK.iProovListenerEventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);
    tokenApi = TokenApi();
  }

  void getToken(String userID, String claimType, String assuranceType) async {
    String token = await tokenApi.getToken(userID, claimType, assuranceType);
    IProovSDK.launch(tokenApi.baseUrl, token);
  }

  void _onEvent(Object event) {
    print("onEvent $event");
  }

  void _onError(Object error) {
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
                    getToken('ksdfgsjs@ssdgh.ldfgl', 'enrol', 'genuine_presence');
                  },
                )
              ]
            )
        )
    );
  }
}