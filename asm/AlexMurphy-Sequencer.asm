;
;       >>> Alex Murphy - Serve the party; Protect the demo scene; uphold the code <<<
;
;       (c) 2024 by JAC! for Silly Venture 2k24 SE
;
;	Sequencer to run all different effects along the with the tune.
;
;       @com.wudsn.ide.lng.mainsourcefile=AlexMurphy.asm

	.proc sequencer

	.enum operation
	wait_time
	wait_value
	init
	mva
	mwa
	call
	jump
	.ende


	.macro m_init
	.byte operation.init,a(:1)
	.endm

	.macro m_call
	.byte operation.call,a(:1)
	.endm

	.macro m_wait_time
	.byte operation.wait_time,a(:1)
	.endm

	.macro m_wait_value
	.byte operation.wait_value,a(:1),:2
	.endm

	.macro m_jump
	.byte operation.jump,a(:1)
	.endm

	.macro m_poke
	.byte operation.mva,:2,a(:1)
	.endm
	
	.macro m_dpoke
	.byte operation.mwa,a(:2),a(:1)
	.endm

	.macro m_animate_row
	.byte operation.animate_row+:1+:2
	.endm

;	.macro m_stop
;	.byte operation.init,a(system.irq)
;	.endm

loop	.if .def show_time
	ldx $d20a
	stx $d01a
	.endif
	lda rtclok+2
	cmp #0			;Wait as long as the count is still the same
last_cnt = *-1
	beq loop
	sta last_cnt		;Store new count

	.if .def show_time
	lda #0
	sta $d01a
	.endif

	jsr fetch_operation
call_adr = *+1
	jsr empty_procedure
;addition_adr = *+1
	jmp loop

;===============================================================

        .proc empty_procedure
        rts
        .endp

;===============================================================

	.proc fetch_operation	;Wait until condition holds true, then fetch next operation
	jsr wait_time
wait_adr = *-2
	bne return

next_operation
	jsr get_byte

	cmp #operation.wait_time
	bne no_wait_time
	jsr get_byte
	sta wait_time.counter
	jsr get_byte
set_operation_wait		;IN: <A>=high byte of wait counter
	sta wait_time.counter+1
	mwa #wait_time wait_adr
return	rts

no_wait_time

	cmp #operation.wait_value
	bne no_wait_value
	jsr get_byte
	sta wait_value.value_adr
	jsr get_byte
	sta wait_value.value_adr+1

set_wait_value
	jsr get_byte
	sta wait_value.value
	mwa #wait_value wait_adr
	rts

no_wait_value
	cmp #operation.init
	bne no_init
	jsr get_byte
	sta init_adr
	jsr get_byte
	sta init_adr+1
	jsr empty_procedure
init_adr = *-2
	jmp next_operation

no_init	cmp #operation.mva
	bne no_mva
	jsr get_byte
	tax
	jsr get_byte
	sta mva_adr
	jsr get_byte
	sta mva_adr+1
mva_adr = *+1
	stx $ffff
	jmp next_operation

no_mva	cmp #operation.mwa
	bne no_mwa
	jsr get_byte
	tax
	jsr get_byte
	tay
	jsr get_byte
	sta mwa_adr
	jsr get_byte
	sta mwa_adr+1
	txa
	jsr mwa_sub
	inw mwa_adr
	tya
	jsr mwa_sub
	jmp next_operation
mwa_sub
mwa_adr = *+1
	sta $ffff
	rts

no_mwa	cmp #operation.call
	bne no_call
	jsr get_byte
	sta call_adr
	jsr get_byte
	sta call_adr+1
	jmp next_operation

no_call
	cmp #operation.jump
	bne no_jump
	jsr get_byte
	tax
	jsr get_byte
	stx get_byte.lda_adr
	sta get_byte.lda_adr+1
	jmp next_operation
no_jump

        .byte 2                 ; Should never get here


	.proc get_byte
lda_adr = *+1
	lda operations
	inw lda_adr
	rts
	.endp			;End of get_byte

	.endp			;End of fetch_operation

;===============================================================

	.proc wait_time		;Returns with Z=0 if counter has reached zero
	lda counter
	ora counter+1
	beq zero
	sbw counter #1
	lda #1
zero	rts

counter	.word 0
	.endp

;===============================================================

	.proc wait_value	;Returns with Z=0 if value address has has reached value
value_adr = *+1
	lda $ffff 
value	= *+1
	cmp #0
	rts
	.endp
	
;===============================================================

	.endp			;End of sequencer