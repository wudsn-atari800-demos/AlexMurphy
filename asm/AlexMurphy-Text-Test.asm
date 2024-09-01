;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Text scroller module test.
;

        icl "AlexMurphy-Globals.asm"

lzss.pokey_shadow = $400

        org $2000
        
        mva #$23 sdmctl
        mwa #dl sdlstl
        mwa #dl.return text_dl.jump_address
        
        jsr text.init

main_loop

        ldy #0
        lda text.print_letter_to_buffer.text_charmap_address+1
        jsr print_hex
        ldy #2
        lda  text.print_letter_to_buffer.text_charmap_address
        jsr print_hex

        ldy #5
        lda text.letter_width
        jsr print_hex_byte

        lda text.char_column
        jsr print_hex_byte

        mva #0 colbk
        jsr wait_frame


        .proc dli
sync
        lda vcount
        sta colbk
        cmp #3+13
        bne sync
        mva #0 colbk
        sta wsync
        sta wsync
        jsr text.kernel

        sta wsync
        .endp

        mva #0 colpf1
        sta colpf2
        mva #$e0 chbase

        sta wsync
        mva #$0e colpf1
        mva #$84 colpf2
        mva #$22 dmactl
        
        jsr text.scroll_new_fine
        
        jsr text_rasters.set_forground_metallic

        mva random colbk
        jmp main_loop

        jmp *


        .proc wait_frame
        lda rtclok+2
loop    ldx vcount
        stx colbk
        cmp rtclok+2
        beq loop
        rts
        .endp

;----------------------------------------------------------------------

        icl "AlexMurphy-Text.asm"
        icl "AlexMurphy-Text-Rasters.asm"
        icl "AlexMurphy-Text-Data.asm"

;----------------------------------------------------------------------

        .local dl
        .byte $70,$70,$70
        .byte $01,a(text_dl)
return
        .byte $70
:16     .byte $42,a(text.charmap.data+text.charmap.bytesPerLine*#)

        .byte $70
        .byte $42,a(debug)
        .byte $41,a(dl)
        .endl

        .local debug
:40     .byte $00
        .endl


        .proc print_hex_byte    ; IN: <A>=value, <Y>=offset
        jsr print_hex
        iny
        iny
        iny
        rts
        .endp

;----------------------------------------------------------------------

        .proc print_hex         ; IN: <A>=value, <Y>=offset
        pha
        lsr
        lsr
        lsr
        lsr
        tax
        lda hexchars,x
        sta debug,y
        pla
        and #15
        tax
        lda hexchars,x
        sta debug+1,y
        rts
        
        .local hexchars
        .byte "0123456789ABCDEF"
        .endl

        .endp

        