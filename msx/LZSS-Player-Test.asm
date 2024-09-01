;
;       >> LZSS Player - Player test <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Based on https://github.com/dmsc/lzss-sap/blob/main/asm/playlzs16.asm
;

        icl "../asm/AlexMurphy-Globals.asm"

font    = $4000

        org $80

        icl "LZSS-Player-Zeropage.asm"

        org $2000

        .proc loader
        mva #$ff portb
        sta coldst
        lda rtclok+2
sync    cmp rtclok+2
        beq sync
        lda #0
        sta sdmctl
        sta dmactl
        sei
        sta irqen
        sta nmien
        
        dec portb
        .proc copy_song_data
        ldy #>[.len lzss.song_data+$ff]
        ldx #0
loop
from    = *+1
        lda lzss.song_data,x
to      = *+1
        sta lzss.song_data_address,x
        inx
        bne loop
        inc from+1
        inc to+1
        dey
        bne loop
        .endp

        inc portb
        mva #$40 nmien
        mva pokmsk irqen
        cli


copy_font        
        lda $e000,x
        sta font,x
        lda $e100,x
        sta font+$100,x
        lda $e200,x
        sta font+$200,x
        lda $e300,x
        sta font+$300,x
        inx
        bne copy_font
        mva #>font chbas
        rts
        .endp

        icl "LZSS-Player-Song.asm"

        ini loader

        org $2000

        .proc main
        mva #$22 sdmctl
        jsr wait_frame
        sei
        lda #0
        sta irqen
        sta nmien
        mva #$fe portb

        jsr init_stereo

restart_song
        lda #<[lzss.song_data_address]
        ldx #>[lzss.song_data_address]
        jsr lzss.player.init_song


play_next_frame
        lda #>lzss.song_end
        sec
        sbc lzss.player.song_ptr+1
        clc
        adc #40
        tay
        lda lzss.player.song_ptr
        sta (savmsc),y

        lda #32
sync    cmp vcount
        bne sync
        sta wsync
        mva #$0e colbk
        jsr lzss.player.play_frame
        mva #$00 colbk
        lsr atract
        
        jsr lzss.player.check_song_end
        bne play_next_frame
        inc color4
        inc color4
        jmp restart_song
        .endp                          ;End of main


        .proc init_stereo
        
        jsr lzss.player.detect_stereo
        cpx #1
        beq is_stereo
        ldx #text.mono-text
        .byte $2c
is_stereo
        ldx #text.stereo-text
        ldy #2
print
        lda text,x
        beq text_end
        sta (savmsc),y
        iny
        inx
        bne print
text_end
        rts

        .local text
mono    .byte "Mono",0
stereo  .byte "Stereo",0
        .endl

        .endp

;----------------------------------------------------------------------
; Wait for next frame
;----------------------------------------------------------------------

        .proc wait_frame
        lda rtclok+2
delay   cmp rtclok+2
        beq delay
        rts
        .endp

;----------------------------------------------------------------------
; LZSS Includes
;----------------------------------------------------------------------

        icl "LZSS-Player-Main.asm"
        
        .align $100
        icl "LZSS-Player-Data.asm"

        run main
