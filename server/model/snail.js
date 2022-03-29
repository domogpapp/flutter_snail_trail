const utils = require("../utils");

const SNAIL_ID_LENGTH = 4;

class Snail {

    constructor(color) {
        this.id = utils.makeSnailId(SNAIL_ID_LENGTH);
        this.controller = null;
        this.speed = 0.0;
        this.ready = false;
        this.color = color;
    }

    isOccupied() { return this.controller != null; }

    occupy(ws) {
        this.controller = ws;
    }

    isReady() { return this.ready; }

    markReady() {
        this.ready = true;
    }

    move(ws, speed) {
        this.speed = speed;
    }

    handleConnectionClose(ws) {
        // remove dying ws connection from this snail
        if (ws === this.controller) {
            this.controller = null;
            this.ready = false;
            this.speed = 0;
        }
    }
}

module.exports = {
    Snail: Snail
}