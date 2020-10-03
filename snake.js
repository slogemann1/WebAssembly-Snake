var canvas
var canvasContext
var scoreElement
var highScoreElement
var webAssemblyExports
var webAssemblyImports = 
{
    graphics: //Import graphics functions into module
    {
        rectLine: (x, y, w, h) => { canvasContext.strokeRect(x, y, w, h) },
        rectFull: (x, y, w, h) => { canvasContext.fillRect(x, y, w, h) },
        requestFrame: () => { window.requestAnimationFrame(webAssemblyExports.draw) },
        color: (r, g, b) => 
        {
            let rStr = r.toString(16)
            let gStr = g.toString(16)
            let bStr = b.toString(16)
            if(rStr.length == 1) rStr = "0" + rStr
            if(gStr.length == 1) gStr = "0" + gStr
            if(bStr.length == 1) bStr = "0" + bStr
            canvasContext.fillStyle = "#" + rStr + gStr + bStr
            canvasContext.strokeStyle = canvasContext.fillStyle
        },
        showResetText: (x, y) => { canvasContext.font = "45px Arial"; canvasContext.fillText("You Lost! Press R to restart", x, y) }
    },
    other: //Import general functions into module
    {
        random: () => { return Math.random() },
        setScore: (score) => { scoreElement.innerHTML = "Current Score: " + score },
        setHighScore: (highScore) => { highScoreElement.innerHTML = "High Score: " + highScore }
    }
}

main()
function main()
{
    canvas = document.getElementById("canvas")
    canvasContext = canvas.getContext("2d")
    scoreElement = document.getElementById("score")
    highScoreElement = document.getElementById("highScore")
    setupWebAssembly()
}

function setupWebAssembly()
{
    WebAssembly.instantiateStreaming(fetch("snake.wasm"), webAssemblyImports).then((arg) =>
        {
            webAssemblyExports = arg.instance.exports
            webAssemblyExports.init() //Initialize variables in module
            window.requestAnimationFrame(webAssemblyExports.draw) //Start draw loop
            document.addEventListener("keydown", (event) => //Send code to module when a key is pressed
                {
                    event.preventDefault() //Prevent up/down arrow keys from moving screen 
                    var code;
                    switch(event.key)
                    {
                        case "ArrowUp":
                        case "w": code = 1; break
                        case "ArrowRight":
                        case "d": code = 2; break
                        case "ArrowDown":
                        case "s": code = 3; break
                        case "ArrowLeft":
                        case "a": code = 4; break
                        case "r": code = 5; break
                        default: code = 0
                    }
                    webAssemblyExports.onKeyPress(code)
                }
            )
        }
    )
}