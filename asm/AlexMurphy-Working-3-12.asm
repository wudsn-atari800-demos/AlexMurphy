;
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

tip_page        .byte 0         ;$00,$01

                .local small_blocks_hi
                .ds smallBlockVisibleCount
                .endl

scroll_fine     .byte 0         ; $00 or $01
scroll_line     .byte 0
scroll_block    .byte 0
scroll_sm_hi    .byte 0

last_scroll_line .byte $ff      ;0...smallBlockLines-1, negative indicates not set
last_vbl_line    .byte $ff      ;0...smallBlockLines-1+2, negative indicates not set

jdl_active      .byte $01       ;$00 (inactive) or $01 (active)
last_jdl_line   .byte $ff       ;0...smallBlockLines-1+2, negative indicates not set, relative to jump_dl_base

;----------------------------------------------------------------------

        .proc init_empty_block
        lda #0
        tax
        ldy #$10
loop    sta empty_block,x
        inx
        bne loop
        inc loop+2
        dey
        bne loop
        rts
        .endp

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

        .proc dli

        .var .byte top_lines = 26       ;0..visibleLines
        .var .byte bottom_lines = visibleLines-26
        pha
        txa
        pha

        .proc top
        mva #$00 colbk
luma_mode = *+1
        mva #$40 luma_line
        ldx top_lines
loop    sta wsync
        mva #$c0 prior
        sta wsync
luma_line = *+1
        mva #$40 prior
        eor #$c0
        sta luma_line
        dex
        bne loop
        .endp                   ; End of top

        .proc middle
        ldx jdl_active
        beq no_display
        mva #$00 prior
        sta colpf2
        mva #$23 dmactl

        lda tip_page
        eor scroll_fine
        beq no_skip
        sta wsync
no_skip
        jsr text.kernel

;        mva top.luma_line bottom.luma_line
;        sta prior
no_display
        .endp                   ; End of middle

        sta wsync
        mva #$20 dmactl
        mva color1 colpf1       ; Restore graphics 10 palette
        mva color2 colpf2       ; Restore graphics 10 palette
        sta wsync
        mva #$22 dmactl

        .proc bottom
        mva #$00 colbk
luma_mode = *+1
        mva #$40 luma_line
        ldx bottom_lines
        beq no_display
loop    sta wsync
        mva #$c0 prior
        sta wsync
luma_line = *+1
        mva #$40 prior
        eor #$c0
        sta luma_line
        dex
        bne loop
no_display
        .endp                   ; End of bottom

        pla
        tax
        pla
        rti
        .endp

        .local colors
        .byte 14,12,10,8,6,4,4,4,4,4,4
        .byte 6,8,10,12,14,14,14,14,12,10,8,6
        .byte 4,4,4,4,4,4,6,8,10,12,14
        .endl
        
        m_info colors

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
        
        lda #0
        tax
loop3
        .rept [smallBlock / $100]
        sta empty_block+#*$100,x
        .endr
        inx
        bne loop3

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

        ldx #$40
        lda scroll_block
        eor #2
        eor scroll_line
        lsr
        eor tip_page
        and #1
        beq skip2
        ldx #$80
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
        jsr get_block_lms
        sta dl.lms3+2
        jsr get_block_lms
        sta dl.lms4+2
        jsr get_block_lms
        sta dl.lms5+2
        jsr get_block_lms
        sta dl.lms6+2

        ldy scroll_line
        sty last_scroll_line

        sty sdlstl
        lda scroll_fine
        seq
        lda #$10
        ora #$80
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
        lda scroll_fine
        eor #$01
        sta scroll_fine
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

        .proc setup_jump_dl     ;IN: scroll_line, scroll_line, OUT: last_jdl_line
        mwa #dl.jump_dl_base p1
        ldy scroll_line

        clc             ;p2=p1+y
        tya
        beq is_0        ; First LMS is at 0, next DC is at 2
        adc #2
is_0    sta last_jdl_line ; Remeber relative offset
        adc p1
        sta p2
        lda p1+1
        adc #0
        sta p2+1
        

        ldy #0
        lda (p2),y
;        and #$fe
;        sta (p2),y
;        rts

        lda #$01
        sta (p2),y
        iny
        lda #<text_dl
        clc
        adc scroll_fine
        sta (p2),y
        iny
        mva #>text_dl (p2),y

        mwa dl.lms2+1 text_dl.reload_lms+1
        mwa #dl.wait_vbl text_dl.jump_address

;        adw p2 #3
        mwa #dl.lms4 p2
        
        mwa p2 text_dl.jump_address
; TODO
;        .byte 2
        rts
        .endp

;----------------------------------------------------------------------

        .endp                   ; End of tip
