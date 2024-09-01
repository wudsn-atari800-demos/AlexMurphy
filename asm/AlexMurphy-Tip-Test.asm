; Picture height 187 lines
; TIP,1,0,width(pixel), height, <size (bpl*height), >size (bpl*height)
headerSize = 9

; 40 bytes per line
width = 40
; Maximum number of lines in a 4k block
blockLines = 102
blockSize = blockLines*width

; Top has 119 lines
topLines = 119
; Bottom has 69 lines
bottomLines = 69

totalLines = topLines+bottomLines

visibleLines = 119

        .def alignment_mode
        icl "Kernel-Equates.asm"

	org $2000

start
	mwa #dl 560
	mva #$80 623
	jsr init_palette
	jmp *
	
;----------------------------------------------------------------------
        .proc init_palette
        ldx #.len gr10_colors-1
loop    lda gr10_colors,x
        sta pcolor0,x
        dex
        bpl loop
        rts

        .local gr10_colors
        .byte $00,$02,$04,$06,$08,$0a,$0c,$0e,$00
        .endl
        .endp
	
	.local dl // Total 240 scanline
	dc = $0f
	.byte $40+dc,a(gr10)
:101	.byte dc,$00
;        .byte $40+dc,a(gr10+$1000)
;:101    .byte dc
	.byte $41,a(dl)
	.endl


        .macro ins_tip

        offset = :1*topLines*width
        ins "../gfx/Robocop-160x188-Top.tip",headerSize+offset,blockSize
        .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
        .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff       ; 4k boundary padding
        ins "../gfx/Robocop-160x188-Top.tip",headerSize+offset+blockSize,(topLines-blockLines)*width
        ins "../gfx/Robocop-160x188-Bottom.tip",headerSize+offset,bottomLines*width

        .endm
        
        org $6000

        .local gr9
        ins_tip 0
        .endl
        m_info gr9

        org $8000

        .local gr10
        ins_tip 1
        .endl
        m_info gr10

        org $a000
        .local gr11
;        ins_tip 2
        .endl
        m_info gr11

	run start