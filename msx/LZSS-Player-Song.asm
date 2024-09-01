;
;       >> LZSS Player - Song include <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Based on https://github.com/dmsc/lzss-sap/blob/main/asm/playlzs16.asm
;
;       @com.wudsn.ide.lng.mainsourcefile=LZSS-Player-Test.asm

        .local lzss

        .local song_data
        ins 'Buddy - Robocop C64-Theme_ok.lzss'
        .endl

        m_info song_data
        .endl
