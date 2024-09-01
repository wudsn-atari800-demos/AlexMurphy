

  
        icl "AlexMurphy-Globals.asm"

        org lzss_zp
        
        icl "msx/LZSS-Player-Zeropage.asm"
        
        org $400
        icl "msx/LZSS-Player-Data.asm"

;----------------------------------------------------------------------

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
        sta song_data_address,x
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
        .endp

        icl "msx/LZSS-Player-Song.asm"

        ini loader

;----------------------------------------------------------------------

        org $2000

        .proc main
        jsr init
        
        mva #0 rtclok+2
        jsr tip.init_palette

        jsr tip.init_dl
        jsr tip.setup_dl
        
        jsr init_song

        jsr wait_frame
        mva #$22 sdmctl
        mwa #dl sdlstl
frame_loop        
        jsr wait_frame
        jsr play_song

        lda rtclok+2
        and #1
        bne no_scroll
        lda consol
        lsr
;        bcs no_scroll
        jsr tip.next_scroll_line_and_block
no_scroll

        jmp frame_loop

;----------------------------------------------------------------------
; Wait for next frame
;----------------------------------------------------------------------

        .proc wait_frame
        lda rtclok+2
delay
;        mvx random colbk
        cmp rtclok+2
        beq delay
        rts
        .endp

;----------------------------------------------------------------------

        .proc init
        sei
        lda #0
        sta irqen
        sta nmien
sync    sta vcount
        bne sync
        sta dmactl
        sta sdmctl
        mva #$fe portb
        mwa #nmi $fffa
        mva #$40 nmien
        sta nmist
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

        jsr tip.restore_dl
        jsr tip.flip_sm
        jsr tip.setup_dl
        jsr tip.setup_jump_dl

;       Copy shadow registers
        mwa sdlstl dlptr
        mva sdmctl dmactl
:9      mva pcolor0+# colpm0+#

        mwa #tip.dli vdslst
        mva #$c0 nmien

        inc rtclok+2
        sne
        inc rtclok+1

 
        pla
        tay
        pla
        tax
        pla
        rti
        .endp

        .endp

;===============================================================

;----------------------------------------------------------------------
; Perform stereo detection and prepare song replay
;----------------------------------------------------------------------

        .proc init_song
        jsr lzss.player.detect_stereo
        lda #<[song_data_address]
        ldx #>[song_data_address]
        jsr lzss.player.init_song

        rts
        .endp

;----------------------------------------------------------------------
; Play song, restart if required
;----------------------------------------------------------------------

        .proc play_song
;        mva #$01 prior
;        mva #$0e colbk
        jsr lzss.player.play_frame
;        mva #$00 colbk

        jsr lzss.player.check_song_end
        bne not_at_end
        lda #<[song_data_address]
        ldx #>[song_data_address]
        jsr lzss.player.init_song
        
not_at_end
        rts
        .endp

;----------------------------------------------------------------------
  
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

last_jdl_line    .byte $ff      ;0...smallBlockLines-1+2, negative indicates not set

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

        .proc dli
        
        .var .byte top_lines = 26       ;visibleLines
        .var .byte middle_lines = 34
        .var.byte bottom_lines = 0

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
        ldx middle_lines
        beq no_display
        mva #$00 prior
        sta colpf2
        mva #$23 dmactl
        mva #14 colpf1

        lda tip_page
        eor scroll_fine
        beq no_skip
        sta wsync
no_skip

loop    sta wsync
        mva colors-1,x colpf1
        dex
        bne loop
        sta wsync
        mva #$00 colpf1
        sta colpf2
        mva #$22 dmactl
        

;        mva top.luma_line bottom.luma_line
;        sta prior
no_display
        .endp                   ; End of middle
;
;        .proc bottom
;        mva #$00 colbk
;luma_mode = *+1
;        mva #$40 luma_line
;        ldx bottomLines
;        beq no_display
;loop    sta wsync
;        mva #$c0 prior
;        sta wsync
;luma_line = *+1
;        mva #$40 prior
;        eor #$c0
;        sta luma_line
;        dex
;        bne loop
;no_display
;        .endp                   ; End of bottom

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

        ldy last_jdl_line               ; Where was the $01(a(other_dl) previously?
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
        sta dl+[dl_template.lms3-dl_template]+2
        jsr get_block_lms
        sta dl+[dl_template.lms4-dl_template]+2
        jsr get_block_lms
        sta dl+[dl_template.lms5-dl_template]+2
        jsr get_block_lms
        sta dl+[dl_template.lms6-dl_template]+2

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

        .proc setup_jump_dl
        mwa #dl.jump_dl_base p1
        ldy scroll_line
        sty last_jdl_line

        clc             ;p2=p1+y
        tya
        beq is_0        ; First LMS is at 0, next DC is at 2
        adc #2
is_0    adc p1
        sta p2
        lda p1+1
        adc #0
        sta p2+1
        

        ldy #0
        lda (p2),y
        and #$0fe
        sta (p2),y
        

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

;        mwa p2 scroll_dl.jump_dl+1
;        .byte 2

        rts
        .endp

;----------------------------------------------------------------------

        .endp                   ; End of tip

        .endp                   ; End of main

        m_info main

;----------------------------------------------------------------------


;       Music data
        icl "msx/LZSS-Player-Main.asm"

;----------------------------------------------------------------------
        
        org $3000

        .local dl_template // Total 238 scanlines
        dc = $0f
        ldc = $40+dc
        
        .byte $80
lms1    .byte ldc, a(sm1+smallBlock*0)
:50     .byte dc

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

lms6   .byte ldc, a(sm1+smallBlock*5)
:32     .byte dc

        .byte $41,a(dl)
        .endl

        m_assert_same_1k dl_template

        org $3200
        .local dl
        lms2 = dl+[dl_template.lms2-dl_template]
        wait_vbl = dl+[dl_template.wait_vbl-dl_template]
        jump_dl_base = dl+[dl_template.jump_dl_base-dl_template]
        .ds $200
        .endl

        m_assert_same_1k dl

        org $3400
        .local font
        ins "gfx/font-34/Font-34px.pic"
        .endl
        font_width = 40 ;196?

        m_info font
        
        org $3a00
        .local text_dl
        .byte $00
:34     .byte $4f,a(font+#*font_width)
reload_lms .byte $4f, a($0000)
jump_dl  .byte $41,a(dl)
        .endl

        org sm1
        ins "gfx/RoboCop-160x188-Blocks.raw"


        run main