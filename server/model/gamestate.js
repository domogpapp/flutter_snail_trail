var Snail = require("./snail").Snail;
const utils = require("../utils");

var games = [];
var clients = [];
const SNAIL_MAX = 5;
const GAME_ID_LENGTH = 6;

const GameStateEnum = Object.freeze({ "init": 1, "started": 2, "finished": 3 });

class Game {

  constructor(master) {
    this.id = utils.makeId(GAME_ID_LENGTH);
    this.master = master;
    this.initSnails();
    this.state = GameStateEnum.init;
    this.spectators = [];
  }

  initSnails() {
    this.snails = [];
    for (let i = 0; i < SNAIL_MAX; i++)
      this.snails.push(new Snail(i));
  }

  handleConnectionClose(ws) {
    // remove dying ws connection from this game
    if (ws === this.master)
      this.master = null;

    this.snails.forEach(snail => snail.handleConnectionClose(ws));

    this.spectators = this.spectators.filter(conn => {
      return (conn === ws) ? false : true;
    });

    this.updateGameInfo("gameinfo");
  }

  updateGameInfo(cmd) {

    // notify racers 
    for (let i = 0; i < this.snails.length; i++) {

      if (this.snails[i].isOccupied()) {

        this.sendGameInfo(this.snails[i].controller, cmd);
      }
    }

    // notify spectators
    for (let i = 0; i < this.spectators.length; i++)
      this.sendGameInfo(this.spectators[i], cmd);
  }

  spectateGame(ws) {

    this.spectators.push(ws);

  }

  occupySnail(ws, snailId) {
    let error = `There is no snail ${snailId} in game ${this.id}. Probaly a typo?`;
    for (let i = 0; i < this.snails.length; i++) {

      if (this.snails[i].id.toUpperCase() === snailId.toUpperCase()) {
        if (!this.snails[i].isOccupied()) {
          this.snails[i].occupy(ws);
          error = null;
          break;
        }
        else {
          error = `Could not occupy snail ${snailId} due to this snail is already occupied in game ${this.id}.`;
          break;
        }
      }
    }

    return error;
  }

  readySnail(ws, snailId) {
    let error = `There is no snail ${snailId} in game ${this.id}. Probaly a typo?`;
    for (let i = 0; i < this.snails.length; i++) {

      if (this.snails[i].id === snailId) {
        if (this.snails[i].isOccupied() && !this.snails[i].isReady()) {
          this.snails[i].markReady();
          error = null;
          break;
        }
        else {
          if (this.snails[i].isOccupied())
            error = `Could not mark snail ready ${snailId} due to this snail is not occupied yet in game ${this.id}.`;
          else
            error = `Could not mark snail ready ${snailId} due to this snail is already marked as ready in game ${this.id}.`;
          break;
        }
      }
    }

    return error;
  }

  tryToFinishRace() {
    let cntOccupied = 0;
    let speedReady = 0;

    for (let i = 0; i < this.snails.length; i++) {

      if (this.snails[i].isOccupied())
        cntOccupied++;


      if (this.snails[i].speed != 0)
        speedReady++;
    }
    if (speedReady == cntOccupied && cntOccupied > 0) {
      this.state = GameStateEnum.finished;
      setTimeout(() => {
        console.log(`Finishing game ${this.id}`);
        this.updateGameInfo("gamefinish");
      }, 2000);
    }
  }

  tryToStartRace() {
    let cntOccupied = 0;
    let cntReady = 0;

    for (let i = 0; i < this.snails.length; i++) {

      if (this.snails[i].isOccupied())
        cntOccupied++;


      if (this.snails[i].isReady())
        cntReady++;
    }
    if (cntReady == cntOccupied && cntOccupied > 0) {
      this.state = GameStateEnum.started;
      for (let i = 0; i < this.snails.length; i++) this.snails[i].speed = 0;
      setTimeout(() => {
        console.log(`Starting game ${this.id}`);
        this.updateGameInfo("gamestart");
      }, 2000);
    }
  }



  moveSnail(ws, snailId, speed) {
    let error = `There is no snail ${snailId} in game ${this.id}. Probaly a typo?`;
    for (let i = 0; i < this.snails.length; i++) {

      if (this.snails[i].id === snailId) {
        if (this.snails[i].isOccupied()) {
          this.snails[i].move(ws, speed);
          error = null;
          break;
        }
        else {
          error = `Could not move snail ${snailId} due to this snail is not occupied in game ${this.id}.`;
          break;
        }
      }
    }

    return error;
  }

  sendGameInfo(ws, cmd) {

    let snailList = [];

    this.snails.forEach(snail => snailList.push({ id: `${snail.id}`, occupied: snail.isOccupied(), ready: snail.isReady(), color: snail.color, speed: snail.speed }));

    let resp = { cmd: cmd, response: { "id": this.id, snails: snailList, spectators: this.spectators.length } };

    console.log(`${JSON.stringify(resp)}`);
    try {
      ws.send(`${JSON.stringify(resp)}`);

    } catch (error) {
      console.log(`Removing websocket due to ${error}`);
      games.removeDyingWs(ws);

    }
  }
}


games.findGameIdxById = function (gameId) {
  var gameIdx = null;

  if (gameId == null)
    return gameIdx;

  for (i = 0; i < games.length; i++) {
    if (games[i].id.toUpperCase() === gameId.toUpperCase()) {
      gameIdx = i;
      break;
    }
  }

  return gameIdx;
}

games.removeDyingWs = function (ws) {
  for (i = 0; i < games.length; i++)
    games[i].handleConnectionClose(ws);
}


module.exports = {
  games: games,
  clients: clients,
  Game: Game,
  GameStateEnum: GameStateEnum
}


