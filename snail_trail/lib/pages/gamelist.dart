import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:snail_trail/pages/gamedetails.dart';

import '../utils.dart';

class SnailGameListPage extends StatefulWidget {
  @override
  _SnailGameListPageState createState() => _SnailGameListPageState();
}

class _SnailGameListPageState extends State<SnailGameListPage> {
  var _streamController;
  List<Widget> gameWidgets = [];
  List gameStates = [];
  final trailController = TextEditingController();
  bool validate = false;

  @override
  void initState() {
    super.initState();

    _streamController = NotificationController().streamController;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Snail Games"),
        actions: [
          InkWell(
            child: Icon(Icons.refresh),
            onTap: () {
              NotificationController()
                  .channel
                  .sink
                  .add('{ "cmd": "gameslist", "payload" : { }}');
            },
          )
        ],
      ),
      body: StreamBuilder<Object>(
          stream: _streamController.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              // got messge snapshot.data from server
              print("Games: " + snapshot.data);
              Map<String, dynamic> resp = jsonDecode(snapshot.data);
              gameWidgets = [];
              if (resp["cmd"] == "welcome")
                NotificationController()
                    .channel
                    .sink
                    .add('{ "cmd": "gameslist", "payload" : { }}');
              else if (resp["cmd"] == "create")
                NotificationController()
                    .channel
                    .sink
                    .add('{ "cmd": "gameslist", "payload" : { }}');
              else if (resp["cmd"] == "gameslist") {
                gameStates = resp["response"]["games"];
              } else if (resp["cmd"] == "gameinfo") {
                // TODO move to GAME Page
                print("Got gameinfo spectator joined");
                Future.microtask(() => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => GameDetailsPage(
                              gameInfo: resp["response"],
                            ))));
              }

              gameStates.forEach((e) {
                int occupiedSnail = 0;
                e["snails"].forEach((s) {
                  if (s["occupied"]) occupiedSnail++;
                });

                var gameWidget = ExpansionTile(
                  title: InkWell(
                    onTap: () {
                      NotificationController().channel.sink.add(
                          '{ "cmd": "spectate", "request" : { "gameId": "${e["id"]}" } }');
                    },
                    child: Text(
                      ' ${e["id"]}    $occupiedSnail/${e["snails"].length}',
                      style: TextStyle(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                    ),
                  ),
                  children: <Widget>[
                    ListTile(
                      title: Column(
                        children: [
                          ...e["snails"].map((s) {
                            return Container(
                              color: s["occupied"]
                                  ? Colors.black12
                                  : Colors.transparent,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.accents[s["color"] * 2],
                                    size: 20,
                                  ),
                                  Text(
                                    s["id"],
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.accents[s["color"] * 2]),
                                  ),
                                  Text(s["occupied"] ? "inGame" : "free"),
                                  Text(s["ready"] ? "ready" : "waiting"),
                                  Text(s["speed"].toString())
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    )
                  ],
                );

                gameWidgets.add(gameWidget);
              });

              // print(" $gameId has ${snails}");

              return Container(
                width: double.infinity,
                color: NotificationController().disconnected
                    ? Colors.red.withAlpha(128)
                    : Colors.green.withAlpha(128),
                child: ListView(
                  children: <Widget>[
                    Text(
                      "Enter Game ID:",
                      style: TextStyle(fontSize: 30),
                    ),
                    //TrafficLight(notifier: MyCustomNotifier(value: true)),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 300,
                        height: 50,
                        child: TextField(
                          obscureText: false,
                          controller: trailController,
                          decoration: InputDecoration(
                            errorText: validate ? "Enter trail ID" : null,
                            border: OutlineInputBorder(),
                            labelText: 'Trail ID',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: () {
                          NotificationController().channel.sink.add(
                              '{ "cmd": "spectate", "request" : { "gameId": "${trailController.text}" } }');
                        },
                        child: Text(
                          "Spectate Trail",
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    ...gameWidgets
                  ],
                ),
              );
            } else
              return Container();
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // send messge snapshot.data from server

          NotificationController()
              .channel
              .sink
              .add('{ "cmd": "create", "payload" : { "players" : 5}}');
        },
        tooltip: 'Create',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
