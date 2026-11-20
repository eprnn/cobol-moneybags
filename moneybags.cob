       >>source format free
identification division.
program-id. moneybags.
data division.
working-storage section.
01 ledger.
   02 acct pic 9(4)v99 comp-3 occurs 2.
01 money-out.
   02 amount-edited pic z,zz9.99 occurs 2.
01 screen-buf.
   02 pixel-row occurs 38.
      03 pixel binary-char unsigned occurs 76.
01 profile-radii pic x(40) value
   "0007101315161717171615131109060403060708".
01 ink.
   02 filler pic x(35) value "00100011111010001110001011111000100".
01 dyed-cloth.
   02 filler pic x(30) value "052094130136172178214220221229".
   02 filler pic x(30) value "022028029035036042072078114157".
01 bolts redefines dyed-cloth.
   02 dye occurs 2.
      03 tint pic 999 occurs 10.
01 upper-ink pic 999.
01 lower-ink pic 999.
01 strip-out pic x(2300).
01 pen binary-long.
01 esc pic x value x"1b".
01 delay-ns binary-long-long value 50000000.
01 frame-no binary-long.
01 bag binary-long.
01 col-no binary-long.
01 row-no binary-long.
01 band-no binary-long.
01 stamp-col binary-long.
01 stamp-row binary-long.
01 shade-no binary-long.
01 from-acct binary-long value 1.
01 coin-x binary-long.
01 coin-y binary-long.
01 coin-width binary-long.
01 beat binary-long.
01 middle-x binary-long.
01 scale-factor comp-2.
01 height-pos comp-2.
01 r0 comp-2.
01 r1 comp-2.
01 radius-now comp-2.
01 slope comp-2.
01 nx comp-2.
01 nz comp-2.
01 normal-table.
   02 sample-point occurs 257.
      03 front-z comp-2.
      03 longitude-deg binary-long.
01 waves.
   02 cosine-value comp-2 occurs 360.
01 sample-no binary-long.
01 angle-deg binary-long.
01 turn-deg binary-long.
01 normal-factor comp-2.
01 light-now comp-2.
01 phase-now comp-2.
procedure division.
main.
    move 700 to acct(1)
    move 300 to acct(2)
    perform varying sample-no from 1 by 1 until sample-no > 257
        compute nx = (sample-no - 129) / 128
        compute front-z(sample-no) = function sqrt(1 - nx * nx)
        compute longitude-deg(sample-no) rounded = 57.29578 * function asin(nx)
    end-perform
    perform varying sample-no from 1 by 1 until sample-no > 360
        compute cosine-value(sample-no) = function cos((sample-no - 1) / 57.29578)
    end-perform
    display esc "[2J" with no advancing
    perform varying frame-no from 0 by 1 until frame-no > 144
        compute beat = function mod(frame-no, 18)
        if beat = 0 and frame-no > 0
            subtract 100 from acct(from-acct)
            add 100 to acct(3 - from-acct)
            evaluate acct(1) when 300 move 2 to from-acct
                             when 700 move 1 to from-acct end-evaluate
        end-if
        if acct(1) + acct(2) not = 1000
            display "OUT OF BALANCE" stop run returning 1
        end-if
        move all x"E9" to screen-buf
        perform varying bag from 1 by 1 until bag > 2
            perform draw-sack
            move acct(bag) to amount-edited(bag)
        end-perform
        if frame-no < 144 perform draw-coin end-if
        display esc "[H" esc "[1;37m" "  NIGHTLY BATCH  //  THE $100 TRANSFER"
        perform paint-screen
        display esc "[0m" "  VAULT A $" amount-edited(1)
            "    VAULT B $" amount-edited(2) "    CONTROL $1,000.00"
        if frame-no < 144 call "CBL_OC_NANOSLEEP" using delay-ns end-if
    end-perform
    display "  BATCH CLOSED. EVERY CENT ACCOUNTED FOR."
    stop run.

