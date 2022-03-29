// Animation

import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:snail_trail/pages/gamelist.dart';
import 'package:snail_trail/utils.dart';
import 'package:snail_trail/snail.dart';

class GameDetailsPage extends StatefulWidget {
  final String snailId;
  final Map<String, dynamic> gameInfo;

  GameDetailsPage({this.snailId, this.gameInfo});
  _GameDetailsPageState createState() => _GameDetailsPageState();
}

class _GameDetailsPageState extends State<GameDetailsPage>
    with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  Map<String, dynamic> gameInfo;
  List snails = [];

  num maxSpeed = 0;
  List moves = [
    Curves.easeInOutQuint,
    Curves.easeInOutQuart,
    Curves.elasticIn,
    Curves.elasticInOut,
    Curves.bounceOut
  ];

  @override
  initState() {
    super.initState();
    gameInfo = widget.gameInfo;
    snails = gameInfo["snails"];
  }

  @override
  void dispose() {
    super.dispose();
  }

  showSnails(double width) {
    double ratio = 0;

    if (maxSpeed != 0) ratio = (width * 2 / maxSpeed) * 0.7;

    return Row(
      children: [
        Spacer(),
        ...snails
            .map((e) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                            height: 76,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: width / 5 - 21,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            e["speed"].toString(),
                                            style:
                                                TextStyle(fontSize: width / 30),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                0, 0, 8, 0),
                                            child: Text(e["id"],
                                                style: TextStyle(
                                                    fontSize: width / 25,
                                                    color: Colors.accents[
                                                        e["color"] * 2])),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  TrafficLight(
                                    size: 20,
                                    state: e["occupied"] && e["ready"]
                                        ? TrafficLightState.green
                                        : e["occupied"] && !e["ready"]
                                            ? TrafficLightState.yellow
                                            : TrafficLightState.red,
                                  ),
                                ],
                              ),
                            )),
                        SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                    AnimatedPositioned(
                      duration: Duration(
                          milliseconds:
                              2000 + 100 * Random().nextInt(e["speed"] + 1)),
                      curve: moves[Random().nextInt(moves.length)],
                      left: 0,
                      bottom: e["speed"] * ratio,
                      child: SnailWidget(
                        width: width / 7,
                        height: (width / 5) * 1.95,
                        offset: Offset(0, 25 + e["speed"] * ratio),
                        houseOffsetRatio: 0,
                        forward: -0.15,
                        color: Colors.accents[e["color"] * 2],
                      ),
                    ),
                  ],
                ))
            .toList(),
        Spacer()
      ],
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("Game ${gameInfo["id"]}"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              child: Icon(Icons.exit_to_app),
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SnailGameListPage()));
                NotificationController().channel.sink.add(
                    '{ "cmd": "gameinfo", "request" : {"gameId": "${widget.gameInfo["id"]}"  }}');
              },
            ),
          )
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraint) {
            double width = constraint.maxHeight / 2;
            print(width);
            return Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Color.fromRGBO(157, 78, 40, 1),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(
                    "images/background.jpg",
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: StreamBuilder<Object>(
                      stream: NotificationController().streamController.stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          print("Game Details: " + snapshot.data);
                          Map<String, dynamic> resp = jsonDecode(snapshot.data);

                          if (resp["cmd"] != null &&
                              resp["cmd"] == "gameinfo") {
                            gameInfo = resp["response"];
                            snails = resp["response"]["snails"] ?? [];
                          }

                          if (resp["cmd"] != null &&
                              resp["cmd"] == "gamestart") {
                            gameInfo = resp["response"];
                            snails = resp["response"]["snails"] ?? [];
                          }

                          if (resp["cmd"] != null &&
                              resp["cmd"] == "gamefinish") {
                            gameInfo = resp["response"];
                            snails = resp["response"]["snails"] ?? [];
                            maxSpeed = 0;
                            snails.forEach((snail) {
                              if (snail["speed"] > maxSpeed)
                                maxSpeed = snail["speed"];
                            });
                          }
                        }

                        return showSnails(width);
                      }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
