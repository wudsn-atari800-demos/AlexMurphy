;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Text raster module effects.
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm

        .proc text_rasters

raster_lines = 32

        .use text_data

;----------------------------------------------------------------------

        .proc set_forground_metallic

        ldx #raster_lines-1
loop    mva color_bar,x colors.foreground,x
l       mva #0 colors.background,x
        dex
        bpl loop
        rts
        
        .local color_bar
        .byte $02,$04,$06,$08,$0a,$0c,$0e,$0e
        .byte $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
        .byte $0e,$02,$04,$06,$08,$0a,$0c,$0e
        .byte $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
        .endl
        
        .endp

        .proc fade_background
        lda rtclok+2
        lsr
        scs
        rts

        ldx #raster_lines-1
loop
        lda colors.background,x
        jsr darker
        sta colors.background,x
        dex
        bpl loop
        rts
        
        .proc darker
        pha
        and #$f0
        sta chroma
        pla
        and #15
        beq black
        sub #1
chroma = *+1
        ora #$00
black   rts
        .endp
        
        .endp                   ; End of fade_background

;----------------------------------------------------------------------

        .proc shifted_bars
        
        .proc execute

        inc color_cnt
color_cnt = *+1
        ldx #0
        cpx #28
        bne no_over
        ldx #0
no_over stx color_cnt

        lda color_cnt
        lsr
        tax

        ldy #0
loop    lda colorbar,x
        sta colors.foreground,y
        lda #1
        jsr add_x
        cpy #8
        beq skip
        cpy #16
        beq skip
        cpy #24
        bne no_skip
skip    lda #8
        jsr add_x
no_skip
        iny 
        cpy #.len colors.foreground
        bne loop
        rts


        .proc add_x
        .var .byte temp
        stx temp
        clc
        adc temp
        cmp #14
        bcc no_over
        sbc #14
no_over
        tax
        rts
        .endp


        .local colorbar
        .rept 4
        .byte $0e,$0c,$0a,$08,$06,$04,$02
        .byte $02,$04,$06,$08,$0a,$0c,$0e
        .endr        
        .endl

        rts
        
        .endp           ; End of execute
        
        .endp           ; End of shifted_bars

;----------------------------------------------------------------------

        .proc pokey_bars
        .var .byte chroma_mask = $0f

        .proc execute
        ldx #2
        ldy #1
        jsr set_background

        ldx #0
        ldy #14
        jsr set_background

        ldx #4
        ldy #26
        jsr set_background
        rts

        .proc set_background
        .var .byte chroma = $00
        .var .byte luma = $00

        lda lzss.pokey_shadow,x
        asl
        and #$f0
        sta chroma

        lda lzss.pokey_shadow+1,x
        and #15
        sta luma
        jsr add_chroma
        sta colors.background+2,y
        jsr darker
        sta colors.background+1,y
        sta colors.background+3,y
        jsr darker
        sta colors.background+0,y
        sta colors.background+4,y
        rts
        
        .proc darker
        lda luma
        beq black
        sec
        sbc #1
        sta luma
black
        .endp                   ; Fall trough

        .proc add_chroma
        cmp #$00
        beq black
        ora chroma
        and chroma_mask
black   rts
        .endp
        
        .endp                   ; End of set_background

        .endp                   ; End of execute

        .endp                   ; End of pokey_bars
        .endp
