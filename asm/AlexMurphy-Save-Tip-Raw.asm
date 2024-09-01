;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Converts "Robocop-160x188-Top.tip" and "Robocop-160x188-Bottom.tip" to "RoboCop-160x188.raw"
;
;       @com.wudsn.ide.lng.outputfile=../gfx/RoboCop-160x188.raw

        icl "AlexMurphy-Globals.asm"


        .macro ins_tip

        offset = :1*topLines*width
;        ins "../gfx/Pattern.tip",headerSize+offset,blockSize
        ins "../gfx/Robocop-160x188-Top.tip",headerSize+offset,blockSize
        ins "../gfx/Robocop-160x188-Top.tip",headerSize+offset+blockSize,(topLines-blockLines)*width
        ins "../gfx/Robocop-160x188-Bottom.tip",headerSize+offset,bottomLines*width

        .endm
        
        opt h-

        .local tip_data

        .local gr9
        ins_tip 0
        .endl
        m_info gr9

        .local gr10
        ins_tip 1
        .endl
        m_info gr10

        .local gr11
        ins_tip 2
        .endl
        m_info gr11
        
        .endl

        m_info tip_data


