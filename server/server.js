const express = require("express");
const app = express();
const expressWs = require("express-ws")(app);
const router = express.Router();
const utils = require("./utils");
const wsRoute = require('./routers/wshandler')
//const createLobbyRoute = require('./routers/lobby')
var games = [];

wsRoute("/", router);


app.use("/ws", router);

/*const listener = app.listen(process.env.PORT, () => {
  console.log("Your app is listening on port " + listener.address().port);
}); */


const listener = app.listen(3000, () => {
  console.log("Your app is listening on port " + listener.address().port);
});
