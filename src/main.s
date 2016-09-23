.include	"../gbdk/libc/global.s"
.include 	"gfx.s"
.include	"ball.s"

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

STARTX = 60
STARTY = 20
TOP_EDGE = 17
BOTTOM_EDGE = 155
LEFT_EDGE = 9
RIGHT_EDGE = 165

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
.pad_position_x:
	.ds	0x04
.pad_position_y:
	.ds	0x04

.area	_CODE

_main::
	DI
	CALL	.display_off
	LD	A,  #0b11100100
	LDH	(.BGP),  A
	LDH	(.OBP0),  A

	LD	HL,  #0x8000
	LD	DE,  #0x1000
	LD	B,  #0x00
	CALL	.init_vram
	LD	B,  #0xFF
	CALL	.init_btt
	CALL	.init_wtt

	LD	BC,  #.tp0
	LD	HL,  #0x9000-(.endtp0-.tp0)
	LD	DE,  #.endtp0-.tp0
	CALL	.copy_vram

	LD	BC,  #.tp1
	LD	HL,  #0x8000
	LD	DE,  #.endtp1-.tp1
	CALL	.copy_vram

	;; Init sprite
	XOR	A
	CALL .init_ball_sprite
	CALL .init_pad_sprite

	LD	A, #100
	LD	(.pad_position_x), A
	LD	A, #140
	LD	(.pad_position_y), A

	LD	A, #STARTX
	LD	(.ball_position_x), A
	XOR	A
	LD	(.ball_position_x+1), A
	LD	A, #STARTY
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

	CALL	.init_ball_sprite
	CALL	.update_ball_sprite_position


	LD	A, #0b11100111
          ; LCDC         = On
          ; WindowBank   = 0x9C00
          ; Window       = On
          ; BG Chr       = 0x8800
          ; BG Bank      = 0x9800
          ; OBJ          = 8x16
          ; OBJ          = On
          ; BG           = On
	LDH	(.LCDC), A
	EI

.update:
	CALL	.wait_vbl_done
	CALL	.move_ball
	CALL	.jpad
	LD	D,A

	AND	#.LEFT
	CALL	NZ, .move_pad_left

	LD	A,D
	AND	#.RIGHT
	CALL	NZ, .move_pad_right


	JP .update
	RET

;; Ställ in sprite 0x00 <- tile 0x00 (bollens tile)
.init_ball_sprite:
	LD	C,#0x00		; Sprite 0x00
	LD	D,#0x00		; Default sprite properties (ingen flip etc.)
	CALL	.set_sprite_prop
	LD	C,#0x00		; Sprite 0x00
	LD	D,#0x00		; Tile 0x00
	CALL	.set_sprite_tile
	RET

;; Ställ in sprite 0x01 <- 0x03 (spelarens tile)
;; Flippa 0x03 för att göra 0x02
.init_pad_sprite:
	LD	C,#0x01		; Sprite 0x01
	LD	D,#0x00		; Default sprite properties
	CALL	.set_sprite_prop
	LD	C,#0x01		; Sprite 0x01
	LD	D,#0x03		; Tile 0x03
	CALL	.set_sprite_tile

	LD	C,#0x02		; Sprite 0x02
	LD	D,#0x20		; Flip X
	CALL	.set_sprite_prop
	LD	C,#0x02		; Sprite 0x02
	LD	D,#0x03		; Tile 0x03
	CALL	.set_sprite_tile
	RET

.update_ball_sprite_position:
	LD	C, #0x00
	LD	A, (.ball_position_x)
	LD	D, A
	LD	A, (.ball_position_y)
	LD	E, A
	CALL	.mv_sprite
	RET

.update_pad_sprite_position:
	LD	C, #0x01
	LD	A, (.pad_position_x)
	LD	D, A
	LD	A, (.pad_position_y)
	LD	E, A
	CALL	.mv_sprite

	LD	C, #0x02
	LD	A, (.pad_position_x)
	ADD	A, #0x08 ; placera 0x02 8 pixlar till höger om 0x01
	LD	D, A
	LD	A, (.pad_position_y)
	LD	E, A
	CALL	.mv_sprite
	RET

.move_pad_left:
	LD	A, (.pad_position_x)
	DEC A
	LD	(.pad_position_x), A
	RET

.move_pad_right:
	LD	A, (.pad_position_x)
	INC A
	LD	(.pad_position_x), A
	RET

.area	_LIT
