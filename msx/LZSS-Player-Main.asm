;
; 	>> LZSS Player - Main routines include <<<
;
;	(c) 2024 by JAC! for Silly Venture 2k24 SE
;
;	Based on https://github.com/dmsc/lzss-sap/blob/main/asm/playlzs16.asm
;
;       @com.wudsn.ide.lng.mainsourcefile=LZSS-Player-Test.asm

	.local lzss

        .proc player

;----------------------------------------------------------------------
; Detect is 2nd POKEY is present
;----------------------------------------------------------------------
;	KMK method: If POKEY is set to HALT mode, RANDOM will become $ff within a few cycles.

	.proc detect_stereo	; OUT: <X>=0 (single POKEY), 1 (dual POKEY)

	offset = $10		; Address offset of the 2nd POKEY

	ldx #$00
	stx skctl		; Halt 1st POKEY
	stx skctl+offset	; Halt 2nd POKEY
	ldy #$03		; Reset and release 2nd POKEY
	sty skctl+offset
	sta wsync		; Delay necessary for accelerator boards
	sta wsync

	lda #$ff
loop	and random		; See if 1st pokey is still halted (random = $ff)
	inx
	bne loop

	sty skctl		; Reset and release 2nd POKEY

	cmp #$ff
	bne mono
	inx
	rts

mono	lda #$2c		;Turn STA abs,x into BIT abs
	sta play_frame.store_2nd_pokey
	rts
	.endp

;----------------------------------------------------------------------
; Song Initialization - this runs in the first tick:
;----------------------------------------------------------------------

        .proc init_song	        ; IN: <A>=<song, <X>=>song

        sta song_ptr
        stx song_ptr + 1

        jsr get_byte            ; Remember channel bit mask
        sta play_frame.song_data_chn_bits
        
	; Init POKEYs
	lda #3
	sta pokey+$0f
	sta pokey+$1f

        ; Init all channels
        ldx #pokey_lzss_registers-1
        ldy #0
        mwa #buffers+255 bptr

clear   jsr get_byte            ; Read just init value and store into buffer and POKEY
        sta pokey,x
        sty chn_copy,x          ; Y==$00

        sta (bptr),y
        inc bptr+1              ; Next page
        dex
        bpl clear

        sty bptr                ; Initialize buffer pointer low-byte
        sty cur_pos
        iny                     ; Y==$01
        sty bit_data            ; Must be $01
        rts
.endp

;----------------------------------------------------------------------
; Play one frame of the song
;----------------------------------------------------------------------

        .proc play_frame
        mva #>buffers bptr+1

        ; Initialized with the first byte of song_data
song_data_chn_bits = *+1
        mva #0 chn_bits
        ldx #8

        ; Loop through all "channels",one for each POKEY register
chn_loop
        lsr chn_bits
        bcs skip_chn            ; C=1 : skip this channel

        lda chn_copy,x          ; Get status of this stream
        bne do_copy_byte        ; If > 0 we are copying bytes

        ; We are decoding a new match/literal
        lsr bit_data            ; Get next bit
        bne got_bit
        jsr get_byte            ; Not enough bits,refill!
        ror                     ; Extract a new bit and add a 1 at the high bit (from C set above)
        sta bit_data
got_bit jsr get_byte            ; Always read a byte,it could mean "match size/offset" or "literal byte"
        bcs store               ; Bit = 1 is "literal",bit = 0 is "match"
        
        sta chn_pos,x           ; Store in "copy pos"
        
        jsr get_byte
        sta chn_copy,x         ; Store in "copy length"

                                ; And start copying first byte
do_copy_byte
        dec chn_copy,x          ; Decrease match length,increase match position
        inc chn_pos,x
        ldy chn_pos,x

        lda (bptr),y            ; Now,read old data,jump to data store

store   ldy cur_pos
        sta pokey,x             ; Store to output and buffer
store_2nd_pokey
        sta pokey+$10,x
        sta pokey_shadow,x
        sta (bptr),y

skip_chn
        inc bptr+1              ; Increment channel buffer pointer high byte

        dex
        bpl chn_loop            ; Next channel

        inc cur_pos             
        rts
.endp

;----------------------------------------------------------------------
; Get the next byte from the song
;----------------------------------------------------------------------
        .proc get_byte
        lda $ffff
        inc song_ptr
        bne skip
        inc song_ptr+1
skip    rts
	.endp

song_ptr = get_byte + 1
    
;----------------------------------------------------------------------
; Check for ending of song and jump to the next frame
;----------------------------------------------------------------------
	.proc check_song_end   ; OUT: Z=0 is song has ended

        lda song_ptr+1
        cmp #>song_end
        bne not_end
        lda song_ptr
        cmp #<song_end
        bne not_end
not_end	rts
	.endp
	
	.endp                  ; End of player
	
	m_info player

        .endl                  ; End of lzss
