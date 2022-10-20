ORG 0x0000
RST_0:
	NOP				;reset vector
	DI				;turn off interrupts
	LXI	SP,0xFFD0h	;preparing the stack
	JMP	sub_main

ORG 0x0008
RST_1:
	NOP

ORG 0x0010
RST_2:
	NOP

ORG 0x0018
RST_3:
	NOP

ORG 0x0020
RST_4:
	NOP

ORG 0x0028
RST_5:
	NOP

ORG 0x0030
RST_6:
	NOP

ORG 0x0038
RST_7: ;rom entry
	NOP


ORG 0x0040
sub_main:
	MVI	A,0x06
	OUT	0x78

	LXI	H,0xF000		;set hl to the first ram address
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
	CALL	mask_display
	OUT	0x40
	MVI	A,0x02
	OUT	0x50
	IN	0x50



LXI	B,str_yolo
CALL	cpy_str_to_screen_cursor_pos



foreverloop:
	jmp foreverloop


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


mask_display: ;work on me
	LXI	H,var_C000_display_buff ;screen buffer
	LXI	D,0xF7FF

mask_display_loop:
	MOV	A,M			;move screen buff into A
	ANA	B			;check a = a&b
	MOV	M,A			;put it back
	INX	H
	INX	D

	MOV	A,D
	CPI	0x00		;have we reached the end 255 bytes
	JNZ	mask_display_loop

	MOV	A,B			;move the mask byte into A
	CPI	0x00		;is the mask byte zero?
	RNZ				;if not zero ret

	LXI	H,0xC050
	MVI	A,0x80
	MOV	M,A			;move ;0x80 to 0xc050

	SHLD	var_FF00	;move 0xc050 to 0xff00
	RET


var_C000_display_buff equ 0xC000


label_0800 equ 0x0800
;mystery code jumpped to from the ROM


str_yolo:
	DB "HELLO WORLD!"
	DB 0


var_F000        equ 0xf000
var_FF00 	equ 0xFF00; = 0xc050
var_FF02	equ 0xFF02
var_FF03	equ 0xFF03
var_FF04	equ 0xFF04
var_FF06	equ 0xFF06
var_FF07	equ 0xFF07
var_FF09	equ 0xFF09
var_FF0A	equ 0xFF0A
var_FF0B	equ 0xFF0B
var_FF0C	equ 0xFF0C
var_FF0E	equ 0xFF0E
var_FF0F	equ 0xFF0F
var_FF11	equ 0xFF11
var_FF12	equ 0xFF12
var_FF14	equ 0xFF14
var_FF22	equ 0xFF22
var_FFCE	equ 0xFFCE
var_FFD0	equ 0xFFD0;top of stack
var_FFF8:	equ 0xFFF8
var_FFFA:	equ 0xFFFA
var_cursor_pos_FFFC:	equ 0xFFFC


var_C000_display_buff equ 0xC000


