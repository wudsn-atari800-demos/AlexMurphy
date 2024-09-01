;
;       >> LZSS Player - Data areas include <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Based on https://github.com/dmsc/lzss-sap/blob/main/asm/playlzs16.asm
;
;       @com.wudsn.ide.lng.mainsourcefile=LZSS-Player-Test.asm

        .local lzss
        .local buffers
        .ds $100*pokey_lzss_registers
        .endl
        
        m_assert_align buffers $100
        m_info buffers
        
        .local pokey_shadow
:9      .byte $00
        .endl
        .endl
 
