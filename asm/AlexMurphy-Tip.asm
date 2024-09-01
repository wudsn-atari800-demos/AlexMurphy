;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Tip scroller module.
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm

       .proc tip

        .local small_blocks_hi_template
        .rept smallBlockCount
        .byte >[smallBlock*#]
        .endr
        .byte >empty_block
        .byte >empty_block
        .byte >empty_block
        .byte >empty_block
        .byte >empty_block
        .byte >empty_block
        .endl

tip_vbi_active    .byte 0
tip_page        .byte 0         ;$00,$01

                .local small_blocks_hi
:smallBlockVisibleCount .byte $00
                .endl

scroll_active   .byte $00       ; $00 (inactive), $01 (active)
scroll_fine     .byte $00       ; $00 or $01
scroll_line     .byte $00       ; $00,$02,$04,$06...smallBlockLines-1,$01,$03,$05,...smallBlockLines-2
scroll_block    .byte $00
scroll_sm_hi    .byte $00

last_scroll_line .byte $ff      ; 0...smallBlockLines-1, negative indicates not set
last_vbl_line    .byte $ff      ; 0...smallBlockLines-1+2, negative indicates not set

jdl_active      .byte $00       ; $00 (inactive), $01 (active)
jdl_move_active .byte $00       ; $00 (inactive), $01 (active)
jdl_move_count  .byte $20       ; $00..$ff
jdl_fine        .byte $00       ; $00 or $01
jdl_position    .byte $00       ; 0...smallBlockLines-1 step 2, like scroll_line
last_jdl_line   .byte $ff       ; 0...smallBlockLines-1+2, negative indicates not set, relative to jump_dl_base

console_active  .byte $00

;----------------------------------------------------------------------

        .proc init
        jsr init_empty_block
        jsr init_palette
        jsr init_dl
        jsr setup_dl
        mva #0 jdl_active
        jsr tip.set_jump_dl_lines

        rts

        .proc init_empty_block
        lda #0
        tax
        ldy #>smallBlock
loop    sta empty_block,x
;        eor #$ff       ; Debugging pattern
        inx
        bne loop
        inc loop+2
        dey
        bne loop
        rts
        .endp

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

;----------------------------------------------------------------------

        .proc init_dl
        ldx #0
loop    mva dl_template,x dl,x
        inx
        bne loop
loop1   mva dl_template+$100,x dl+$100,x
        inx
        cpx #<[.len dl_template]
        bne loop1
        
        ldx #smallBlockVisibleCount-1
        lda #>empty_block
loop2   sta small_blocks_hi,x
        dex
        bpl loop2
        rts
        .endp

        .endp           ; End of init

;----------------------------------------------------------------------

        .proc vbi
    
        jsr restore_dl

        jsr read_console

        jsr next_scroll_line_and_block
        jsr flip_sm
        jsr setup_dl
        mwa sdlstl dlptr
        
        jsr animate_jump_dl
        jsr setup_jump_dl
        jsr set_jump_dl_lines

        ldx jdl_fine
        mva top_dl,x text_dl.extra_blank_top
        mva bottom_dl,x text_dl.extra_blank_bottom
        mva top_sync,x dli.middle.extra_skip_top
        mva bottom_sync,x dli.middle.extra_skip_bottom

;##TRACE "scroll_fine=$%02X, dli.middle.scroll_fine_delay=$%02X, jdl_active=$%02X, scroll_temp==$%02X " db(main.tip.scroll_fine) db(main.tip.dli.middle.scroll_fine_delay) db(main.tip.jdl_active) db(main.tip.scroll_temp)


       rts

top_dl          .byte $00,$10
bottom_dl       .byte $10,$00
top_sync        .byte $ad,$8d
bottom_sync     .byte $8d,$ad

        .endp

;----------------------------------------------------------------------

        .proc dli

        .var .byte top_lines = 0        ; 0..visibleLines
        .var .byte jdl_active = 0       ; $00 or $01
        .var .byte bottom_lines = 0     ; 0..visibleLines

        pha
        txa
        pha
        tya
        pha

        .proc top
        mva #$00 colbk
luma_mode = *+1
        mva #$41 luma_line
        ldx top_lines
loop    sta wsync
        mva #$c1 prior          ; Graphics 11, chroma
        sta wsync
luma_line = *+1
        mva #$00 prior          ; Graphics 9/10 , luma
        eor #$c0
        sta luma_line
        dex
        bne loop
        .endp                   ; End of top

        .proc middle
        lda jdl_active
        beq no_display
        mva #$23 dmactl

        stx prior               ; <X>==0
        stx colpf2              ; <X>==0

scroll_fine_delay = *+1
        lda #$00
        sta wsync
        bne no_skip
        sta wsync
no_skip

extra_skip_top
        lda wsync
        nop

        jsr text.kernel

        sta wsync
        lda #$22
        sta dmactl
        lda #$00
        sta colpf1
        sta colpf2

        sta wsync
        ldx color1
        ldy color2
        stx colpf1       ; Restore graphics 10 palette
        sty colpf2       ; Restore graphics 10 palette

extra_skip_bottom
        sta wsync

no_display
        .endp                   ; End of middle

        .proc bottom
        lda top.luma_line
extra_eor = *+1
        eor #$00
        sta bottom.luma_line

        ldx bottom_lines
        beq no_display
        sta wsync
        lda middle.scroll_fine_delay
        bne skip

loop    sta wsync
        mva #$c1 prior
skip
        sta wsync
luma_line = *+1
        mva #$00 prior
        eor #$c0
        sta luma_line
        dex
        bne loop
no_display
        .endp                   ; End of bottom

        pla
        tay
        pla
        tax
        pla
        rti
        
        .endp
        
;----------------------------------------------------------------------

        .proc read_console
        .var .byte last_consol
        lda console_active
        bne is_active
        rts

is_active
        lda consol
        cmp last_consol
        beq no_consol
        sta last_consol

        and #4
        bne no_option
        lda jdl_move_active
        eor #1
        sta jdl_move_active

no_option
        lda last_consol
        and #2
        bne no_select
        lda jdl_active
        eor #1
        sta jdl_active

no_select
        lda last_consol
        and #1
        bne no_start
        lda scroll_active
        eor #1
        sta scroll_active
no_start
no_consol

;        lda trig0
;        bne no_trig0
;        lda jdl_active
;        eor #1
;        sta jdl_active
;no_trig0
        rts
        .endp

;----------------------------------------------------------------------

        .proc restore_dl
        ldy last_scroll_line
        bmi no_last_scroll_line
        mva dl_template+0,y dl+0,y
        mva dl_template+1,y dl+1,y
        mva dl_template+2,y dl+2,y
        mva dl_template+3,y dl+3,y
no_last_scroll_line

        ldy last_vbl_line               ; Where was the $41,a(dl) previously?
        bmi no_last_vbl_line
        mva dl_template.wait_vbl+0,y dl.wait_vbl+0,y
        mva dl_template.wait_vbl+1,y dl.wait_vbl+1,y
        mva dl_template.wait_vbl+2,y dl.wait_vbl+2,y
no_last_vbl_line

        ldy last_jdl_line               ; Where was the $01,a(other_dl) previously?
        bmi no_last_jdl_line
        mva dl_template.jump_dl_base+0,y dl.jump_dl_base+0,y
        mva dl_template.jump_dl_base+1,y dl.jump_dl_base+1,y
        mva dl_template.jump_dl_base+2,y dl.jump_dl_base+2,y
no_last_jdl_line

        rts
        .endp

;----------------------------------------------------------------------

        .proc flip_sm
        ldx #>sm1
        lda tip_page
        beq skip
        ldx #>sm2
skip    stx scroll_sm_hi

        ldx #$41
        lda scroll_block
        eor #2
        eor scroll_line
        lsr
        and #1
        eor tip_page
        beq skip2
        ldx #$81
skip2   stx dli.top.luma_mode

        lda tip_page
        eor #$01
        sta tip_page
        rts
        .endp

;----------------------------------------------------------------------

        .proc setup_dl
        
        ldy #0
        jsr get_block_lms
        sta lms1_hi             ; Is at dl.lms1+2 at start
        jsr get_block_lms
        sta dl.lms2+2
        sta dl_template.lms2+2  ; The template values are used in setup_jump_dl
        jsr get_block_lms
        sta dl.lms3+2
        sta dl_template.lms3+2
        jsr get_block_lms
        sta dl.lms4+2
        sta dl_template.lms4+2
        jsr get_block_lms
        sta dl.lms5+2
        jsr get_block_lms
        sta dl.lms6+2

        ldy scroll_line
        sty last_scroll_line

        sty sdlstl
        lda scroll_fine
        seq                     ; $00 = one empty scanline
        lda #$10                ; $10 = two empty scanlines
        ora #$80                ; Enable DLI
        sta dl+0,y
        lda #dl_template.ldc
        sta dl+1,y
        lda llo,y
        sta dl+2,y
        lda lhi,y
        clc
lms1_hi = *+1
        adc #$00
        sta dl+3,y

        
        ldy scroll_line
        cpy #18+1
        bcc no_lms
        iny
        iny
no_lms
        sty last_vbl_line
        mva #$41   dl.wait_vbl+0,y
        mva sdlstl dl.wait_vbl+1,y
        mva sdlsth dl.wait_vbl+2,y
        rts

        .proc get_block_lms
        lda small_blocks_hi,y
        iny
        cmp #>empty_block
        beq is_empty
        clc
        adc scroll_sm_hi
is_empty
        rts
        .endp


        .local llo
:smallBlockLines        .byte <[#*width]
        .endl
        .local lhi
:smallBlockLines        .byte >[#*width]
        .endl

        .endp

;----------------------------------------------------------------------

        .proc next_scroll_line_and_block
        lda scroll_active
        bne is_active
        rts
is_active
        lda rtclok+2
        and #1
        bne is_stepping
        rts
is_stepping

unconditionally
        lda scroll_fine
        eor #$01
        sta scroll_fine
        sta dli.middle.scroll_fine_delay

        beq no_block

        lda scroll_line
        clc
        adc #2
        sta scroll_line
        cmp #smallBlockLines
        bcc no_block
        sbc #smallBlockLines
        sta scroll_line
        ldy scroll_block


        .rept smallBlockVisibleCount-1
        mva small_blocks_hi+#+1 small_blocks_hi+#
        .endr
        mva small_blocks_hi_template,y small_blocks_hi+smallBlockVisibleCount-1

        iny
        cpy #.len small_blocks_hi_template
        sne
        ldy #0
        sty scroll_block

no_block
        rts

        .endp

;----------------------------------------------------------------------

        .proc set_jump_dl_lines         ; IN: jdl_active, jdl_position
        lda jdl_active
        sta dli.jdl_active              ; Copy, so changes in sequencer do not cause distortion
        cmp #$00
        bne is_active
        mva #visibleLines dli.top_lines
        mva #0 dli.bottom_lines
        rts
is_active
        lda jdl_position
        lsr
        clc
        adc #26
        sta dli.top_lines
        lda #visibleLines
        sec
        sbc dli.top_lines
        sbc #[textBlockLines/2]-1
        sta dli.bottom_lines
        rts
        .endp

;----------------------------------------------------------------------

        .proc animate_jump_dl

        lda jdl_move_count
        clc
        adc #110
        and #127
;        cmp #64
;        scc
;        eor #127
        tax
        lda wave,x
        pha
        and #$fe
        sta jdl_position
        pla
        and #$01
        sta jdl_fine

        lda jdl_move_active
        seq
        inc jdl_move_count
        rts
        
wave
;       .byte cos(32,31,128)
;	.byte 32, 34, 35, 37, 38, 40, 41, 43, 44, 46, 47, 48, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 61, 62, 62, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 62, 62, 61, 61, 60, 60, 59, 58, 57, 56, 55, 54, 53, 52, 50, 49, 48, 46, 45, 43, 42, 40, 39, 37, 36, 34, 33, 31, 30, 28, 27, 25, 24, 22, 21, 19, 18, 16, 15, 14, 12, 11, 10, 9, 8, 7, 6, 5, 4, 4, 3, 3, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 18, 20, 21, 23,24,26,27,29,30,32
	.byte 32,34,35,37,38,40,41,43,44,46,47,48,50,51,52,53,54,55,56,57,58,59,60,61,61,62,62,63,63,63,63,63,63,63,63,63,63,62,62,61,61,60,60,59,58,57,56,55,54,53,52,50,49,48,46,45,43,42,40,39,37,36,34,33,31,30,28,27,25,24,22,21,19,18,16,15,14,12,11,10,9,8,7,6,5,4,4,3,3,2,2,1,1,1,1,1,1,1,1,1,1,2,2,3,3,4,5,6,7,8,9,10,11,12,13,14,16,17,18,20,21,23,24,26,27,29,30,32

        .endp

;----------------------------------------------------------------------

        .proc setup_jump_dl             ;IN: jdl_actives, jdl_position, scroll_line, OUT: last_jdl_line
        .var .byte jdl_line

        lda jdl_active
        sne
        rts

        mwa #dl.jump_dl_base p1
        lda scroll_line
        clc
        adc jdl_position
        sta jdl_line

        tax
        lda lookup,x
        sta last_jdl_line       ; Remeber relative offset

        clc
        adc p1
        sta p2
        lda p1+1
        adc #0
        sta p2+1                ; p2 = jump_dl_base+lookup[jdl_line]
        

        ldy #0
        lda #$01
        sta (p2),y
        iny
        lda scroll_fine         ; Skip first $00 ANTIC command?
        clc
        adc #<text_dl
        sta (p2),y
        iny
        lda #>text_dl
        adc #0
        sta (p2),y

        lda #0
        ldx #$00
        ldy scroll_fine
        bne not_zero
        lda #1
        ldx #$c0
not_zero
        stx dli.bottom.extra_eor

        ldx dl_template.lms2+2
        clc
        adc jdl_line            ; Compute where the SM must be reloaded to be continued
        adc #textBlockLines-1

;##TRACE "scroll_fine=$%02X, dli.middle.scroll_fine_delay=$%02X, jdl_active=$%02X, scroll_temp==$%02X " db(main.tip.scroll_fine) db(main.tip.dli.middle.scroll_fine_delay) db(main.tip.jdl_active) db(main.tip.scroll_temp)


        cmp #smallBlockLines
        bcc no_overflow
        sbc #smallBlockLines
        ldx dl_template.lms3+2
        cmp #smallBlockLines
        bcc no_overflow
        sbc #smallBlockLines
        ldx dl_template.lms4+2
        
no_overflow
        tay
        cpy #.len setup_dl.llo
        bcs stop
        clc
        lda setup_dl.llo,y
        sta text_dl.reload_lms+1
        txa
        adc setup_dl.lhi,y
        sta text_dl.reload_lms+2
        cmp #<sm1
        bcc stop

        lda jdl_line
        clc
        adc #textBlockLines+1
        sec
        sbc scroll_fine
        tax
        lda lookup,x

        clc
        adc p1
        sta p2
        lda p1+1
        adc #0
        sta p2+1

        mwa p2 text_dl.jump_address

        rts
        .endp

stop    .byte 2

        .local lookup
        block_size=51+2
        ?offset = 0*block_size
        .byte ?offset+0,?offset+3,?offset+4,?offset+5,?offset+6,?offset+7,?offset+8,?offset+9,?offset+10,?offset+11,?offset+12,?offset+13,?offset+14,?offset+15,?offset+16,?offset+17,?offset+18,?offset+19,?offset+20,?offset+21,?offset+22,?offset+23,?offset+24,?offset+25,?offset+26,?offset+27,?offset+28,?offset+29,?offset+30,?offset+31,?offset+32,?offset+33,?offset+34,?offset+35,?offset+36,?offset+37,?offset+38,?offset+39,?offset+40,?offset+41,?offset+42,?offset+43,?offset+44,?offset+45,?offset+46,?offset+47,?offset+48,?offset+49,?offset+50,?offset+51,?offset+52
        ?offset = 1*block_size
        .byte ?offset+0,?offset+3,?offset+4,?offset+5,?offset+6,?offset+7,?offset+8,?offset+9,?offset+10,?offset+11,?offset+12,?offset+13,?offset+14,?offset+15,?offset+16,?offset+17,?offset+18,?offset+19,?offset+20,?offset+21,?offset+22,?offset+23,?offset+24,?offset+25,?offset+26,?offset+27,?offset+28,?offset+29,?offset+30,?offset+31,?offset+32,?offset+33,?offset+34,?offset+35,?offset+36,?offset+37,?offset+38,?offset+39,?offset+40,?offset+41,?offset+42,?offset+43,?offset+44,?offset+45,?offset+46,?offset+47,?offset+48,?offset+49,?offset+50,?offset+51,?offset+52
        ?offset = 2*block_size
        .byte ?offset+0,?offset+3,?offset+4,?offset+5,?offset+6,?offset+7,?offset+8,?offset+9,?offset+10,?offset+11,?offset+12,?offset+13,?offset+14,?offset+15,?offset+16,?offset+17,?offset+18,?offset+19,?offset+20,?offset+21,?offset+22,?offset+23,?offset+24,?offset+25,?offset+26,?offset+27,?offset+28,?offset+29,?offset+30,?offset+31,?offset+32,?offset+33,?offset+34,?offset+35,?offset+36,?offset+37,?offset+38,?offset+39,?offset+40,?offset+41,?offset+42,?offset+43,?offset+44,?offset+45,?offset+46,?offset+47,?offset+48,?offset+49,?offset+50,?offset+51,?offset+52
        .endl

        m_info lookup
;----------------------------------------------------------------------

        .endp                   ; End of tip
