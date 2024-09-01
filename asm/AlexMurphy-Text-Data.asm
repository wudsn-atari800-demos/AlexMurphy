;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;       Text scroller module data.
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm

        .local text_data

        .use text

        .local buffer
        .ds :text.charmap.bytesPerLetter
        .endl

        .local colors
        .local foreground
        .ds 32
        .endl
        
        .local background
        .ds 32
        .endl
        .endl

        .endl
