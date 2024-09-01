;
; 	>> LZSS Player - Zeropage definitions include <<<
;
;	(c) 2024 by JAC! for Silly Venture 2k24 SE
;
;	Based on https://github.com/dmsc/lzss-sap/blob/main/asm/playlzs16.asm
;
;       @com.wudsn.ide.lng.mainsourcefile=LZSS-Player-Test.asm

	.local lzss
chn_copy    .ds pokey_lzss_registers
chn_pos     .ds pokey_lzss_registers
bptr        .ds 2
cur_pos     .ds 1
chn_bits    .ds 1
bit_data    .ds 1
	.endl
