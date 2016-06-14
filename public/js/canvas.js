
/**
 * 集中線メーカー
 * @param {obj} canvas object
 * @param {number} centralX: 集中線を配置するx座標
 * @param {number} centralY: 集中線を配置するy座標
 * @param {number} lineWidth: 線の太さ(ランダムの上限)
 * @param {number} lineNum: 線の数
 * @param {number} circleRadiusMax: 集中線の円形の半径上限
 * @param {number} circleRadiusMin: 集中線の円形の半径下限
 * @param {string} lineColor: 集中線の色
 */

var focusLine = function(cs, centralX, centralY, lineWidth, lineNum, circleRadiusMax, circleRadiusMin, lineColor) {

    var ctx = cs.getContext('2d');
    var lines = [];

    // canvasの中心から角までの斜辺距離を円の半径とする
    // 中心をズラす場合は、もっと大きな値を設定してやる(引数でできるようにすべきか)
    var csRadius = Math.sqrt(Math.pow(cs.width / 2, 2) + Math.pow(cs.height / 2, 2)) | 0;

    /**
     * ランダムな整数を返す
     * @param max 最大値
     * @param min 最小値
     * @return min ~ max
     */
    var getRandomInt = function(max, min) {
        return Math.floor(Math.random() * (max - min)) + min;
    };

    /**
     * 円周上の座標を返す
     * @param d 角度
     * @param r 半径
     * @param cx, cy 中心座標
     */
    var getCircumPos = {
        // x座標
        x: function(d, r, cx) {
            return Math.cos(Math.PI / 180 * d) * r + cx;
        },
        // y座標
        y: function(d, r, cy) {
            return Math.sin(Math.PI / 180 * d) * r + cy;
        }
    };

    /**
     * @constructor
     */
    var Liner = function() {
        this.initialize();
    };
    Liner.prototype = {
        /* initialize()内の設定をsetPos()内へ移すと、アニメーションの動きが変わる */
        initialize: function() {
            this.deg       = getRandomInt(360, 0);
        },
        setPos: function() {
            this.moveDeg   = this.deg + (getRandomInt(lineWidth, 1) / 10);
            this.endRadius = getRandomInt(circleRadiusMax, circleRadiusMin);

            // 開始座標
            this.startPos = {
                x: getCircumPos.x(this.deg, csRadius, centralX),
                y: getCircumPos.y(this.deg, csRadius, centralY)
            };

            // 移動座標
            this.movePos = {
                x: getCircumPos.x(this.moveDeg, csRadius, centralX),
                y: getCircumPos.y(this.moveDeg, csRadius, centralY)
            };

            // 終了座標
            this.endPos = {
                x: getCircumPos.x(this.moveDeg, this.endRadius, centralX),
                y: getCircumPos.y(this.moveDeg, this.endRadius, centralY)
            };
        },
        update: function() {
            this.setPos();
        },
        draw: function() {
            ctx.beginPath();
            ctx.lineWidth = 1;
            ctx.fillStyle = lineColor;
            ctx.moveTo(this.startPos.x, this.startPos.y);
            ctx.lineTo(this.movePos.x,  this.movePos.y);
            ctx.lineTo(this.endPos.x,   this.endPos.y);
            ctx.fill();
            ctx.closePath();
        },
        render: function() {
            this.update();
            this.draw();
        }
    };

    /**
     * 線インスタンスの作成
     * @return lines[instance, instance...];
     */
    function createLines(num) {
        var i = 0;
        for (; i < num; i++) {
            lines[lines.length] = new Liner();
        }
    }

    /**
     * 描画
     */
    function render() {
        var i = 0;
        var l = lines.length;
        ctx.clearRect(0, 0, cs.width, cs.height);
        for (; i < l; i++) {
            lines[i].render();
        }
        setTimeout(function() {
            render();
        }, 100);
    }

    createLines(lineNum);
    render();
};


/**
 * focusLine()に渡す引数の設定
 */
var cs = document.getElementById('myCanvas');
var conf = {
    cx: cs.width / 2,
    cy: cs.height / 2,
    lineWidth: 30,
    lineNum: 200,
    crMax: 200, // 集中線の円形の半径上限
    crMin: 150, // 集中線の円形の半径下限
    color: 'black'
};

focusLine(cs, conf.cx, conf.cy, conf.lineWidth, conf.lineNum, conf.crMax, conf.crMin, conf.color);
