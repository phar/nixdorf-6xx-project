ORG 0x0000
RST_0:
	NOP				;reset vector
	DI				;turn off interrupts
	LXI	SP,var_FFD0	;preparing the stack
	JMP	sub_main

;**************************************************************************************************


ORG 0x0008
RST_1:
	NOP
	JMP	RST_7
	JMP	RST_7
	NOP

;**************************************************************************************************


ORG 0x0010
RST_2:
	NOP
	JMP	RST_7
	JMP	RST_7
	NOP

;**************************************************************************************************


ORG 0x0018
RST_3:
	LXI	H,0x8000
	SHLD	error_counter_FF12 	;store HL into ram
	RET
	NOP

;**************************************************************************************************


ORG 0x0020
RST_4:				;observed to be the keyboard input handler
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	JMP	int_4_handler
	NOP

;**************************************************************************************************


ORG 0x0028
RST_5:
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	JMP	int_5_handler ; i think this is the comms input interrupt
	NOP

;**************************************************************************************************


ORG 0x0030
RST_6:
	PUSH	PSW
	IN	0x78
	PUSH	PSW
	JMP	label_05C4
	NOP

;**************************************************************************************************


ORG 0x0038
RST_7: ;warmboot
	DI					;disable interrupts
	LXI	SP,var_FFD0		;load stack pointer
	JMP	RST_0			;hard reboot
	NOP

;**************************************************************************************************


ORG 0x0040
sub_main:
	MVI	A,0x06
	OUT	0x78

	LXI	H,var_F000		;set hl to the first ram address
	MVI	B,0x00			;init zero into b

init_mem_loop:
	MOV	M,B
	INX	H
	MOV	A,H
	ORA	A
	JNZ	init_mem_loop		;has the address counter rolled over at the top of mem?
					
;init ram variables
	LXI	H,var_FF14
	SHLD	var_FF04		;init variable var_f
	SHLD	var_FF0C

	LXI	H,var_F020
	SHLD	char_buff_ptr

	LXI	H,0x0642
	SHLD	var_FF0A				;FF0A=06 FF0B=42

	LXI	H,var_FFD0					; i assume this is an addr, (it is!)
	SHLD	var_FFFA
	SHLD	var_FFF8


	IN	0x78
	ANI	0x20
	JNZ	label_007A
	MVI	A,0x01
	STA	var_FF03

label_007A:
	MVI	A,0x10			;send 0x10 then 0x7f
	OUT	0x60			;send a \n
	XRA	A				;
	OUT	0x60			;send a \x7f command (redraw?)
	IN	0x40			;read from 0x40
	RAL					;test port40 for a bit
	JNC	label_0089		;
	MVI	B,0x7F			;yes, B_reg = 0x7f, else B_reg = 0x00 for the mask  seems to check if the display
						;should be cleared or not
	
label_0089:
	CALL	mask_display ;A_reg  = mask_display(B_reg)
	OUT	0x40
	
	MVI	A,0x02			;whats this about?
	OUT	0x50
	
	IN	0x50

idle_loop:					; this was observed to be the idle loop
	LXI	H,0x0028			; init HL

	IN	0x40
	CMA
	ANI	0x01
	STA	var_FF02
	RAR
	JNC	label_00A6			; test port 0x40 bit to determine if HL chould be different

	LXI	H,0x0050			;change HL
	
label_00A6:
	SHLD	var_FFFC
	
	EI  					;enable interrupts
	
	LHLD	var_FFFA		;load HL from ram
	MOV	A,M
	ORA	A
	CNZ	sub_041A
	
	LDA	var_FF09
	RAR
	JNC	label_00CA

	LDA	printer_not_ready_flag_FF0E
	RAR
	JC	label_00CA
	
	IN	0x70						;
	ANI	0x10						; test port 0x70 bit 0x10
	CNZ	terminal_cmd_handler_024D					; bit is set
	CZ	terminal_emu_handler_00E1	;if not set
	
label_00CA:
	IN	0x48
	ANI	0x40
	CNZ	RST_4

	LDA	var_FF03
	RAR
	JC	idle_loop

	MVI	A,0x40
	OUT	0x78

	IN	0x68			;doesnt appear that this value is ever used
	JMP	idle_loop


;**************************************************************************************************


terminal_emu_handler_00E1: terminal_emu_handler_00E1(char_buff_ptr)
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	LHLD	char_buff_ptr			;load HL from ram

	MOV	A,M							;switch(A_reg)
	CPI	0x0D
	JZ	handle_CR_0145				;case 0x0d: handle_CR_0145()
	
	CPI	0x0A
	JZ	handle_LF_0172				;case 0x0a: handle_LF_0172()
	
	CPI	0x0B
	JZ	handle_VT_01A5				;case 0x0b: handle_VT_01A5()
	
	CPI	0x20
	JZ	handle_SP_01DD				;case 0x20: handle_SP_01DD()
	
	CALL	test_printer_ready_021E	;default
	
	IN	0x70
	ANI	0x08
	JZ	return_from_int_subroutine		;return
	
	MOV	A,M
	CPI	0xB8
	CZ	return_A_0x20
	
	CPI	0xB6
	JZ	label_022E

