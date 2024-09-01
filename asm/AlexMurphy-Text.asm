;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Text scroller module code.
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm

        .local text

        .use text_data

screen_width = 48
scroll_width = screen_width*2


        .var .byte letter_width = 0       ;1..6
        .var .byte char_column = 0     ;0...letter_width-1

        // Hardware scroll
        .var .byte scroll_active = 0
        .var .byte scroll_fine = 3      ;3..0, decrementing
        .var .byte scroll_offset = 0    ;0.. screen_width-1


;----------------------------------------------------------------------
        .proc init
        jsr scroll_new_letter
        jsr text.print_column_from_buffer     ;IN: text_char_column
        rts
        .endp

        .proc get_letter          ; OUT: <A>=0..63

text_ptr = *+1
        lda text_content
        bne not_end
        mwa #text_content text_ptr
        jmp get_letter
not_end
        inw text_ptr

        cmp #text_content.stop
        bne not_stop
        mva #0 scroll_active
        jmp get_letter

not_stop
        sec
        sbc #32
        rts

        .endp
        
;----------------------------------------------------------------------

        .proc print_letter_to_buffer        ;IN: <A>=letter (0..63), OUT: buffer
        .var .word text_charmap_address = 0
        tax
        mva charmap.addresses.llo,x text_charmap_address
        mva charmap.addresses.lhi,x text_charmap_address+1
        lda charmap.widths,x
        sec
        sbc #'1'
        spl
        .byte 2
        cmp #6
        scc
        .byte 2 
        sta letter_width

        lda #0
        sta char_column

        ldx #charmap.bytesPerLetter-1
copy_inner_chars
        clc
        lda text_charmap_address
        adc charmap.offsets.llo,x
        sta p3
        lda text_charmap_address+1
        adc charmap.offsets.lhi,x
        sta p3+1

        ldy #0
        lda (p3),y
        sta buffer,x

        dex
        bpl copy_inner_chars
        rts
        .endp                   ; End of print_char_to_buffer       


;----------------------------------------------------------------------

        .proc print_column_from_buffer      ;IN: char_column, scroll_offset 
?lines = charmap.letter_height
sm_start = text_sm+[?lines-1]*scroll_width-4

        lda scroll_offset
        clc
        adc #<sm_start
        sta p2
        lda #>sm_start
        adc #0
        sta p2+1
        
        ldy char_column
        cpy #.len buffer_addresses.llo
        scc
        .byte 2

        mva buffer_addresses.llo,y buffer_ptr
        mva buffer_addresses.lhi,y buffer_ptr+1

        ldx #?lines-1
loop
buffer_ptr = *+1
        lda buffer,x
        ldy #0
        sta (p2),y
        ldy #screen_width
        sta (p2),y
        sbw p2 #scroll_width
        dex
        bpl loop
        rts

        .local buffer_addresses
        .local llo
