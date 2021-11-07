import 'dart:async';

import 'package:flutter/material.dart';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_onboarding_flutter/at_onboarding_flutter.dart'
    show Onboarding;
import 'package:at_utils/at_logger.dart' show AtSignLogger;
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:at_app_flutter/at_app_flutter.dart' show AtEnv;
import 'package:at_commons/at_commons.dart';
import 'dart:math';

Future<void> main() async {
  await AtEnv.load();
  runApp(const MyApp());
}

Future<AtClientPreference> loadAtClientPreference() async {
  var dir = await getApplicationSupportDirectory();
  return AtClientPreference()
        ..rootDomain = AtEnv.rootDomain
        ..namespace = AtEnv.appNamespace
        ..hiveStoragePath = dir.path
        ..commitLogPath = dir.path
        ..isLocalStoreRequired = true
      // TODO set the rest of your AtClientPreference here
      ;
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // * load the AtClientPreference in the background
  Future<AtClientPreference> futurePreference = loadAtClientPreference();
  AtClientPreference? atClientPreference;

  final AtSignLogger _logger = AtSignLogger(AtEnv.appNamespace);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // * The onboarding screen (first screen)
      theme: ThemeData(primaryColor: Colors.pink),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MyApp'),
        ),
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                var preference = await futurePreference;
                setState(() {
                  atClientPreference = preference;
                });
                Onboarding(
                  context: context,
                  atClientPreference: atClientPreference!,
                  domain: AtEnv.rootDomain,
                  rootEnvironment: AtEnv.rootEnvironment,
                  appAPIKey: AtEnv.appApiKey,
                  onboard: (value, atsign) {
                    _logger.finer('Successfully onboarded $atsign');
                  },
                  onError: (error) {
                    _logger.severe('Onboarding throws $error error');
                  },
                  nextScreen: const HomeScreen(),
                );
              },
              child: const Text('Onboard an @sign'),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

//* The next screen after onboarding (second screen)
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  List<Container> _currentFeed = [];
  List<String> _currentFriends = ["@structuraliceskating"];

  void _onBNBTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // The navigation bar on the bottom
  BottomNavigationBar getBNB() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.plus_one), label: "Add activity"),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
      ],
      currentIndex: _selectedIndex,
      onTap: _onBNBTapped,
    );
  }

  Container card(
      String name, String timeSpent, String location, String activity) {
    return Container(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
        width: double.maxFinite,
        child: Card(
          elevation: 5,
          child: ListTile(
            title: Text(name + " " + activity + " for " + timeSpent + "."),
            subtitle: Text(location),
          ),
        ));
  }

  void sendData(List<String> dataToBeSent) {
    var atClientManager = AtClientManager.getInstance();
    AtClient atclient = atClientManager.atClient;
  }

  Future<List<List<String>>> getData() async {
    List<List<String>> res = [];
    var atClientManager = AtClientManager.getInstance();
    AtClient atclient = atClientManager.atClient;
    List<AtKey> keys = await atclient.getAtKeys();
    for (int i = 0; i < keys.length; i++) {
      AtKey pizzaKey = keys[i];
      res.add([pizzaKey.sharedBy.toString()]);
      AtValue pizzaValue = await atclient.get(pizzaKey);
      res[i].addAll(pizzaValue.value.toString().split("`"));
    }
    print(res);
    return res;
  }

  void refreshFeed() async {
    List<List<String>> newData = await getData();
    setState(() {
      _currentFeed = [];
      for (int i = 0; i < newData.length; i++) {
        if (newData[i].length == 4) {
          _currentFeed.add(
              card(newData[i][0], newData[i][1], newData[i][2], newData[i][3]));
        }
      }
    });
  }

  ListView FeedView() {
    return ListView(
      children: _currentFeed,
    );
  }

  Center settingsTitle() {
    return Center(
        child: Container(
      child: Text("Your @handle is @rzh"),
      padding: EdgeInsets.all(16.0),
    ));
  }

  Center AddFriendsTitle() {
    return Center(
        child: Container(
      child: const Text("Add your friends!",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
      padding: EdgeInsets.all(16.0),
    ));
  }

  ListView SettingsView() {
    return ListView(
      children: [settingsTitle(), AddFriendsTitle()],
    );
  }

  Form AddActivityView() {
    TextEditingController tec1 = TextEditingController();
    TextEditingController tec2 = TextEditingController();
    TextEditingController tec3 = TextEditingController();
    return Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Activity:'),
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'e.g. Jogging',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                          controller: tec1,
                        )
                      ])),
              Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Time Spent:'),
                        TextFormField(
                          controller: tec2,
                          decoration: const InputDecoration(
                            hintText: 'e.g. 40 mins',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        )
                      ])),
              Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text('Location:'),
                        TextFormField(
                          controller: tec3,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Goheen Walk',
                          ),
                          validator: (String? value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                        )
                      ])),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (_formKey.currentState!.validate()) {
                      // Process data.
                    }
                  },
                  child: const Text('Import from Google Fitness'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Validate will return true if the form is valid, or false if
                    // the form is invalid.
                    if (true) {
                      var atClientManager = AtClientManager.getInstance();
                      AtClient atclient = atClientManager.atClient;
                      AtKey sendKey = AtKey();
                      sendKey.key =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      sendKey.sharedWith = "@structuraliceskating";
                      String msg =
                          tec1.text + "`" + tec2.text + "`" + tec3.text;
                      atclient.put(sendKey, msg);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(primarySwatch: Colors.pink),
        home: Scaffold(
            floatingActionButton: _selectedIndex == 0
                ? FloatingActionButton(
                    onPressed: refreshFeed,
                    child: const Icon(Icons.refresh),
                  )
                : null,
            appBar: AppBar(
              title: Text("Priv@teFit"),
            ),
            bottomNavigationBar: getBNB(),
            body: [FeedView(), AddActivityView(), SettingsView()]
                .elementAt(_selectedIndex)));
  }
}