draw-sack.
    compute middle-x = 19 + (bag - 1) * 38
    compute scale-factor = 0.70 + acct(bag) / 3000
    compute turn-deg rounded = (3 - 2 * bag) * frame-no * 2.5
    perform varying row-no from 1 by 1 until row-no > 38
        compute height-pos = 1 + (38 - row-no) / (2 * scale-factor)
        compute band-no = function integer(height-pos)
        if band-no < 20
            compute r0 = function numval(profile-radii(2 * band-no - 1:2))
            compute r1 = function numval(profile-radii(2 * band-no + 1:2))
            compute slope = (r1 - r0) / 2
            compute normal-factor = 1 / function sqrt(1 + slope * slope)
            compute radius-now = scale-factor *
                (r0 + (r1 - r0) * (height-pos - band-no))
            compute col-no = middle-x - 17
            perform until col-no > middle-x + 17
                if function abs(col-no - middle-x) < radius-now
                    perform shade-pixel
                end-if
                add 1 to col-no
            end-perform
            if band-no >= 14 and band-no <= 16
                compute col-no = middle-x + (19 - band-no) * scale-factor
                move 179 to pixel(row-no,col-no) pixel(row-no,col-no + 1)
            end-if
        end-if
    end-perform.

shade-pixel.
    compute nx = (col-no - middle-x) / radius-now
    compute sample-no rounded = 129 + 128 * nx
    move front-z(sample-no) to nz
    compute angle-deg = function mod(longitude-deg(sample-no) + turn-deg + 180, 360) - 180
    if height-pos > 19.2 + 0.7 * cosine-value(1 + function mod(5 * angle-deg, 360))
        exit paragraph
    end-if
    compute light-now = (0.72 * nz - 0.45 * nx - 0.45 * slope) * normal-factor
        + 0.13 * cosine-value(1 + function mod(9 * angle-deg, 360))
    compute shade-no = 2 + function max(0, function min(8, 8 * light-now))
    move tint(bag,shade-no) to pixel(row-no,col-no)
    if band-no = 16
        if function mod(col-no + row-no, 3) = 0
            move 130 to pixel(row-no,col-no)
        else move 222 to pixel(row-no,col-no) end-if
    end-if
    compute stamp-row = 13 - band-no
    compute stamp-col = 1 + function integer((angle-deg + 27.5) / 11)
    if stamp-row >= 1 and stamp-row <= 7 and stamp-col >= 1 and stamp-col <= 5
        if ink((stamp-row - 1) * 5 + stamp-col:1) = "1"
            move tint(bag,1) to pixel(row-no,col-no)
        end-if
    end-if.

draw-coin.
    compute phase-now = beat / 18
    if from-acct = 2 compute phase-now = 1 - phase-now end-if
    compute coin-x rounded = 19 + 38 * phase-now
    compute coin-y rounded = 11 - 8 * function sin(3.14159 * phase-now)
    compute coin-width = 1 + 2 * function abs(function cos(beat * 0.55))
    perform varying row-no from 1 by 1 until row-no > 5
        perform varying col-no from 1 by 1 until col-no > 7
            compute nx = (col-no - 4) / coin-width
            if nx * nx + ((row-no - 3) / 2.2) ** 2 <= 1
                if col-no = 4 move 230 to pixel(coin-y + row-no - 3, coin-x)
                else move 220 to pixel(coin-y + row-no - 3, coin-x + col-no - 4)
                end-if
            end-if
        end-perform
    end-perform.

paint-screen.
    perform varying row-no from 1 by 2 until row-no > 38
        move 1 to pen
        perform varying col-no from 1 by 1 until col-no > 76
            if col-no = 1 or upper-ink not = pixel(row-no,col-no)
                or lower-ink not = pixel(row-no + 1,col-no)
                move pixel(row-no,col-no) to upper-ink
                move pixel(row-no + 1,col-no) to lower-ink
                string esc "[38;5;" upper-ink ";48;5;" lower-ink "m"
                    into strip-out pointer pen
                end-string
            end-if
            string "▀" into strip-out pointer pen end-string
        end-perform
        display strip-out(1:pen - 1) esc "[0m"
    end-perform.