label_0112: 		;label_0112(A_reg, HL_reg)
	OUT	0x58
	
	MVI	A,0x80
	OUT	0x60
	
	XRA	A
	OUT	0x60
	
	INX	H
	SHLD	char_buff_ptr
	
label_011F:
	CALL	test_printer_ready_021E
	IN	0x48									;discarded
	IN	0x70
	ANI	0x04
	JZ	label_011F
	
	LDA	var_FF0B
	MOV	E,A
	MVI	D,0x00
	LHLD	var_cursor_col_FF0F			;load HL from ram
	DAD	D
	SHLD	var_cursor_col_FF0F			; var_cursor_col_FF0F = var_cursor_col_FF0F + var_FF0B;
	
	MOV	A,E
	OUT	0x58
	
	MVI	A,0x40
	OUT	0x60
	
	XRA	A
	OUT	0x60
	
	JMP	return_from_int_subroutine			;return


;**************************************************************************************************



handle_CR_0145:
	CALL	test_printer_ready_021E
	IN	0x70
	ANI	0x04
	JZ	return_from_int_subroutine			;return
	
	LHLD	char_buff_ptr			;
	INX	H						;
	SHLD	char_buff_ptr			; increment char_buff_ptr
	
	LHLD	var_cursor_col_FF0F			;load HL from ram
	MOV	A,L
	OUT	0x58
	
	MOV	A,H
	ORI	0x04
	OUT	0x60
	
	ORI	0x40
	OUT	0x60
	
	ANI	0xBF
	OUT	0x60

carriage_return_cursor:
	LXI	H,0x0000
	SHLD	var_cursor_col_FF0F
	JMP	return_from_int_subroutine				;return
	

;**************************************************************************************************


handle_LF_0172:
	CALL	test_printer_ready_021E

	IN	0x70
	ANI	0x02
	IN	0x48							;discarded
	JZ	handle_LF_0172

	LDA	var_FF0A						;
	MOV	D,A								;
	LDA	var_cursor_line_FF11			;
	INR	A								;
	CMP	D								;
	JNZ	label_018B						;var_cursor_line_FF11 != (var_FF0A)

	XRA	A
label_018B:
	STA	var_cursor_line_FF11

	MVI	A,0x08
	OUT	0x58
	
	MVI	A,0x20
	OUT	0x60
	
	XRA	A
	OUT	0x60

label_0199:
	LXI	H,var_F020
	SHLD	char_buff_ptr
	STA	var_FF09
	JMP	label_0500

;**************************************************************************************************

handle_VT_01A5:
	CALL	test_printer_ready_021E

	IN	0x70
	ANI	0x02
	IN	0x48						;iscarded
	JZ	handle_VT_01A5

	LDA	var_cursor_line_FF11
	MOV	D,A
	LDA	var_FF0A
	SUB	D
	MOV	L,A
	MVI	H,0x00
	DAD	H
	DAD	H
	DAD	H
	MOV	A,L
	OUT	0x58
	MOV	A,H
	ANI	0x03
	OUT	0x60
	
	ORI	0x20
	OUT	0x60
	
	ANI	0xDF
	OUT	0x60
	
	LHLD	char_buff_ptr			;load HL from ram
	INX	H
	SHLD	char_buff_ptr			;store incremented var
	
	XRA	A
	STA	var_cursor_line_FF11
	JMP	return_from_int_subroutine			;return

;**************************************************************************************************


handle_SP_01DD:
	CALL	test_printer_ready_021E
	IN	0x48									;discarded

	IN	0x70
	ANI	0x04
	JZ	handle_SP_01DD

	LDA	var_FF0B
	MOV	C,A
	MVI	B,0x00
	XCHG
	LXI	H,0x0000

label_01F3:
	DAD	B
	
	INX	D
	LDAX	D
	CPI	0x20
	JZ	label_01F3
	
	XCHG										;HL<=>DE
	SHLD	char_buff_ptr
	
	CPI	0x0D
	JZ	return_from_int_subroutine					;return
	
	IN	0x48									;discarded
	
	MOV	A,E
	OUT	0x58
	
	MOV	A,D
	OUT	0x60
	
	ORI	0x40
	OUT	0x60
	
	ANI	0xBF
	OUT	0x60
	
	LHLD	var_cursor_col_FF0F			;load HL from ram
	DAD	D
	SHLD	var_cursor_col_FF0F
	JMP	return_from_int_subroutine					;return

;**************************************************************************************************

test_printer_ready_021E:
	IN	0x70
	RAR
	JC	pop_f_err_printer_not_ready
	
	ANI	0x10
	JZ	pop_f_err_printer_not_ready
	RET

;**************************************************************************************************

pop_f_err_printer_not_ready:
	POP	PSW
	JMP	err_printer_not_ready ;does not return from this call