:charmap.column_width .byte <[buffer+#*[?lines]]
        .endl
        .local lhi
:charmap.column_width .byte >[buffer+#*[?lines]]
        .endl
        .endl
        
        .endp                   ; End of print_column_from_buffer


;----------------------------------------------------------------------

        .proc scroll_new_fine
        ldx scroll_fine
        dex
        bpl no_new_column
        jsr scroll_new_column

        ldx char_column
        inx
        stx char_column
        cpx letter_width
        bcc no_new_letter
        
        jsr scroll_new_letter

no_new_letter
        jsr print_column_from_buffer

        ldx #3
no_new_column
        stx scroll_fine
        rts
        .endp                   ; End of scroll_frame

;----------------------------------------------------------------------

        .proc scroll_new_column
        lda scroll_offset
        clc
        adc #1
        cmp #screen_width
        bne no_full_width

        lda #0
no_full_width
        sta scroll_offset

        ldx #[charmap.letter_height-1]
        ldy #[charmap.letter_height-1]*3
loop    lda scroll_offset
        clc
        adc llo,x
        sta text_dl.lms+1,y
        lda lhi,x
        adc #0
        sta text_dl.lms+2,y
        dey
        dey
        dey
        dex
        bpl loop
        rts
        
        .local llo
:charmap.letter_height .byte <[text_sm+scroll_width*#] 
        .endl
 
        .local lhi
:charmap.letter_height .byte >[text_sm+scroll_width*#] 
        .endl

        .endp            ; End of scroll_new_column

;----------------------------------------------------------------------
        
        .proc scroll_new_letter
        jsr get_letter
        jsr print_letter_to_buffer
        rts
        .endp

;----------------------------------------------------------------------

        .proc vbi
        lda scroll_active
        beq not_active
        jsr scroll_new_fine
not_active
        rts
        .endp
        
        .proc kernel

         mva #>charset.top chbase
         ldx #>charset.bottom
         lda scroll_fine
         clc
         adc #$08                ; Gain some DMA cycles for using higher hscrol value
         sta hscrol              ; WARNING: Can cause abnormal playfield DMA and broken DL/DLIs

        .rept 32
        lda colors.background+#
        ldy colors.foreground+#
        .if # = 16
;:20     nop
        jsr delay       ; 12 cycles
        jsr delay       ; 12 cycles
        jsr delay       ; 12 cycles
:2      nop
        .else
        sta wsync
        .endif
;        sty colbk
        sty colpf1
        .if # = 16
        stx chbase
        .endif
        sta colpf2
        .endr
        rts
        
        .proc delay
        rts
        .endp

        .endp                   ; End of kernel

;----------------------------------------------------------------------

        m_align $400
        .local charset
        .local top
;        .byte $80,$40,$20,$10,$08,$04,$02,$01
        ins "../gfx/font/Font-Top - Chars.bin"
        .end
        
        m_align $400
        .local Bottom
;        .byte $01,$02,$04,$08,$10,$20,$40,$80
        ins "../gfx/font/Font-Bottom - Chars.bin"
        .end
        .endl
        
        m_info charset

;----------------------------------------------------------------------

        .local charmap
  
        letter_count = 64
        
        columns = 16
        column_width = 5        ; With space
        rows = 4
        row_height =5           ; With space
  
        letter_width = 4        ; Without space column
        letter_height = 4       ; Without space row
        bytesPerLine = columns*column_width
        bytesPerRow = bytesPerLine*row_height
        bytesPerLetter = column_width*letter_height

        bytesPerStripe = bytesPerLine*2

        // Merge the two interleaved charmaps together, skipping every 5th (empty) line
        .local data
        .rept rows
;:4      .byte "01234ABCDE01234ABCDE01234ABCDE01234ABCDE01234ABCDE01234ABCDE01234ABCDE01234ABCDE"
        ins "../gfx/font/Font-Top - Map (8bpc, 80x20).bin",+0+bytesPerRow*#,bytesPerStripe
        ins "../gfx/font/Font-Bottom - Map (8bpc, 80x20).bin",+bytesPerStripe+bytesPerRow*#,bytesPerStripe
        .endr
        .endl
        
        m_info data

        .local addresses
        .local llo
        .rept letter_count
        .byte <[charmap.data+(#/columns)*bytesPerLine*letter_height+(#%columns)*column_width]
        .endr
        .endl
        .local lhi
        .rept letter_count
        .byte >[charmap.data+(#/columns)*bytesPerLine*letter_height+(#%columns)*column_width]
        .endr
        .endl
        .endl   ; End of addresses

        .local widths
        ;       !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_
        .byte '3345566333443536545555555533454555555555555556555555555655546444'
        .endl

        .local offsets  ; Offsets to get all chars of a letter

llo      .rept column_width
        ?width = #
        .rept letter_height
        ?height = #
        .byte <[[?height*bytesPerLine]+?width]
        .endr
        .endr

lhi      .rept column_width
        ?width = #
        .rept letter_height
        ?height = #
        .byte >[[?height*bytesPerLine]+?width]
        .endr
        .endr

        .endl           ; End of offsets
        
        .endl           ; End of charmap

        .endl           ; End of text

;----------------------------------------------------------------------

        .local text_dl
        .byte $00       ;Is skipped when required
extra_blank_top
        .byte $00

lms
:4      .byte $52,a(text_sm+text.scroll_width*#)

reload_lms
        .byte $4f,a($0000)
extra_blank_bottom
        .byte $10
jump_address = *+1
        .byte $01,a($0000)
        .endl
        
        m_assert_same_1k text_dl

         .local text_content
        stop = 1

;        .rept 64
;        .byte 32+#
;        .endr

        .byte 'HELLO SILLY VENTURE! WELCOME TO MY SMALL ENTRY FOR SUMMER EDITION 2K24.'
        .byte '                      ',stop
        .byte 'THIS MELODIC COVER OF THE ROBOCOP THEME WAS CREATED BY BUDDY. GRAB A COLD DRINK AND RELAX!'
        .byte '                      ',stop
        .byte 'RESPECT TO ALL MEMBERS OF ABBUC*AGENDA*ATARI OLDSCHOOLERS*AYCE*DESIRE*LAMERS*MEC*MYSTIC BYTES*MARQUEE DESIGN*NEW GENERATION*RADIANCE*PPS*SUSPECT*TRISTESSE*ZELAX '
        .byte '                      ',stop
        .byte 'SPECIAL THANKS TO EPI*F#READY*GREY*KRYSTONE*PHAERON*TEBE FOR ALL YOUR TOOLS AND SUPPORT.'
        .byte '                      ',stop
        .byte 'YOU CAN NOW USE THE CONSOLE KEYS TO TOGGLE THE EFFECTS.'
        .byte '                      ',stop
        .byte 0 
        .endl