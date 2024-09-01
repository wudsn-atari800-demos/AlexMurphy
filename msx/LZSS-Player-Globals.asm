;
;       >> LZSS Player - Song globals include <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Based on https://github.com/dmsc/lzss-sap/blob/main/asm/playlzs16.asm
;
;       @com.wudsn.ide.lng.mainsourcefile=LZSS-Player-Test.asm


        .local lzss
song_data_address = $d800       ; Up to $fa5b
pokey_lzss_registers = 9
song_end = song_data_address+.filesize 'Buddy - Robocop C64-Theme_ok.lzss'

        .endl
