;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Converts "RoboCop-160x188-Blocks.raw" to "RoboCop-160x188.raw"

;       @com.wudsn.ide.lng.outputfile=../gfx/RoboCop-160x188-Blocks.raw

        icl "AlexMurphy-Globals.asm"


        .get "../gfx/RoboCop-160x188.raw"

        opt h-

        org $4000
        
chunkOffset = totalLines*width

        .macro m_padding
        .if * & $7ff = $7f8
        .byte $00,$00,$00,$00,$00,$00,$00,$00
        .endif
        .endm

        .macro m_block
        .rept totalLines/2
        ?offset = #*width*2
        .print "Offset=",?offset

        .sav [chunkOffset*2+?offset] width
        m_padding

        .sav [chunkOffset*:1+?offset] width
        m_padding

        .sav [chunkOffset*2+?offset+width] width
        m_padding

        .sav [chunkOffset*:2+?offset] width
        m_padding
        .endr
        
        m_align $4000
        .endm
        
        m_block 0 1
        m_block 1 0



