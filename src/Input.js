function Input(whichCodeMap) {
    var gameCodeStatus = {},
        self = this,
        num;

    this.status = gameCodeStatus;

    for (num in whichCodeMap) {
        gameCodeStatus[whichCodeMap[num]] = false;
    }

    $(document.body).keydown(function (e) {
        var gameCode = whichCodeMap[e.which];

        if (gameCode === undefined) {
            return;
        }

        var status = !!gameCodeStatus[gameCode];

        if (status) {
            return;
        }

        gameCodeStatus[gameCode] = true;

        $(self).trigger('key:' + gameCode, [ true ]);
    });

    $(document.body).keyup(function (e) {
        var gameCode = whichCodeMap[e.which];

        if (gameCode === undefined) {
            return;
        }

        var status = !!gameCodeStatus[gameCode];

        if (!status) {
            return;
        }

        gameCodeStatus[gameCode] = false;

        $(self).trigger('key:' + gameCode, [ false ]);
    });

    $(window).blur(function (e) {
        for (var gameCode in gameCodeStatus) {
            if (gameCodeStatus[gameCode]) {
                gameCodeStatus[gameCode] = false;

                $(self).trigger('key:' + gameCode, [ false ]);
            }
        }
    });
}

module.exports = Input;
