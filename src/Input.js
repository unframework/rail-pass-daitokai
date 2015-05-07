function Input(whichCodeMap) {
    var gameCodeStatus = {},
        self = this,
        num;

    this.status = gameCodeStatus;

    for (num in whichCodeMap) {
        gameCodeStatus[whichCodeMap[num]] = false;
    }

    document.body.onkeydown = function (e) {
        var gameCode = whichCodeMap[e.which];

        if (gameCode === undefined) {
            return;
        }

        var status = !!gameCodeStatus[gameCode];

        if (status) {
            return;
        }

        gameCodeStatus[gameCode] = true;
    };

    document.body.onkeyup = function (e) {
        var gameCode = whichCodeMap[e.which];

        if (gameCode === undefined) {
            return;
        }

        var status = !!gameCodeStatus[gameCode];

        if (!status) {
            return;
        }

        gameCodeStatus[gameCode] = false;
    };

    window.onblur = function (e) {
        for (var gameCode in gameCodeStatus) {
            if (gameCodeStatus[gameCode]) {
                gameCodeStatus[gameCode] = false;
            }
        }
    };
}

module.exports = Input;
