import 'dart:async';

import 'package:flutter/material.dart';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class NotificationController {
  static final NotificationController _singleton =
      new NotificationController._internal();

  StreamController<String> streamController =
      new StreamController.broadcast(sync: true);

  String wsUrl = 'ws://localhost:3000/ws';

  bool disconnected = true;

  WebSocketChannel channel;

  factory NotificationController() {
    return _singleton;
  }

  NotificationController._internal() {
    initWebSocketConnection();
  }

  void setConnected(bool isConnected) {
    disconnected = !isConnected;
    if (isConnected)
      streamController.add('{ "status": "Connected" }');
    else
      streamController.add('{ "status": "Disconnected" }');
  }

  initWebSocketConnection() async {
    await Future.delayed(Duration(seconds: 3));
    print("conecting...");
    this.channel?.sink?.close();

    this.channel = await connectWs();
    await Future.delayed(Duration(seconds: 3));
    print("socket connection initializied");
    broadcastNotifications();
  }

  broadcastNotifications() {
    try {
      this.channel.stream.listen((streamData) {
        setConnected(true);
        print(streamData);
        streamController.add(streamData);
      }, onDone: () {
        print("conecting aborted");
        setConnected(false);

        initWebSocketConnection();
      }, onError: (e) {
        print('Server error: $e');
        setConnected(false);

        initWebSocketConnection();
      });
    } catch (e) {
      print("Failed to listen to stream!");
    }
  }

  connectWs() async {
    try {
      return WebSocketChannel.connect(
        Uri.parse(wsUrl),
      );
    } catch (e) {
      print("Error! can not connect WS connectWs " + e.toString());
      setConnected(false);
      channel.sink.close(status.goingAway);
      return await connectWs();
    }
  }
}

class Snail extends Object {
  final String id;
  bool occupied;

  Snail({this.id, this.occupied});

  @override
  String toString() {
    // TODO: implement toString
    return "My name is: $id and im occupied $occupied";
  }
}

// class SnailWidget extends StatelessWidget {
//   final Snail snail;

//   SnailWidget({this.snail});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//         color: Colors.blue,
//         child: Column(children: [
//           Text(snail.id),
//           snail.occupied
//               ? Icon(Icons.radio_button_checked)
//               : Icon(Icons.radio_button_off)
//         ]));
//   }
// }

class SnailCard extends StatelessWidget {
  final Map<String, dynamic> snail;

  SnailCard({this.snail});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Card(
      color: Colors.accents[snail["color"] * 2].withAlpha(128),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(width: 80, child: Image.asset('assets/images/snail.png')),
            Text(
              snail["id"],
              style: TextStyle(
                  color: Colors.accents[snail["color"] * 2].withAlpha(128)),
            ),
            Text(
              "occupied : ${snail["occupied"]}",
              style: TextStyle(
                  color:
                      snail["occupied"] as bool ? Colors.blue : Colors.black),
            ),
            Text("ready : ${snail["ready"]}")
          ],
        ),
      ),
    );
  }
}

enum TrafficLightState { red, yellow, green }

class TrafficLight extends StatelessWidget {
  final TrafficLightState state;

  final double size;

  const TrafficLight({
    this.state = TrafficLightState.red,
    this.size = 60,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      child: Column(
        children: [
          Column(
            children: [
              Icon(
                Icons.circle,
                color: state == TrafficLightState.red
                    ? Colors.red
                    : Colors.red.withAlpha(65),
                size: size,
              ),
              Icon(
                Icons.circle,
                color: state == TrafficLightState.yellow
                    ? Colors.yellow
                    : Colors.yellow.withAlpha(65),
                size: size,
              ),
              Icon(
                Icons.circle,
                color: state == TrafficLightState.green
                    ? Colors.green
                    : Colors.green.withAlpha(65),
                size: size,
              )
            ],
          ),
        ],
      ),
      decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.all(Radius.circular(20))),
    );
  }
}