label_022E:
	MVI	A,0x3D
	OUT	0x58
	
	MVI	A,0x80
	OUT	0x60
	
	XRA	A
	OUT	0x60
	
label_0239:
	CALL	test_printer_ready_021E
	IN	0x48							;results are discarded
	
	IN	0x70
	ANI	0x08
	JZ	label_0239
	
	MVI	A,0x2F
	JMP	label_0112

;**************************************************************************************************

return_A_0x20:
	MVI	A,0x20
	RET

;**************************************************************************************************

terminal_cmd_handler_024D:
	PUSH	PSW
	PUSH	B
	PUSH	D
	PUSH	H
	
	MVI	A,0x00
	OUT	0x60
	CALL	test_port_70_and_ret
	
	ANI	0x08
	JZ	return_from_int_subroutine		;return

	LHLD	char_buff_ptr					;switch(char_buff_ptr)P{
	MOV	A,M
	CPI	0x0A
	JZ	label_02A0							;case 0x0a: label_02A0()
	
	CPI	0xB8
	CZ	return_A_0x20						;case 0xb8: return_A_0x20()
	
	CPI	0xB6
	CZ	return_A_0x20					;case 0xB6: return_A_0x20
	
	CPI	0x0B
	JNZ	label_027D						;case 0x0b: label_027D
	JMP	label_027B						;default: label_027B

;**************************************************************************************************


test_port_70_and_ret_from_subroutine:
	CALL	test_port_70_and_ret
label_027B:
	MVI	A,0x0C
label_027D:
	CMA
	OUT	0x58
	
	MVI	A,0x80
	OUT	0x60
	
	XRA	A
	OUT	0x60
	
	INX	H
	SHLD	char_buff_ptr
	
	JMP	return_from_int_subroutine					;return

;**************************************************************************************************



test_port_70_and_ret:
	IN	0x70      									;printer
	RAR
	JC	pop_b_and_jmp_err_printer_not_ready   		;does not return from this call
	RAR
	JNC	pop_b_and_jmp_err_printer_not_ready			;does not return from this call
	RET


;**************************************************************************************************

pop_b_and_jmp_err_printer_not_ready:
	POP	B
	JMP	err_printer_not_ready						;does not return from this call

call_test_port_70_and_ret:										;A_reg - call_test_port_70_and_ret()
	CALL	test_port_70_and_ret
label_02A0:
	MVI	A,0xF5
	OUT	0x58
	
	MVI	A,0x80
	OUT	0x60
	
	XRA	A
	OUT	0x60
	XRA	A
	
	JMP	label_0199

;**************************************************************************************************


label_02AF:
	MVI	A,0x05
	OUT	0x78
	
	MVI	B,0x28
	MVI	C,0x0C
	LDA	var_FF02
	RAR
	JNC	label_02C2
	MVI	B,0x50
	MVI	C,0x18
label_02C2:

	MOV	A,B
	STA	var_FF22
	
	LXI	H,var_F020
	LXI	D,var_C000_display_buff
	
label_02CC:
	IN	0x48
	LDAX	D
	ANI	0x7F
	CPI	0x00
	JNZ	label_02DB
	MVI	A,0x20
	JMP	label_0300

label_02DB:
	CPI	0x1D
	JNZ	label_02E5
	MVI	A,0x5F
	JMP	label_0300

label_02E5:
	CPI	0x1E
	JNZ	label_02EF
	MVI	A,0xB8
	JMP	label_0300

label_02EF:
	CPI	0x1C
	JNZ	label_02F9
	MVI	A,0xB6
	JMP	label_0300

label_02F9:
	CPI	0x1F
	JNZ	label_0300
	MVI	A,0x5E
label_0300:
	MOV	M,A
	INX	H
	INX	D
	DCR	B
	JNZ label_02CC
	MVI	M,0x0D
	INX	H
	MVI	M,0x0A
	LXI	H,var_F020
	SHLD	char_buff_ptr
	MVI	A,0x01
	STA	var_FF09

label_0317:
	LDA	printer_not_ready_flag_FF0E
	RAR
	JC	label_0332
	
	LDA	var_FF09
	RAR
	JNC	label_0345
	
	IN	0x70      ;printer
	ANI	0x10
	CNZ	terminal_cmd_handler_024D
	CZ	terminal_emu_handler_00E1
	
	JMP	label_0317

label_0332:
	MVI	A,0x10
	OUT	0x60
	
	XRA	A
	OUT	0x60
	
	STA	var_FF09
	
	LXI	H,var_F020
	SHLD	char_buff_ptr
	
	JMP	carriage_return_cursor

label_0345:
	LDA	var_FF22
	MOV	B,A
	LXI	H,var_F020
	SHLD	char_buff_ptr
	DCR	C
	JNZ	label_02CC
	JMP	return_from_int_subroutine				;return

;**************************************************************************************************

	RST	7										;????? warmboot

;**************************************************************************************************


err_printer_not_ready:
	LXI	B,var_printer_not_ready_string		;"printer not ready""
	CALL	cpy_str_to_screen_cursor_pos		;cpy_str_to_screen_cursor_pos("printer not ready")
	MVI	A,0x01
	OUT	0x50
	STA	printer_not_ready_flag_FF0E
	JMP	return_from_int_subroutine				;return

;**************************************************************************************************


int_5_handler:
	MVI	A,0x61
	OUT	0x78
	IN	0x78
	ANI	0x40
	JNZ	label_03FF
	
	IN	0x68
	MOV	D,A
	CPI	0x0A
	JZ	label_038C
	CPI	0xA5
	JZ	label_03B4
	ANI	0xC0
	CPI	0xC0
	JZ	label_03CA
	
	CALL	send_char_to_line_buff			; send_char_to_line_buff(D_reg)
	JMP	send_02_on_port_78

label_038C:
	LHLD	char_buff_ptr
	DCX	H
	MOV	A,M
	CPI	0x0D
	JNZ	send_crlf_to_screen
	CALL	send_char_to_line_buff			; send_char_to_line_buff(D_reg)

label_0399:
	LXI	H,var_F020
	SHLD	char_buff_ptr
	MVI	A,0x01
	STA	var_FF09
	JMP	ie_and_return_from_int_subroutine

send_crlf_to_screen:
	MVI	D,0x0D
	CALL	send_char_to_line_buff			; send_char_to_line_buff(D_reg)
	MVI	D,0x0A
	CALL	send_char_to_line_buff			; send_char_to_line_buff(D_reg)
	JMP	label_0399

label_03B4:
	IN	0x78
	RAR
	CNC	inc_and_store_error_counter
	JNC	label_03B4

	CALL	RST_3							;clear error  counter
	
	IN	0x68
	ANI	0x3F
	STA	var_FF0B

	JMP	ie_and_return_from_int_subroutine

label_03CA:
	IN	0x78
	RAR
	CNC	inc_and_store_error_counter
	JNC	label_03CA
	CALL	RST_3							;clear error counter
	IN	0x68
	ANI	0x7F
	STA	var_FF0A
	XRA	A
	STA	var_cursor_line_FF11
	JMP	ie_and_return_from_int_subroutine

;**************************************************************************************************


send_char_to_line_buff:						; send_char_to_line_buff(D_reg)
	LHLD	char_buff_ptr			;load HL from ram
	MOV	M,D
	INX	H
	MVI	A,0xA8
	CMP	L
	JZ	append_crlf_to_buff
	SHLD	char_buff_ptr
	RET

append_crlf_to_buff:
	LXI	H, var_F0A4
	MVI	M,0x0D
	INX	H
	MVI	M,0x0A
	POP	PSW
	JMP	label_0399

label_03FF:
	IN	0x68
	CPI	0xA5
	JZ	label_0411
	LDA	var_FF09
	ORA	A
	JNZ	label_0411



send_02_on_port_78:
	MVI	A,0x02
	OUT	0x78

label_0411:
	IN	0x48
	MVI	A,0x40
	OUT	0x78
	JMP	ie_and_return_from_int_subroutine


;**************************************************************************************************


sub_041A:
	MOV	D,M
	INX	H
	MOV	E,M
	
	MVI	B,0x00
	
	MOV	M,B
	DCX	H
	MOV	M,B
	
	EI  ;enable interrupts
	
	RAL
	JC	label_0465						;label_0465(A_reg)
   ;JMP filter_d_and_store_in_char_buff				; implicit

filter_d_and_store_in_char_buff:			;filter_d_and_store_in_char_buff(D_reg)
	LHLD	char_buff_cntr_FF00			;load HL from ram
	CALL	translate_d			;D_reg = translate_d(D_reg)
	MOV	M,D						;store translated value
	INX	H
	SHLD	char_buff_cntr_FF00

	MOV	A,M
	ORI	0x80
	MOV	M,A

;increment var_FFFA by two untill it reaches 0xffee, then set it  back to (ffD0)
;circular buffer pointer?
cycle_var_FFFA:
	LHLD	var_FFFA			;load HL from ram
	MOV	A,L
	CPI	0xEE
	JNZ	label_0442
	LXI	H,var_FFCE
label_0442:
	INX	H
	INX	H
	SHLD	var_FFFA
	RET

;**************************************************************************************************


translate_d: 			;D_reg = translate_d(D_reg)
	MOV	A,D
	CPI	0x5F			;D == 0x5f?
	JNZ	d_does_not_match		;no
	MVI	D,0x1D			;yes D = 0x1d
	RET
d_does_not_match:
	CPI	0x5E			; d == 0x5e?
	RNZ					;no
	MVI	D,0x1F
	RET

;**************************************************************************************************


translate_d_type2: 				; D_reg = translate_d_type2(A_reg)
	CPI	0xB6
	JNZ	b6_handler
	MVI	D,0x1C
	RET
b6_handler:
	CPI	0xB8
	RNZ
	MVI	D,0x1E
	RET

;**************************************************************************************************


label_0465:  ;label_0465(A_reg)
	RAL
	JC	label_0497
	
	MOV	A,D
	CPI	0xA9
	JZ	a9_handler
	
	CPI	0xA7
	JZ	a7_handler
	
	CPI	0xA2
	JZ	a2_handler
	
	CPI	0xA0
	JZ	a0_handler
	
	CPI	0xA3
	JZ	a3_handler
	
	CPI	0xA4
	JZ	a4_handler
	
	CALL	translate_d_type2			;D_reg = translate_d_type2(A_reg)

	JZ	filter_d_and_store_in_char_buff 			;filter_d_and_store_in_char_buff(D_reg = translate_d_type2(A_reg))
	JMP	cycle_var_FFFA


;**************************************************************************************************


a4_handler:
	CALL	mask_display
	JMP	cycle_var_FFFA

;**************************************************************************************************


label_0497:
	MOV	A,E
	RAL
	JC	label_0562
	MOV	A,D
	ANI	0x1F
	MOV	D,A
	CALL	limit_char_buff_cntr
	LXI	H,0x0000
	MOV	L,D				; HL == (d_regvar & 0x1f)
	PUSH	D
	LDA	var_FF02
	CALL	sub_07AF
	RAR
	CC	sub_07BA
	XCHG
	LXI	H,var_C000_display_buff		;
	DAD	D				;add HL=0xc0000+DE
	POP	D
	MOV	C,E
	XCHG
	LHLD	var_FFFC			;load HL from ram
	XCHG
label_04BE:
	MOV	M,C
	INX	H
	DCR	E
	JNZ	label_04BE
	JMP	cycle_var_FFFA


;**************************************************************************************************

a9_handler:
	MVI	A,0x04
	OUT	0x50
	JMP	cycle_var_FFFA

;**************************************************************************************************


a7_handler:
	MVI	A,0x01
	OUT	0x50
	JMP	cycle_var_FFFA

;**************************************************************************************************


a2_handler: ;takes E as an argument  \ function doesnt get called?
	CALL	limit_char_buff_cntr
	MOV	A,E
	ANI	0x3F
	LXI	H,0x0000
	MOV	L,A
	LDA	var_FF02
	CALL	sub_07AF
	RAR
	CC	sub_07BA
	LXI	B,var_C000_display_buff
	DAD	B
	MOV	B,H
	MOV	C,L
	XCHG
	LHLD	var_FFFC			;load HL from ram
	XCHG
	DAD	D
label_04F5:
	LDAX	B
	MOV	M,A
	INX	H
	INX	B
	DCR	E
	JNZ	label_04F5
	JMP	cycle_var_FFFA

;**************************************************************************************************


label_0500:
	LDA	var_FF03
	RAR
	JNC	return_from_int_subroutine			;return
	CALL	wait_for_ready_with_abort_timeout
	
	MVI	A,0x90
	OUT	0x78
	
	MVI	A,0xAA
	OUT	0x70
	
	MVI	A,0xFF
	OUT	0x68
	
	JMP	return_from_int_subroutine			return

;**************************************************************************************************


a0_handler:
	CALL	limit_char_buff_cntr
	LXI	D,var_C000_display_buff

	LDA	var_FF02
	RAR
	JC	label_052F
	
	LXI	H,0x0028
	LXI	B,0xFE48
	JMP	label_0535

label_052F:
	LXI	H,0x0050
	LXI	B,0xF8D0

label_0535:
	DAD	D

label_0536:
	MOV	A,M
	STAX	D
	INX	H
	INX	D
	INX	B
	MOV	A,B
	ORA	A
	JNZ	label_0536
	JMP	cycle_var_FFFA

;**************************************************************************************************


mask_display: 					;mask_display(B_reg)
	LXI	H,var_C000_display_buff ;screen buffer
	LXI	D,0xF7FF				;screen buffer seems to be 2k bytes

mask_display_loop:
	MOV	A,M			;move screen buff into A
	ANA	B			;check a = a&b
	MOV	M,A			;put it back
	INX	H
	INX	D

	MOV	A,D
	CPI	0x00		;has DE rolled over?
	JNZ	mask_display_loop	;no

	MOV	A,B			;move the mask byte into A
	CPI	0x00		;is the mask byte zero?
	RNZ				;we return if the display is not cleared only masked

	LXI	H,var_C050_display_unk
	MVI	A,0x80
	MOV	M,A			;move ;0x80 to 0xc050

	SHLD	char_buff_cntr_FF00	;move 0xc050 to 0xff00
	RET

;**************************************************************************************************


label_0562:
	MVI	A,0x02
	OUT	0x50
	XRA	A
	STA	var_FF06
	STA	printer_not_ready_flag_FF0E
	CALL	limit_char_buff_cntr
	LXI	H,0x0000
	MOV	A,D
	ANI	0x3F
	MOV	L,A
	PUSH	D
	LDA	var_FF02
	CALL	sub_07AF
	RAR
	CC	sub_07BA
	XCHG
	LXI	H,0xBFFF
	DAD	D
	POP	D
	MVI	D,0x00
	MOV	A,E
	ANI	0x7F
	MOV	E,A
	DAD	D
	SHLD	char_buff_cntr_FF00
	MOV	A,M
	ORI	0x80
	MOV	M,A
	JMP	cycle_var_FFFA

;**************************************************************************************************


a3_handler:
	LHLD	var_FF04			;load HL from ram
	MOV	D,M
	INX	H
	SHLD	var_FF04
	MOV	A,L
	CPI	0x20
	MOV	A,E
	JNZ	label_05AE
	LXI	H,var_FF14
	SHLD	var_FF04
label_05AE:
	CMP	D
	CNZ	transmission_error
	JMP	cycle_var_FFFA

;**************************************************************************************************


transmission_error:
	MVI	A,0x01
	OUT	0x50
	
	DI				;disable interrupts
	
	STA	var_FF06

	LXI	B,var_xmission_err_string		;"XMISSION ERROR"
	CALL	cpy_str_to_screen_cursor_pos; cpy_str_to_screen_cursor_pos("XMISSION ERROR")

	RET

;**************************************************************************************************


label_05C4:
	MVI	A,0x64
	OUT	0x78
	
	POP	PSW				;fix the inconsistant subroutine entry so the exit /can/ be called
	PUSH	B			;
	PUSH	D			;
	PUSH	H			;
	
	RAL
	JC	sub_062D
	MVI	A,0x04
	OUT	0x78
	
	LXI	D,0x0000
	IN	0x68
	MOV	D,A
	CPI	0xA3
	JZ	label_05EC
	
	CPI	0xA2
	JZ	label_05EC
	
	RAL
	JNC	label_05FF
	
	RAL
	JNC	label_05FF
	
label_05EC:
	IN	0x78
	RAR
	CNC	inc_and_store_error_counter
	JNC	label_05EC
	
	CALL	RST_3							;clear error counter
	MVI	A,0x40
	OUT	0x78
	IN	0x68
	MOV	E,A

label_05FF:
	NOP							;iiiiiinteresting alignment for some reason 0x0600

	LHLD	var_FFF8			;load HL from ram
	MOV	A,M
	ORA	A
	JNZ	RST_0				;hard reboot

	MOV	M,D
	MOV	A,D
	ORA	A
	JZ	RST_0			;hard reboot
	
	INX	H
	MOV	M,E
	INX	H
	MOV	A,L
	CPI	0xF0
	JNZ	label_061A

	LXI	H,var_FFD0
label_061A:
	SHLD	var_FFF8
	
label_061D:
	MOV	A,M
	ORA	A
	JNZ	ie_and_return_from_int_subroutine
	
	MVI	A,0x08
	OUT	0x78
	
ie_and_return_from_int_subroutine:
	EI  ;enable interrupts
return_from_int_subroutine:
	POP	H
	POP	D
	POP	B
	POP	PSW
	EI  ;enable interrupts
	RET
	
;**************************************************************************************************


sub_062D:
	IN	0x68
	ANI	0xC0
	CPI	0xC0
	JZ	label_063C
	EI  ;enable interrupts
	IN	0x48
	JMP	label_0648

label_063C:
	IN	0x78
	RAR
	CNC	inc_and_store_error_counter
	JNC	label_063C
	CALL	RST_3							;clear error counter
	
label_0648:
	MVI	A,0x40
	OUT	0x78
	LHLD	var_FFF8			;load HL from ram
	JMP	label_061D
	
	
	
;**************************************************************************************************

	

int_4_handler: int_4_handler(F,BC,DE,HL)
	IN	0x50			;read from keyboard port?
	MOV	D,A				;D_reg: arent i sneeky look at me!
	
	MVI	A,0x9B			;
	CMP	D				;
	JZ	sub_0744		;compare byte read from port with 0x9b

	LDA	var_FF06
	RAR
	JC	return_from_int_subroutine

read_port_48_cmd:
	IN	0x48
	ANI	0x07		;only the lower 3 bits used?
	JNZ	label_0687 ; label_0687(A,DE)  no jump to interesting code that calls external rom

label_0669:
	MVI	E,0xFF      ;i dont know if this is a ram addr FIXME
	MVI	C,0x90


label_066D:
	CALL	wait_for_ready_with_abort_timeout	;sub_078f(0x90, ,0xff)
	MOV	A,C
	OUT	0x78			;write 0x90 (wait_for_ready_with_abort_timeout does not modify C)
	CALL	wait_for_ready_with_abort_timeout	;sub_078f(0x90, ,0xff) ;not sure
	
	MOV	A,D				;D_reg: you didnt forget about me already did you?
	OUT	0x70

	LDA	var_FF03
	RAR
	JC	label_06F3

	MOV	A,E
	OUT	0x68
	
	EI  ;enable interrupts
	
	JMP	return_from_int_subroutine			;return
	
	
;**************************************************************************************************

	
		
label_0687: 			; label_0687(A,DE)
	MOV	E,D				;E = arg1
	CPI	0x02			;case 0x02:
	JNZ	label_06D3		;A != 02?

	MVI	D,0x84			;A = 02, D = 84

	MVI	A,0xDF          ;A = DF
	ANA	E				;A &= E
	CPI	0x54
	JZ	label_06B7		;A == 54?
	CPI	0x58
	JNZ	label_069D		;A != 58?
	RST	7				;warm boot
	
label_069D:
	CPI	0x53
	JZ	label_06C7		;A == 53?
	CPI	0x50
	JZ	label_02AF		;A == 50?
	CPI	0x44
	JNZ	label_06EE		;A != 44?
	
	LDA	0x0800			;A == 44
	CPI	0xFF			;
	JNZ	label_0800		;peek at address 08000, if its NOT 0xff, we'll jump to it
	JMP	label_06EE		;rom is present at 0800

label_06B7:
	LXI	H,var_F01F
	SHLD	char_buff_ptr			;	(0xf01f) = ff07
	IN	0x70      				;
	ANI	0x10
	JZ	handle_VT_01A5				;(A & 0x10) == 0?
	JMP	test_port_70_and_ret_from_subroutine


label_06C7:
	IN	0x70      				;A =
	ANI	0x10
	JZ	handle_LF_0172				;(A & 0x10) == 0?
	MVI	A,0x0A					;A=0A
	JMP	call_test_port_70_and_ret

label_06D3:
	CPI	0x03
	JNZ	label_06DD			;A ARG0 != "03"?"

	MVI	D,0x86					;D = 0x86, A arg0 = 03
	JMP	label_06EE

label_06DD:
	CPI	0x06
	JNZ label_06E7 				;A ARG0 != "06"?"
		
	MVI	D,0x85					;D = 0x85, A arg0 = 06
	JMP	label_06EE

label_06E7:
	CPI	0x05
	JNZ	label_0669				;A ARG0 != "05"?"

	MVI	D,0x82					;D = 0x82, A arg0 == 05

label_06EE: 						;rom not present got here

	MVI	C,0x10					;C = 0x10
	JMP	label_066D


label_06F3:
	EI  ;enable interrupts
	IN	0x48
	IN	0x78
	ANI	0x06
	JZ	label_070A
	LHLD	var_FFFA			;load HL from ram
	MOV	A,M
	ORA	A
	PUSH	D
	CNZ	sub_041A
	POP	D
	JMP	label_06F3

label_070A:
	MOV	A,E
	OUT	0x68
	LHLD	var_FF0C			;load HL from ram
	MOV	M,D
	INX	H
	MOV	A,L
	CPI	0x20
	CZ	sub_077D
	MOV	A,E
	CPI	0xFF
	JNZ	label_0781
	SHLD	var_FF0C
	JMP	return_from_int_subroutine		;return

;**************************************************************************************************

limit_char_buff_cntr:
	LHLD	char_buff_cntr_FF00			;load HL from ram
	MOV	A,M
	ANI	0x7F
	MOV	M,A
	RET

;**************************************************************************************************

inc_and_store_error_counter:
	PUSH	PSW
	PUSH	H
	
	IN	0x48
	
	LHLD	error_counter_FF12
	INR	L
	JNZ	store_counter_and_return
	INR	H
	JNZ	store_counter_and_return		; increment label_073E and reset if i rolls over
	JMP	RST_0			;hard reboot

store_counter_and_return:
	SHLD	error_counter_FF12
	POP	H
	POP	PSW
	RET					;function returns the results of roll-over in carry flag

;**************************************************************************************************

sub_0744:
	LDA	var_FF06				;
	RAR							;
	JNC	label_0758				; test bit flag to skip
	
	EI  						;enable interrupts
	
	LXI	H,var_FF14				;HL = var_FF14
	SHLD	var_FF0C			;var_FF0C = var_FF14
	SHLD	var_FF04			;var_FF03 = var_FF14
	JMP	label_075F
	
label_0758:
	LDA	printer_not_ready_flag_FF0E
	RAR								;
	JNC	read_port_48_cmd			;printer is ready
								
	
label_075F:
	MVI	A,0x02
	OUT	0x50

	PUSH	D						;store D for a moment.. we'll need it later
	
	LXI	D,var_C000_display_buff		;DE  = var_C000_display_buff
	LHLD	var_FFFC				;HL = (var_FFFC)
	MOV	C,L							;C = (var_FFFC  & 0x00ff)
	DAD	D							;HL = HL + DE
	
	XRA	A
zero_screen_area_loop:
	MOV	M,A
	INX	H
	DCR	C
	JNZ	zero_screen_area_loop
	
	POP	D							;recover D from storage
	
	STA	var_FF06					;zero
	STA	printer_not_ready_flag_FF0E					;zero
	
	JMP	read_port_48_cmd

;**************************************************************************************************

sub_077D:
	LXI	H,var_FF14
	RET

;**************************************************************************************************

label_0781:
	MOV	M,E
	INX	H
	MOV	A,L
	CPI	0x20
	CZ	sub_077D
	SHLD	var_FF0C
	JMP	return_from_int_subroutine		;return

;**************************************************************************************************

wait_for_ready_with_abort_timeout:
	IN	0x78
	ANI	0x06
	CNZ	inc_and_store_error_counter		;keep incrementing the counter till a roll over and call rst3?
	JNZ	wait_for_ready_with_abort_timeout
	CALL	RST_3						;clear error counter
	RET

;**************************************************************************************************

cpy_str_to_screen_cursor_pos: ;cpy_str_to_screen_cursor_pos(B_reg)
	PUSH	B				;preserve currrent B reg argument pointer
	LXI	B,var_C000_display_buff			;load MMIO base adderess into B
	LHLD	var_FFFC		;load HL from ram
	DAD	B					; ad var_fffc offset to the MMIO base
	POP	B					;restore b reg
	
loop_cpy:
	LDAX	B				;memory at BC to A (fetch string byte)
	MOV	M,A					;store in (HL)
	INX	H					;increment dest ptr low byte
	INX	B					;inc source ptr low byte (strings are 255 max)
	ORA	A					;is the string done?
	JNZ	loop_cpy
	RET
	
;**************************************************************************************************

sub_07AF: ;what in the f?
	PUSH	D		;store DE
	DAD	H			;HL=HL+HL
	DAD	H			;HL=HL+HL
	DAD	H			;HL=HL+HL
	MOV	D,H			;
	MOV	E,L			; swap HL and DE
	DAD	H			;HL=HL+HL
	DAD	H			;HL=HL+HL
	DAD	D			;HL=HL+DE
	POP	D			;restore DE
	RET

;**************************************************************************************************

sub_07BA:
	DAD	H
	RET

;**************************************************************************************************

var_printer_not_ready_string:
	DB "PRINTER NOT READY"
	DB 0
var_xmission_err_string:
	DB "XMISSION ERROR "
	db 0

	
label_0800 equ 0x0800 				;mystery code jumpped to from the ROM


var_F000    equ 0xF000
var_F01F    equ 0xF01F
var_F020    equ 0xF020
var_F0A4    equ 0xF0A4



char_buff_cntr_FF00 	equ 0xFF00				; 0->128->0 cycling counter
var_FF02	equ 0xFF02				; appears to be a single bit flag
var_FF03	equ 0xFF03
var_FF04	equ 0xFF04				;circular buffer from FF14 to var_FF20
var_FF06	equ 0xFF06				; appears to be a single bit flag
char_buff_ptr	equ 0xFF07				;i see this incrementing like a chr ptr
var_FF09	equ 0xFF09				; appears to be a single bit flag
var_FF0A	equ 0xFF0A
var_FF0B	equ 0xFF0B				;seems to be a buffer
var_FF0C	equ 0xFF0C				;circular buffer from FF14 to var_FF20
printer_not_ready_flag_FF0E	equ 0xFF0E				; appears to be a single bit flag
var_cursor_col_FF0F	equ 0xFF0F
var_cursor_line_FF11	equ 0xFF11
error_counter_FF12	equ 0xFF12

var_FF14	equ 0xFF14				;circular buffer to FF20
			
var_FF22	equ 0xFF22

var_FFCE	equ 0xFFCE					;seems to be a 30 byte circular buffer

var_FFD0	equ 0xFFD0					;top of stack, stack grows up from here

var_FFF8:	equ 0xFFF8
var_FFFA:	equ 0xFFFA
var_FFFC:	equ 0xFFFC


var_C000_display_buff equ 0xC000
var_C050_display_unk equ 0xC050




;IOMAP
;0x40 INPUT/OUTPUT  0b0010 0000,
;0x48 INPUT         0b0010 1000		strobe / latch of some sort?

;0x50 INPUT/OUTPUT  0b0101 0000  takes commands 1,2,4
;0x58 OUTPUT        0b0101 1000, takes commands 0x01,0x02, 0x04

;0x60 OUTPUT        0b0110 0000
;0x68 INPUT/OUTPUT  0b0110 1000		seems to read and write bytes, i think this is the IO card

;0x70 INPUT/OUTPUT  0b0111 0000
;0x78 INPUT/OUTPUT  0b0111 1000


;0000  -----------------------------------
;0400 |____________06204.035______________|
;     |            06204.036              |
;0800  -----------------------------------
;     |         UHHHH JMP LAND            |
;     |                                   |
;     |                                   |
;     |                                   |
;     |                                   |
;C000  -----------DISPLAY MEMORY----------
;C050 |        UNKNOWN LOCATION           |
;     |                                   |
;C200  -----------------------------------
;     |                                   |
;     |                                   |
;     |                                   |
;     |                                   |
;     |                                   |
;F000  ----------unknown vars-------------
;F0FF |-----------------------------------|
;     |                                   |
;FF00 |________main program vars__________|
;FFD0 |____________stack__________________|
;FFF8 |__________some vars________________|
;FFFF  -----------------------------------
