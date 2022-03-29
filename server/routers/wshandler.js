const utils = require("../utils");
var games = require("../model/gamestate").games;
var clients = require("../model/gamestate").clients;
var Game = require("../model/gamestate").Game;

module.exports = function (route, router) {

  const interval = setInterval(() => {
    clients.forEach((ws) => {
      if (ws.isAlive === false) {
        return ws.terminate()
      }

      ws.isAlive = false
      try {
        ws.ping("heartbeat");
      }
      catch (error) {
        console.log(`Removing websocket due to ${error}`);
        games.removeDyingWs(ws);
      }

    });
  }, 3000);

  router.ws(route, (ws, req) => {
    // store incoming ws connection and send welcome message
    clients.push(ws);
    ws.send(`{"cmd": "welcome"}`);
    ws.isAlive = true;
    //console.dir(ws);

    console.log(`There are ${clients.length} active ws clients in system.`);

    ws.on("ping", () => {
      console.log("ping recived");

    });

    ws.on("pong", (msg) => {
      //console.log(`${msg} pong recived`);
      ws.isAlive = true;
    });

    ws.on("close", () => {
      console.log(`Closing connection.`);
      // this ws connection is going down, remove it from our registered clients
      clients = clients.filter(conn => {
        return (conn === ws) ? false : true;
      });

      games.removeDyingWs(ws);
      console.log(`There are ${clients.length} active ws clients in system.`);
    });


    ws.on("message", function (msg) {
      console.log(`Got command ${msg}`);

      const obj = JSON.parse(msg);

      if (obj.cmd === 'create') {

        // incoming telegram format: { "cmd": "create", "request" : null }

        var newGame = new Game(ws);
        games.push(newGame);

        // console.dir(newGame);
        console.log(
          `New game ${newGame.id} has been created with ${newGame.snails.length} snails.  ${games.length} game(s) in progress`);

        let resp = { cmd: "create", response: { "game": { id: `${newGame.id}`, snails: [] } } };

        newGame.snails.forEach(elem => resp.response.game.snails.push({ id: elem.id, occupied: elem.isOccupied() }));

        // ws.send(`${JSON.stringify(resp)}`);

        clients.forEach(e => broadCastGameStates(e));

      }

      if (obj.cmd === 'gameslist') {

        // incoming telegram format: { "cmd": "create", "request" : null }
        broadCastGameStates(ws);

      }

      if (obj.cmd === 'gameinfo') {

        // incoming telegram format: { "cmd": "gameinfo", "request" : { "gameId": "LVPmM8sx" } }

        // find game on server
        let gameIdx = games.findGameIdxById(obj.request.gameId);

        if (gameIdx != null)
          games[gameIdx].sendGameInfo(ws, "gameinfo");

        else {
          // return error msg
          console.log(`Client could not process  game info cmd for game ${obj.request.gameId} due to game is not found. There are ${games.length} games in progress.`);
          ws.send(`{"cmd": "gameinfo", "response": { "error": "Game not found, please check again!", "gameId" : "${obj.request.gameId}"  }}`);

        }

      }

      if (obj.cmd === 'moveSnail') {

        // incoming telegram format: { "cmd": "moveSnail", "request" : { "gameId": "LVPmM8sx", "snailId" : "CDBYJ", speed: 12.3 } }

        // find game on server

        let gameIdx = games.findGameIdxById(obj.request.gameId);

        if (gameIdx != null) {
          // try to find and occupy snail with id

          let error = games[gameIdx].moveSnail(ws, obj.request.snailId, obj.request.speed);
          if (error) {
            ws.send(`{"cmd": "moveSnail", "response": { "accepted": false, "gameId" : "${games[gameIdx].id}" , "snailId" : "${obj.request.snailId}", "speed" : ${obj.request.speed}, "error" : "${error}" }}`);

            console.log(error);
          }
          else {
            //            clients.forEach(e => broadCastGameStates(e));
            games[gameIdx].tryToFinishRace();
            ws.send(`{"cmd": "moveSnail", "response": { "accepted": true, "gameId" : "${games[gameIdx].id}" , "snailId" : "${obj.request.snailId}", "speed" : ${obj.request.speed} }}`);
            console.log(`Client moved Snail ${obj.request.snailId} for game ${games[gameIdx].id} by ${obj.request.speed}`);

            //  games[gameIdx].sendGameInfo(ws);

            // console.dir(games[gameIdx]);
          }
        }
        else {
          // return error msg
          console.log(`Client could not join game ${obj.request.gameId} with snail ${obj.request.snailId} due to game is not found. There are ${games.length} games in progress.`);
          ws.send(`{"cmd": "moveSnail", "response": { "accepted": false, "gameId" : "${obj.request.gameId}" , "snailId" : "${obj.request.snailId}", "error" : "Game has not been found" }}`);

        }
      }

      if (obj.cmd === 'ready') {

        // incoming telegram format: { "cmd": "ready", "request" : { "gameId": "LVPmM8sx", "snailId" : "CDBYJ" } }

        // find game on server
        let gameIdx = games.findGameIdxById(obj.request.gameId);
        var snailIdx = null;

        if (gameIdx != null) {
          // try to find and occupy snail with id

          let error = games[gameIdx].readySnail(ws, obj.request.snailId);
          if (error) {
            ws.send(`{"cmd": "ready", "response": { "accepted": false, "gameId" : "${games[gameIdx].id}" , "snailId" : "${obj.request.snailId}", "error" : "${error}" }}`);

            console.log(error);
          }
          else {
            //clients.forEach(e => broadCastGameStates(e));
            //broadCastGameState(ws,  games[gameIdx]);
            games[gameIdx].updateGameInfo("gameinfo");
            games[gameIdx].tryToStartRace();

            ws.send(`{"cmd": "ready", "response": { "accepted": true, "gameId" : "${games[gameIdx].id}" , "snailId" : "${obj.request.snailId}" }}`);
            console.log(`Client marked his snail ready for game ${games[gameIdx].id} with snail ${obj.request.snailId}`);

            //  games[gameIdx].sendGameInfo(ws);

            // console.dir(games[gameIdx]);
          }
        }
        else {
          // return error msg
          let error = `Client could not mark snail ready in game ${obj.request.gameId} with snail ${obj.request.snailId} due to game is not found. There are ${games.length} games in progress.`;
          console.log(error);
          ws.send(`{"cmd": "ready", "response": { "accepted": false, "gameId" : "${obj.request.gameId}" , "snailId" : "${obj.request.snailId}", "error" :  ${error} }}`);

        }
      }
      if (obj.cmd === 'join') {

        // incoming telegram format: { "cmd": "join", "request" : { "gameId": "LVPmM8sx", "snailId" : "CDBYJ" } }

        // find game on server
        var snailIdx = null;

        let gameIdx = games.findGameIdxById(obj.request.gameId);

        if (gameIdx != null) {
          // try to find and occupy snail with id

          let error = games[gameIdx].occupySnail(ws, obj.request.snailId);
          if (error) {
            ws.send(`{"cmd": "join", "response": { "accepted": false, "gameId" : "${games[gameIdx].id}" , "snailId" : "${obj.request.snailId}", "error" : "${error}" }}`);

            console.log(error);
          }
          else {
            clients.forEach(e => broadCastGameStates(e));

            games[gameIdx].updateGameInfo("gameinfo");

            ws.send(`{"cmd": "join", "response": { "accepted": true, "gameId" : "${games[gameIdx].id}" , "snailId" : "${obj.request.snailId}" }}`);
            console.log(`Client joied for game ${games[gameIdx].id} with snail ${obj.request.snailId}`);

            //  games[gameIdx].sendGameInfo(ws);

            // console.dir(games[gameIdx]);
          }
        }
        else {
          // return error msg
          console.log(`Client could not join game ${obj.request.gameId} with snail ${obj.request.snailId} due to game is not found. There are ${games.length} games in progress.`);
          ws.send(`{"cmd": "join", "response": { "accepted": false, "gameId" : "${obj.request.gameId}" , "snailId" : "${obj.request.snailId}" }}`);

        }
      }
      if (obj.cmd === 'spectate') {

        // incoming telegram format: { "cmd": "spectate", "request" : { "gameId": "LVPmM8sx" } }

        // find game on server
        let gameIdx = games.findGameIdxById(obj.request.gameId);

        if (gameIdx != null) {
          // try to find and occupy snail with id

          clients.forEach(e => broadCastGameStates(e));

          games[gameIdx].spectateGame(ws);

          games[gameIdx].sendGameInfo(ws, "gameinfo");

          // console.dir(games[gameIdx]);

        }
        else {
          // return error msg
          let error = `Client could not spectate game ${obj.request.gameId} due to game is not found. There are ${games.length} games in progress.`;
          console.log(error);
          ws.send(`{"cmd": "spectate", "response": { "accepted": false, "gameId" : "${obj.request.gameId}" , "error": "${error}" }}`);

        }
      }


    });
  });
};

function broadCastGameStates(ws) {

  let resp = { cmd: "gameslist", response: { "games": [] } };

  games.forEach(elem => {
    let snailList = [];
    elem.snails.forEach(snail => snailList.push({ id: `${snail.id}`, occupied: snail.isOccupied(), ready: snail.isReady(), color: snail.color, speed: snail.speed }));
    resp.response.games.push({ id: elem.id, snails: snailList })
  });

  console.log(`${JSON.stringify(resp)}`);
  ws.send(`${JSON.stringify(resp)}`);
}

function broadCastGameState(ws, game) {
  game.sendGameInfo(ws, "gameinfo");
}


module.exports.games = games;