
        org $600
        .local dl
        .byte $70,$70,$70,$70,$70,$70,$70,$70,$70
        .byte $42,a(sm),$70,$02,$02,$02,$02,$70,$02
        .byte $41,a(dl)
        .endl

sm      ins "Loading-Screen - Map (8bpc, 48x6).bin"

        org $2000
        
chr     ins "Loading-Screen - Chars.bin"



start   mwa #dl 560
        mva #$23 559
        mva #>chr 756
        mva #0 710
        sta 712
        mva #15 709
        jmp *

        .echo "End address ",*

        run start
