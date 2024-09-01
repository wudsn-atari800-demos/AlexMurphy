;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Song proxy modules.
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm

;----------------------------------------------------------------------
; Perform stereo detection and prepare song replay
;----------------------------------------------------------------------

        .proc song

        .proc init
        jsr lzss.player.detect_stereo
        lda #<[lzss.song_data_address]
        ldx #>[lzss.song_data_address]
        jsr lzss.player.init_song

        rts
        .endp

;----------------------------------------------------------------------
; Play song, restart if required
;----------------------------------------------------------------------

        .proc play
;        m_color $0e
        jsr lzss.player.play_frame
;        m_color $00

        jsr lzss.player.check_song_end
        bne not_at_end
        lda #<[lzss.song_data_address]
        ldx #>[lzss.song_data_address]
        jsr lzss.player.init_song
        
not_at_end
        rts
        .endp
        
        .endp

