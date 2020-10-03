(module
    ;; imports from js
    (import "graphics" "rectLine" (func $rectLine (param i32) (param i32) (param i32) (param i32)))
    (import "graphics" "rectFull" (func $rectFull (param i32) (param i32) (param i32) (param i32)))
    (import "graphics" "showResetText" (func $showResetText (param i32) (param i32)))
    (import "graphics" "color" (func $color (param i32) (param i32) (param i32)))
    (import "graphics" "requestFrame" (func $nextFrame))
    (import "other" "setHighScore" (func $setHighScore (param i32)))
    (import "other" "setScore" (func $setScore (param i32)))
    (import "other" "random" (func $random (result f64)))

    ;; declare 1 page of memory
    (memory 1)

    ;; global vars
    (global $block_num i32 (i32.const 12))
    (global $canvas_size i32 (i32.const 600))
    (global $speed_div i32 (i32.const 30))
    (global $block_length (mut i32) (i32.const 0))
    (global $i32_size i32 (i32.const 4))
    (global $xDir (mut i32) (i32.const 1))
    (global $yDir (mut i32) (i32.const 0))
    (global $foodX (mut i32) (i32.const -1))
    (global $foodY (mut i32) (i32.const -1))
    (global $frame (mut i32) (i32.const -1))
    (global $alive (mut i32) (i32.const 1))
    (global $highScore (mut i32) (i32.const 0))

    ;; initializer function
    (export "init" (func $init))
    (func $init
        global.get $canvas_size
        global.get $block_num
        i32.div_s
        global.set $block_length ;; set block_length to block_num / canvas_size
        call $reset
    )

    ;; draw function
    (export "draw" (func $draw))
    (func $draw (local $var i32) (local $score i32)
        global.get $frame
        global.get $speed_div
        i32.eq
        if
            global.get $alive
            i32.const 1
            i32.eq
            if ;; if alive continue game
                call $background
                call $moveSnake
                call $checkAliveBody
                call $checkAliveWalls
                call $checkEat
                global.get $alive
                i32.const 0
                i32.ne
                if ;; only draw if alive, else draw lose screen
                    call $drawSnake
                    call $drawFood
                else
                    call $loseBackground
                end
            end
            i32.const 0
            global.set $frame ;; set frame to 0
        end
        global.get $alive
        i32.const 0
        i32.eq
        if ;; if not alive draw lose screen
            call $loseBackground
        end
        call $getSnakeLast
        i32.const 2
        i32.div_s
        local.tee $score ;; set score to getSnakeLast() / 2, push score
        call $setScore ;; update score
        local.get $score
        global.get $highScore
        i32.gt_s
        if ;; if (score > highScore)
            local.get $score
            global.set $highScore ;; set highScore to score
            global.get $highScore
            call $setHighScore ;; update high score
        end 
        global.get $frame
        i32.const 1
        i32.add
        global.set $frame ;; frame++
        call $nextFrame
    )

    ;; key pressed function
    (export "onKeyPress" (func $keyPress))
    (func $keyPress (param $dir i32)
        local.get $dir
        i32.const 1
        i32.eq
        if
            i32.const -1
            global.set $yDir
            i32.const 0
            global.set $xDir
        end ;; if (key == 1) yDir = -1, xDir = 0
        local.get $dir
        i32.const 3
        i32.eq
        if
            i32.const 1
            global.set $yDir
            i32.const 0
            global.set $xDir
        end ;; if (key == 3) yDir = 1, xDir = 0
        local.get $dir
        i32.const 2
        i32.eq
        if
            i32.const 1
            global.set $xDir
            i32.const 0
            global.set $yDir
        end ;; if (key == 2) yDir = 0, xDir = 1
        local.get $dir
        i32.const 4
        i32.eq
        if
            i32.const -1
            global.set $xDir
            i32.const 0
            global.set $yDir
        end ;; if (key == 4) yDir = 0, xDir = -1
        global.get $alive
        i32.const 0
        i32.eq
        if ;; if (!alive)
            local.get $dir
            i32.const 5
            i32.eq
            if ;; if (key == 5) reset
                call $reset
            end
        end
    )

    ;; other functions

    ;; draw background
    (func $background (local $x i32) (local $y i32) (local $tempX i32) (local $tempY i32)
        i32.const 102
        i32.const 102
        i32.const 102
        call $color ;; set color to gray
        i32.const 0
        i32.const 0
        i32.const 600
        i32.const 600
        call $rectFull ;; fill background
        i32.const 0
        i32.const 0
        i32.const 0
        call $color ;; set color to black
        i32.const 0
        local.set $x ;; set x to 0
        loop $xLoop
            i32.const 0
            local.set $y ;; set y to 0
            loop $yLoop
                global.get $block_length
                local.get $x
                i32.mul
                local.set $tempX ;; set tempX to x * block_length
                global.get $block_length
                local.get $y
                i32.mul
                local.set $tempY ;; set tempY to y * block_length
                local.get $tempX ;; push tempY
                local.get $tempY ;; push tempX
                global.get $block_length;; push block_length
                global.get $block_length ;; push block_length
                call $rectLine ;; draw line with previous x, y, w, h
                i32.const 1
                local.get $y
                i32.add
                local.tee $y ;; y++, push y
                global.get $block_num
                i32.lt_s
                br_if $yLoop ;; if (y < block_num) loop
            end
            i32.const 1
            local.get $x
            i32.add
            local.tee $x ;; x++, push x
            global.get $block_num
            i32.lt_s
            br_if $xLoop ;; if (x < block_num) loop
        end
    )

    ;; draw loss screen
    (func $loseBackground
        i32.const 75
        i32.const 75
        i32.const 75
        call $color ;; set color to dark gray
        i32.const 0
        i32.const 0
        global.get $canvas_size
        global.get $canvas_size
        call $rectFull
        i32.const 0
        i32.const 0
        i32.const 0
        call $color ;; set color to Black
        global.get $canvas_size
        i32.const 2
        i32.div_s
        global.get $canvas_size
        f32.convert_i32_s
        f32.const 0.46
        f32.mul
        i32.trunc_f32_s
        i32.sub
        global.get $canvas_size
        i32.const 2
        i32.div_s
        call $showResetText ;; show reset text at canvas_size/2 - (i32)((f32)(canvas_size) * 0.50), canvas_size/2
    )

    ;; draw each block of snake
    (func $drawSnake (local $i i32) (local $x i32) (local $y i32) (local $tempX i32) (local $tempY i32)
        i32.const 0
        i32.const 0
        i32.const 0
        call $color ;; set color to black
        i32.const 0
        local.set $i ;; set i to 0
        loop $loop
            local.get $i
            global.get $i32_size
            i32.mul
            i32.load
            local.set $x ;; set x to value at memory address i * 4
            local.get $i
            i32.const 1
            i32.add
            global.get $i32_size
            i32.mul
            i32.load
            local.tee $y ;; set y to value at memory address (i + 1) * 4, push y
            i32.const -1
            i32.add 
            global.get $block_length
            i32.mul
            local.set $tempY ;; set tempY to block_length * (y - 1)
            local.get $x
            i32.const -1
            i32.add
            global.get $block_length
            i32.mul
            local.tee $tempX ;; set tempX to block_length * (x - 1), push tempX
            local.get $tempY ;; push tempY
            global.get $block_length ;; push block_length
            global.get $block_length ;; push block_length
            call $rectFull ;; draw line with previous x, y, w, h
            local.get $i
            i32.const 2
            i32.add
            local.tee $i ;; i += 2, push i
            global.get $i32_size
            i32.mul
            i32.load ;; load value at memory address i * 4
            i32.const 0
            i32.ne
            br_if $loop ;; if (*i != 0) loop
        end
    )

    ;; move the snake 1 position
    (func $moveSnake (local $i i32) (local $xAhead i32) (local $yAhead i32)
        call $getSnakeLast
        i32.const 2
        i32.eq
        if ;; if there are only 2 pieces check if head moved to 2nd piece
            call $checkAlive2Pieces
        end
        call $getSnakeLast
        i32.const 0
        i32.ne ;; if last block first don't try to move other blocks
        if
            call $getSnakeLast
            local.set $i
            loop $loop
                local.get $i
                i32.const -2
                i32.add
                global.get $i32_size
                i32.mul
                i32.load
                local.set $xAhead ;; set xAhead to memory at (i - 2) * i32_size
                local.get $i
                i32.const -1
                i32.add
                global.get $i32_size
                i32.mul
                i32.load
                local.set $yAhead ;; set yAhead to memory at (i - 1) * i32_size
                local.get $i
                global.get $i32_size
                i32.mul
                local.get $xAhead
                i32.store ;; store xAhead at i * i32_size
                local.get $i
                i32.const 1
                i32.add
                global.get $i32_size
                i32.mul
                local.get $yAhead
                i32.store ;; store yAhead at (i + 1) * i32_size
                local.get $i
                i32.const -2
                i32.add
                local.tee $i ;; i -= 2, push i
                i32.const 0
                i32.ne
                br_if $loop ;; if (i != 0) loop
            end
        end
        i32.const 0
        i32.const 0
        i32.load
        global.get $xDir
        i32.add
        i32.store ;; add xDir to value at memory address 0 (snake head x)
        global.get $i32_size
        global.get $i32_size
        i32.load
        global.get $yDir
        i32.add
        i32.store ;; add yDir to value at memory address 1 * i32_size (snake head y)
    )

    ;; get the (last memory address / i32_size) making up the snake
    (func $getSnakeLast (result i32) (local $i i32)
        i32.const 0
        local.set $i ;; set i to 0
        loop $loop
            local.get $i
            i32.const 2
            i32.add
            local.tee $i ;; i += 2, push i
            global.get $i32_size
            i32.mul
            i32.load
            i32.const 0
            i32.ne
            br_if $loop ;; if (*(i) != 0) loop
        end
        local.get $i
        i32.const -2
        i32.add ;; return i - 2
    )

    ;; check if the snake head is in its body
    (func $checkAliveBody (local $i i32) (local $headX i32) (local $headY i32) (local $break i32)
        i32.const 0
        i32.load
        local.set $headX ;; set headX to value at memory address 0
        global.get $i32_size
        i32.load
        local.set $headY ;; set headY to value at memory address 1 * i32_size
        call $getSnakeLast
        i32.const 0
        i32.ne
        if ;; if last snake block isn't head check it with body parts 
            call $getSnakeLast
            local.set $i ;; set i to last snake block
            i32.const 0
            local.set $break ;; set break to 0
            loop $loop
                local.get $i
                global.get $i32_size
                i32.mul
                i32.load ;; push value at memory address i * i32_size
                local.get $headX
                i32.eq
                if ;; if (headX == *i)
                    local.get $i
                    i32.const 1
                    i32.add
                    global.get $i32_size
                    i32.mul
                    i32.load ;; push value at memory address (i + 1) * i32_size
                    local.get $headY
                    i32.eq
                    if ;; if (headY == *(i + 1))
                        i32.const 0
                        global.set $alive ;; alive = 0
                        i32.const 1
                        local.set $break ;; break = 1
                    end
                end
                local.get $break
                i32.const 0
                i32.eq
                if ;; if (!break)
                    local.get $i
                    i32.const -2
                    i32.add
                    local.tee $i ;; i -= 2, push i
                    i32.const 0
                    i32.ne
                    br_if $loop ;; if (i != 0) loop
                end
            end
        end
    )

    (func $checkAlive2Pieces
        i32.const 2
        global.get $i32_size
        i32.mul
        i32.load ;; push value at memory address 2 * i32_size (2nd snake piece x)
        i32.const 0
        i32.load ;; push value at memory address 0 (snake head x)
        global.get $xDir
        i32.add
        i32.eq
        if ;; if (2nd snake piece x == snake head x + xDir)
            i32.const 3
            global.get $i32_size
            i32.mul
            i32.load ;; push value at memory address 3 * i32_size (2nd snake piece y)
            global.get $i32_size
            i32.load ;; push value at memory address 1 * i32_size (snake head y)
            global.get $yDir
            i32.add
            i32.eq
            if ;; if (2nd snake piece y == snake head y + yDir)
                i32.const 0
                global.set $alive ;; set alive to 0
            end
        end
    )

    (func $checkAliveWalls (local $headX i32) (local $headY i32)
        i32.const 0
        i32.load
        local.tee $headX ;; set headX to value at memory address 0, push headX
        i32.const 1
        i32.lt_s
        if ;; if headX is less than 1
            i32.const 0
            global.set $alive ;; set alive to 0
        end
        global.get $i32_size
        i32.load
        local.tee $headY ;; set headY to value at memory address 1 * i32_size, push headY
        i32.const 1
        i32.lt_s
        if ;; if headY is less than 1
            i32.const 0
            global.set $alive ;; set alive to 0
        end
        local.get $headX
        global.get $block_num
        i32.gt_s
        if ;; if headX is greater than block_num
            i32.const 0
            global.set $alive ;; set alive to 0
        end
        local.get $headY
        global.get $block_num
        i32.gt_s
        if ;; if headY is greater than block_num
            i32.const 0
            global.set $alive ;; set alive to 0
        end
    )

    (func $checkEat (local $addI i32)
        i32.const 0
        i32.load ;; push value at memory address 0 (headX)
        global.get $foodX
        i32.const 1
        i32.add
        i32.eq
        if ;; if (headX == foodX + 1) (+1 to adjust for different position storage)
            global.get $i32_size
            i32.load ;; push value at memory address 1 * i32_size (headY)
            global.get $foodY
            i32.const 1
            i32.add
            i32.eq
            if ;; if (headY == foodY + 1)
                call $getSnakeLast
                i32.const 2
                i32.add
                local.tee $addI ;; set addI to last snake index + 2, push addI
                global.get $i32_size
                i32.mul
                i32.const -1
                i32.store ;; store -1 at memory address addI * i32_size
                local.get $addI
                i32.const 1
                i32.add
                global.get $i32_size
                i32.mul
                i32.const -1
                i32.store ;; store -1 at memory address (addI + 1) * i32_size
                call $resetFood 
            end
        end
    )

    (func $resetFood (local $i i32) (local $headX i32) (local $headY i32)
        i32.const 0
        global.get $block_num
        i32.const -1
        i32.add
        call $randomRange ;; get number between 0 and block_num - 1
        global.set $foodX
        i32.const 0
        global.get $block_num
        i32.const -1
        i32.add
        call $randomRange ;; get number between 0 and block_num - 1
        global.set $foodY
        call $getSnakeLast
        local.tee $i ;; set i to last snake block, push i
        i32.const 0
        i32.ne
        if ;; if (i != 0)
            loop $loop
                local.get $i
                global.get $i32_size
                i32.mul
                i32.load
                global.get $foodX
                i32.const 1
                i32.add
                i32.eq
                if ;; if (*(i * i32_size) == foodX + 1)
                    local.get $i
                    i32.const 1
                    i32.add
                    global.get $i32_size
                    i32.mul
                    i32.load
                    global.get $foodY
                    i32.const 1
                    i32.add
                    i32.eq
                    if ;; if (*((i + 1) * i32_size) == foodY + 1)
                        call $resetFood
                    end
                end
                local.get $i
                i32.const -2
                i32.add
                local.tee $i ;; i -= 2, push i
                i32.const 0
                i32.ne
                br_if  $loop;; if (i != 0) loop                
            end
        end
    )

    (func $drawFood
        i32.const 220
        i32.const 30
        i32.const 30
        call $color ;; set color to red
        global.get $foodX
        global.get $block_length
        i32.mul ;; push foodX * block_length
        global.get $foodY
        global.get $block_length
        i32.mul ;; push foodY * block_length
        global.get $block_length
        global.get $block_length
        call $rectFull ;; call rectFull with previous x, y, w, h
    )

    (func $reset (local $i i32)
        i32.const 0
        i32.const 4
        i32.store ;; store 4 at memory address 0
        global.get $i32_size
        i32.const 4
        i32.store ;; store 4 at memory address 1 * i32_size
        call $getSnakeLast
        local.tee $i ;; set i to last snake block index, push i
        i32.const 0
        i32.ne
        if ;; if(i != 0)
            loop $loop
                local.get $i
                global.get $i32_size
                i32.mul
                i32.const 0
                i32.store ;; store 0 at memory address i * i32_size
                local.get $i
                i32.const 1
                i32.add
                global.get $i32_size
                i32.mul
                i32.const 0
                i32.store ;; store 0 at memory address (i + 1) * i32_size
                local.get $i
                i32.const -2
                i32.add
                local.tee $i ;; i -= 2, push i
                i32.const 0
                i32.ne
                br_if $loop ;; if (i != 0) loop
            end
        end
        i32.const 1
        global.set $alive ;; set alive to 1
        global.get $speed_div
        global.set $frame ;; set frame to speed_div
        i32.const 1
        global.set $xDir ;; set xDir to 1
        i32.const 0
        global.set $yDir ;; set yDir to 0
        call $resetFood
    )

    (func $randomRange (param $min i32) (param $max i32) (result i32)
        call $random
        local.get $max
        i32.const 1
        i32.add
        local.get $min
        i32.sub
        f64.convert_i32_s
        f64.mul
        i32.trunc_f64_s
        local.get $min
        i32.add ;;  return (i32)(random() * (f64)(max + 1 - min)) + 1
    )
)