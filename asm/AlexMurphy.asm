;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;	(r) 2024-08-19 Use sinus for scroll y-position, ensure 5 seconds loader screen,
;                      shifted star replaces comma in texts, loder and initial scroll
;                      position vertically centrers, pokey bars 1+2 swapped.
;
;       https://www.wudsn.com/productions/atari800/alexmurphy/alexmurphy.zip
;
;       @com.wudsn.ide.lng.outputfileextension=.xex
;       @com.wudsn.ide.lng.outputfoldermode=SOURCE_FOLDER

        icl "AlexMurphy-Globals.asm"

        org lzss_zp
        
        icl "../msx/LZSS-Player-Zeropage.asm"
        
        org $400        ; Memory segmment, LZSS Player Data, $900 bytes

        icl "../msx/LZSS-Player-Data.asm"

        opt h-
        ins "AlexMurphy-Loader.xex"

        opt h+

;----------------------------------------------------------------------


	org $2000     ; Code segment, Main part

        .proc main

initial_wait		; Ensure at least 5 seconds have passed since the loader screen was shown
        lda rtclok+1
        beq initial_wait

        jsr fade_down
        jsr init_os

        mva #0 rtclok+2
        sta rtclok+1

        jsr tip.init
        jsr tip.vbi
        jsr tip.next_scroll_line_and_block.unconditionally

        jsr text.init
        jsr song.init

        .if 1 = 0       ; Debugging
        .var .word scroll_cnt = 321
init_scroll
        jsr tip.next_scroll_line_and_block.unconditionally
        sbw scroll_cnt #1
        lda scroll_cnt
        ora scroll_cnt+1
        bne init_scroll
        .endif

        lda #1
        jsr wait
        mva #$22 sdmctl
        mwa #dl sdlstl
        mva #1 tip.tip_vbi_active

        jmp sequencer

;----------------------------------------------------------------------

        .proc fade_down
        ldx #16
loop    lda color1
        beq zero
        dec color1
zero    lda #2
        jsr wait
        dex
        bne loop
        rts
        .endp
        

;----------------------------------------------------------------------
; Wait for next frame
;----------------------------------------------------------------------

        .proc wait
        clc
        adc rtclok+2
delay   cmp rtclok+2
        bne delay
        rts
        .endp

;----------------------------------------------------------------------

        .proc nmi

        bit nmist
        sta nmist
        bpl vbi

        .proc dli
        jmp (vdslst)
        .endp

        .proc vbi
        pha
        txa
        pha
        tya
        pha

        lda tip.tip_vbi_active
        beq skip_1
        jsr tip.vbi
skip_1
;       Copy shadow registers
        mwa sdlstl dlptr
        mva sdmctl dmactl
        mva gprior prior
:9      mva pcolor0+# colpm0+#

        lda tip.tip_vbi_active
        beq skip_2
        mwa #tip.dli vdslst
        mva #$c0 nmien
skip_2

        inc rtclok+2
        sne
        inc rtclok+1

        jsr text.vbi
        jsr song.play

        pla
        tay
        pla
        tax
        pla
        rti
        .endp

        .endp

;----------------------------------------------------------------------
        
        icl "AlexMurphy-Sequencer.asm"
        icl "AlexMurphy-Sequencer-Operations.asm"

;----------------------------------------------------------------------
  
        icl "AlexMurphy-Tip.asm"

;----------------------------------------------------------------------

        .endp                   ; End of main

        m_info main


;----------------------------------------------------------------------

        icl "AlexMurphy-Text.asm"
        m_info text

        icl "AlexMurphy-Text-Rasters.asm"
        m_info text_rasters

;----------------------------------------------------------------------

        icl "AlexMurphy-Song.asm"
        icl "../msx/LZSS-Player-Main.asm"

;----------------------------------------------------------------------

        .proc init_os
        sei
        lda #0
        sta irqen
        sta nmien
sync    lda vcount
        bne sync
        sta dmactl
        sta sdmctl

        .proc clear_loader_spare
        tax
        ldy #4
loop
loader_spare_ptr = *+1
        sta loader_spare,x
        inx
        bne loop
        inc loader_spare_ptr+1
        dey
        bne loop
        .endp

        mva #$fe portb
        mwa #main.nmi $fffa
        mva #$40 nmien
        sta nmist
        rts
        .endp

;----------------------------------------------------------------------

	.local dl_template // Total 238 scanlines
	dc = $0f
	ldc = $40+dc
	
        .byte $80
lms1	.byte ldc, a(sm1+smallBlock*0)
:50	.byte dc

jump_dl_base = *

lms2    .byte ldc, a(sm1+smallBlock*1)
:50     .byte dc

lms3    .byte ldc, a(sm1+smallBlock*2)
:50     .byte dc

lms4    .byte ldc, a(sm1+smallBlock*3)
:50     .byte dc

lms5    .byte ldc, a(sm1+smallBlock*4)
:32     .byte dc
wait_vbl
:18     .byte dc

lms6    .byte ldc, a(sm1+smallBlock*5)
:32     .byte dc

	.byte $41,a(dl)
	.endl


        .if *>sm1
        .error "Out of memory at", *
        .endif
        m_align sm1

        org sm1 ; Data segment, SM1 & SM2
        ins "../gfx/RoboCop-160x188-Blocks.raw",+0,$7c00 ;TODO ,$8000-$400      ;leave $bc00-$bff?
        
   
        org $fc00 ; Memory segment TIP DL
        .local dl
        lms2 = dl+[dl_template.lms2-dl_template]
        lms3 = dl+[dl_template.lms3-dl_template]
        lms4 = dl+[dl_template.lms4-dl_template]
        lms5 = dl+[dl_template.lms5-dl_template]
        lms6 = dl+[dl_template.lms6-dl_template]
        wait_vbl = dl+[dl_template.wait_vbl-dl_template]
        jump_dl_base = dl+[dl_template.jump_dl_base-dl_template]
        .ds $200
        .endl

        m_assert_same_1k dl

        org $fe00

        icl "AlexMurphy-Text-Data.asm"
        m_info text_data

	run main