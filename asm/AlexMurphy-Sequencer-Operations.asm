;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Operation sequence for the sequencer.
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm

	.local operations

	.use main.sequencer

;===============================================================


;        .local debug
;        m_init text_rasters.set_forground_metallic
;        m_poke tip.jdl_active 1
;        m_poke tip.scroll_active 0
;        m_poke tip.console_active 1              ; Activate console keys
;loop
;        m_poke text.scroll_active 1
;        m_wait_time 1
;        m_jump loop
;        .endl

	.local sequence ;

        m_init text_rasters.set_forground_metallic
        m_call text_rasters.pokey_bars.execute

        m_poke tip.jdl_active 1
        m_wait_time 1276
        m_poke text_rasters.pokey_bars.chroma_mask $ff

        m_wait_time 1244
        m_call text_rasters.fade_background
        m_wait_time 32
;        
        m_poke text.scroll_active 1
        m_wait_value text.scroll_active 0       ;End of first text

        m_poke tip.jdl_active 0
        m_poke tip.scroll_active 1
        m_wait_value tip.scroll_block 1
        m_wait_value tip.scroll_block 0
        m_poke tip.jdl_active 1
        m_poke text.scroll_active 1

        m_call text_rasters.shifted_bars.execute
        m_wait_value text.scroll_active 0       ;End of second text (..relax)
        m_poke tip.scroll_active 0

        m_wait_time 100        
        m_poke text.scroll_active 1
        m_poke tip.jdl_move_active 1
        m_poke tip.scroll_active 1
        m_init text_rasters.set_forground_metallic
        m_call empty_procedure
        m_wait_value text.scroll_active 0       ;End of third text (..groups)
        m_wait_value tip.scroll_block 0

        m_call text_rasters.shifted_bars.execute
        m_poke text.scroll_active 1
        
loop    m_wait_value text.scroll_active 0       ;End of fouth text (..kudos)
        m_wait_time 50
        m_poke text.scroll_active 1
        m_init text_rasters.set_forground_metallic
        m_call empty_procedure

        m_poke tip.console_active 1              ; Activate console keys

        m_wait_value text.scroll_active 0       ;Repeat
        m_wait_time 50
        m_poke text.scroll_active 1
        m_call text_rasters.shifted_bars.execute
        m_jump loop

        .endl


;===============================================================

	.endl	;End of operations

	m_info operations

