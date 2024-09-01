;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm
   
        .def alignment_mode
        icl "Kernel-Equates.asm"

; TIP,1,0,width(pixel), height, <size (bpl*height), >size (bpl*height)
headerSize = 9

; 40 bytes per line
width = 40
; Maximum number of lines in a 4k block
blockLines = 102
blockSize = blockLines*width

; Maximum number of lines in a 2k block
smallBlockLines = 51
smallBlockPadding = 8
smallBlock = 2048
smallBlockCount = 8
smallBlockVisibleCount = 6

; Top has 119 lines
topLines = 119
; Bottom has 69 lines
bottomLines = 69

totalLines = topLines+bottomLines       ;188

visibleLines = 119

; Text 
textBlockLines = 38     ; Height of the text scroller in scanlines

p1      = $80
p2      = $82
p3      = $84
p4      = $86
p5      = $88

x1      = $90
x2      = $91

lzss_zp = $e0

loader_chr_end = $2198

sm1          = $4000        ; $4000 bytes
sm2          = $8000        ; $4000 bytes, except the last 1k used for the loader spare
loader_spare = $bc00        ; $400 bytes
empty_block  = $c000        ; $1000 bytes


text_sm = $1e00 ; 4*$60 = $180 bytes

          icl "../msx/LZSS-Player-Globals.asm"
        