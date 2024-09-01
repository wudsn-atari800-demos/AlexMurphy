;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Pre-loader to put content under the OS
;

        icl "AlexMurphy-Globals.asm"

        org $2000       ; Info segment

        .byte 13,10
        .byte '>>> Alex Murphy <<<',13,10
        .byte '(c) 2024 by JAC! for Silly Venture 2k24 SE',13,10
        .byte 'Build 2024-08-19',13,10,0
        

        org $2000       ; Fade down and check system segement

        .proc preloader
        jsr fade_down

        lda #0
        sta rtclok+1
        sta rtclok+2
       
        jsr check_system
        rts

        .proc wait
        clc
        adc rtclok+2
loop    cmp rtclok+2
        bne loop
        rts
        .endp           ; End of wait

        .proc fade_down
color   = $80

fade_loop
        ldx #9
        ldy #0
color_loop
        lda color0,x
        and #$0f
        beq store
        ldy #1
        lda color0,x
        pha
        and #$f0
        sta color
        pla
        and #$0f
        sec
        sbc #1
        ora color
store   sta color0,x
        dex
        bpl color_loop
        lda #2
        jsr wait
        cpy #1
        beq fade_loop
        mva #$ff portb
        rts
        .endp

       .proc check_system
        
        .proc check_pal
        lda pal
        cmp #1
        beq ok
        mwa #sm.requires_pal dl.lms
        jmp display_error
ok
        .endp

        .proc check_cartridge
        mva #$ff portb
        ldx $a000
        inc $a000
        cpx $a000
        bne ok
        mwa #sm.remove_cartridge dl.lms
        jmp display_error
ok
        .endp
        
        .proc check_os_ram

        lda #0
        sta sdmctl              ; Disable ANTIC DMA to prevent broken DLs or flickering
        lda #1
        jsr wait
        sei
        lda #0
        sta irqen
        sta nmien
        mva #$fe portb
        ldx $fffc
        inc $fffc
        cpx $fffc
        php
        inc portb
        mva #$40 nmien
        mva pokmsk irqen
        plp
        cli

        bne ok
        mwa #sm.requires_64k dl.lms
        jmp display_error
ok
        .endp
        rts
        
        .proc display_error
        mva #$22 sdmctl
        mwa #dl sdlstl
loop    ldx vcount
        bne loop
line_loop
        txa
        asl
        clc
        adc rtclok+2
        sta wsync
        sta colpf0
        inx
        bpl line_loop

        jmp loop
        .endp           ; End of display_error

        .local dl
:12     .byte $70
        .byte $46
lms     .word $ffff
        .byte $41,a(dl)
        .endl
        
        .local sm
        .local requires_pal
        .byte " DEMO REQUIRES PAL! "
        .endl
        .local remove_cartridge
        .byte " REMOVE CARTRIDGE!  "
        .endl
        .local requires_64k
        .byte " DEMO REQUIRES 64K! "
        .endl
        .endl

        .endp           ; End of check_system
        

        .endp           ; End of preloader
;----------------------------------------------------------------------
        ini preloader
        

        org loader_spare        ; Loader spare are with charset, screen memory and display list
        
        .local loader_chr
        ins "../gfx/loader/Loading-Screen - Chars.bin"
        .endl

        .local loader_sm
        ins "../gfx/loader/Loading-Screen - Map (8bpc, 48x6).bin"
        .endl
        m_info loader_sm

        .local loader_dl
        .byte $70,$70,$70
        .byte $70,$70,$70,$70,$70,$70,$70,$70,$30
        .byte $42,a(loader_sm),$70,$02,$02,$02,$02,$70,$02
        .byte $41,a(loader_dl)
        .endl

        .echo "Load spare ends at ", *

        org $2000       ; Loader screen

        .proc loader_screen
        lda #1
        jsr wait
        mwa #$23 sdmctl
        mwa #loader_dl sdlstl
        mva #>loader_chr chbas

        jsr fade_up
        rts        

        .proc fade_up
        ldx #0
fade_loop
        lda #2
        jsr wait
        stx color1
        inx
        cpx #16
        bne fade_loop
        rts
        .endp          ; End of fade_up

        .proc wait
        clc
        adc rtclok+2
loop    cmp rtclok+2
        bne loop
        rts
        .endp           ; End of wait

        .endp           ; End of loader_screen

        ini loader_screen
        
 
 ;----------------------------------------------------------------------
 
         org $2000      ; Copy under OS
 
        .proc copy_under_os
        mva #$ff portb
        sta coldst

        sei
        lda #0
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
        rts
        
        .endp           ; End of copy_under_os


        icl "../msx/LZSS-Player-Song.asm"

        ini copy_under_os
