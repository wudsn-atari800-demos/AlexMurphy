
        org $2000
        
start   mva #>chr 756
        mva #0 710
        mva #14 709
        jmp *
        
        org $4000
chr     ins "font-8x8.chr"

        org $bc40
        .byte "SERVE THE PARTY   PROTECT THE DEMO SCENE"
        .byte "UPHOLD THE CODE   JAC! AND BUDDY 2K24 SE"
        run start
