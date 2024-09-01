vcount = $d40b

p1      = $80
p2      = $82
p3      = $84

        org $2000
        .var .byte scroll_fine = 0
        .var .word scroll_offset = 0
start
        mwa #dl $230
        mwa #$80 623
        ldx #8
loop    mva colors,x 704,x
        dex
        bpl loop


main_loop
        mwa #sprites p1
        lda 20
        lsr
        lsr
        and #7
        tax
        lda offset,x
        sta p1
        
        mwa #sm p2
        adw p2 scroll_offset

        ldx #64
yloop
        ldy #19
xloop
        mva (p1),y (p2),y
        dey
        mva (p1),y (p2),y
        dey
        bpl xloop
        adw p1 #160
        adw p2 #40
        dex
        bne yloop
        
effect  lda vcount
        sta $d40a
        sta $d01a
        cmp #100
        bcc effect

        lda 20
        and #1
        bne skip

        lda scroll_fine
        asl
        and #2
        sta $d40a
        sta $d404

        inc scroll_fine
        lda scroll_fine
        and #1
        beq skip
        inc scroll_offset
skip

        jmp main_loop

        
        .local colors
        .byte $00,$02,$04,$06,$08,$0a,$0c,$f8,$0e
        .endl

        .local dl
        .byte $70,$70,$70

        .rept 64
        .byte $5f,a(sm + #*40)
        .byte $5f,a(sm + #*40)
        .byte $5f,a(sm + #*40)
        .endr

        .byte $41,a(dl)
        .endl
        
        .local offset
        width=20
:8      .byte #*width
        .endl 
        
        sm = $3000


        org $4000
        .local sprites
        ins "RoboCop-Sprites-Remapped-160x64.bin"
        .endl
        
        run start
