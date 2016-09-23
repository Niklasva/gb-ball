.include	"../gbdk/libc/global.s"
.include 	"gfx.s"

.globl	.init_vram
.globl	.copy_vram
.globl	.init_wtt
.globl	.init_btt
.globl	.set_xy_wtt
.globl	.mv_sprite
.globl	.set_sprite_prop
.globl	.set_sprite_tile
.globl	.jpad
.area	_BSS

TOP_EDGE 		= 15
BOTTOM_EDGE	= 155
LEFT_EDGE		= 10
RIGHT_EDGE	= 165

.sframe:
.ds	0x01
.ball_position_x:
.ds	0x02
.ball_position_y:
.ds	0x02
.ball_speed_x:
.ds	0x03
.ball_speed_y:
.ds	0x03

.area	_CODE

_main::
	DI
	CALL	.display_off
	LD	A,  #0b11100100
	LDH	(.BGP),  A
	LDH	(.OBP0),  A

	;; Initialize tiles
	LD	HL,  #0x8000
	LD	DE,  #0x1000
	LD	B,  #0x00
	CALL	.init_vram	; Init the tile set at 0x8000 with 0x00
	LD	B,  #0xFF
	CALL	.init_btt		; Init the tiles tables with 0xFF
	CALL	.init_wtt

	LD	BC,  #.tp0
	LD	HL,  #0x9000-(.endtp0-.tp0)
	LD	DE,  #.endtp0-.tp0
	CALL	.copy_vram

	LD	BC,  #.tp1	; Move tiles (ball)
	LD	HL,  #0x8000
	LD	DE,  #.endtp1-.tp1
	CALL	.copy_vram



	;; Init sprite
	XOR	A
	LD	(.sframe), A
	LD	C, #0x00
	LD	D, #0x00
	CALL	.set_sprite_prop
	LD	C, #0x01
	LD	D, #0x00
	CALL	.set_sprite_prop

	LD	A, #0x10
	LD	(.ball_position_x), A
	XOR	A
	LD	(.ball_position_x+1), A
	LD	A, #0x10
	LD	(.ball_position_y), A
	XOR	A
	LD	(.ball_position_y+1), A
	XOR	A


	LD	A, #0x00
	LD	(.ball_speed_x), A
	LD	A, #0xFF
	LD	(.ball_speed_x+1), A
	XOR	A

	LD	A, #0x00
	LD	(.ball_speed_y), A
	LD	A, #0xFF
	LD	(.ball_speed_y+1), A

	CALL	.tile_sprite
	CALL	.place_sprite
	LD	A, #0b11100111
		; LCD		= On
		; WindowBank	= 0x9C00
		; Window	= On
		; BG Chr	= 0x8800
		; BG Bank	= 0x9800
		; OBJ		= 8x16
		; OBJ		= On
		; BG		= On
	LDH	(.LCDC), A
	EI

.update:
	CALL	.wait_vbl_done
	CALL	.move_ball
	;CALL	.jpad
	;JP .ball_collision

	CALL	.jpad
	LD	D,A

	AND	#.B		; Is B pressed ?
	CALL	NZ, .change_direction_y

	JP .update
	RET

.move_ball:
	CALL .ball_collision
	;; Update the ball's x position
	LD	A, (.ball_position_x)	; Hämta bollens nuvarande position
	LD	H, A					; och lagra den i HL-registret
	LD	A, (.ball_position_x+1)	;
	LD	L, A					;
	LD	A, (.ball_speed_x)		; Hämta bollens nuvarande hastighet
	LD	B, A					; och lagra den i BC-registret
	LD	A, (.ball_speed_x+1)	;
	LD	C, A					;
	ADD	HL, BC 				; HL = ball_position_x + ball_speed_x
	;; Spara resultatet -- HL -> ball_position_x
	LD	A, L
	LD	(.ball_position_x+1), A
	LD	A, H
	LD	(.ball_position_x), A

	;; Gör samma för y
	LD	A, (.ball_position_y)
	LD	H, A
	LD	A, (.ball_position_y+1)
	LD	L, A
	LD	A, (.ball_speed_y)
	LD	B, A
	LD	A, (.ball_speed_y+1)
	LD	C, A
	ADD	HL, BC
	LD	A, L
	LD	(.ball_position_y+1), A
	LD	A, H
	LD	(.ball_position_y), A

	CALL	.place_sprite


	RET

.ball_collision:
	LD	A, (.ball_position_y)
	CP	#BOTTOM_EDGE			; Om bollen slår i golvet
	JP	NC, .change_direction_y	; Studsa


	CP	#TOP_EDGE				; Om bollen slår i taket
	JP	C, .change_direction_y

	LD	A, (.ball_position_x)
	CP	#RIGHT_EDGE
	JP	NC, .change_direction_x

	CP	#LEFT_EDGE
	JP	C, .change_direction_x

	RET

.change_direction_x:
	LD	A, (.ball_speed_x)
	LD	B, A
	LD	A, #0
	DEC	A
	SUB	B
	LD	(.ball_speed_x), A

	LD	A, (.ball_speed_x+1)
	LD	B, A
	LD	A, #0
	DEC	A
	SUB	B
	LD	(.ball_speed_x+1), A
	RET

.change_direction_y:
	LD	A, (.ball_speed_y)
	LD	B, A
	LD	A, #0
	DEC	A
	SUB	B
	LD	(.ball_speed_y), A

	LD	A, (.ball_speed_y+1)
	LD	B, A
	LD	A, #0
	DEC	A
	SUB	B
	LD	(.ball_speed_y+1), A
	RET

.tile_sprite:
	LD	A, (.sframe)
	LD	HL, #.ball_tiles
	RLCA
	LD	B, #0x00
	LD	C, A
	ADD	HL, BC
	LD	C, #0x00		; Sprite 0x00
	LD	A, (HL+)
	LD	D, A
	PUSH	HL
	CALL	.set_sprite_tile
	POP	HL
	LD	C, #0x01		; Sprite 0x01
	LD	A, (HL+)
	LD	D, A
	CALL	.set_sprite_tile
	RET

.place_sprite:
	LD	C, #0x00		; Sprite 0x00
	LD	A, (.ball_position_x)
	LD	D, A
	LD	A, (.ball_position_y)
	LD	E, A
	PUSH	DE			; Store position
	CALL	.mv_sprite
	LD	C, #0x01		; Sprite 0x01
	POP	DE			; Restore position
	LD	A,  #0x08
	ADD	A,  D
	LD	D,  A
	CALL .mv_sprite
	RET

.area	_LIT
