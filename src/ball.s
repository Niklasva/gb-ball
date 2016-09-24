.move_ball:
	CALL .ball_collision
	;; Update the ball's x position
	LD	A, (.ball_position_x)     ; Hämta bollens nuvarande position
	LD	H, A                      ; och lagra den i HL-registret
	LD	A, (.ball_position_x+1)   ;
	LD	L, A                      ;
	LD	A, (.ball_speed_x)        ; Hämta bollens nuvarande hastighet
	LD	B, A                      ; och lagra den i BC-registret
	LD	A, (.ball_speed_x+1)      ;
	LD	C, A                      ;
	ADD	HL, BC                    ; HL = ball_position_x + ball_speed_x
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

	CALL	.update_ball_sprite_position
	CALL	.update_pad_sprite_position

	RET

.ball_collision:

.edge_collision:
	LD	A, (.ball_position_y)
	CP	#BOTTOM_EDGE              ; Om bollen slår i golvet
	JP	NC, .lose_ball   ; DÖ
	LD	A, (.ball_position_y)
	CP	#TOP_EDGE                 ; Om bollen slår i taket
	JP	C, .change_direction_y

	LD	A, (.ball_position_x)
	CP	#RIGHT_EDGE
	JP	NC, .change_direction_x
	CP	#LEFT_EDGE
	JP	C, .change_direction_x

.pad_collision:
	LD	A, (.pad_position_y)
	ADD	A, #8
	LD	B, A
	LD	A, (.ball_position_y)
	CP	B
	JP	C, .pad_collision_ret

	LD	A, (.pad_position_x)
	LD	B, A
	LD	A, (.ball_position_x)
	CP	B
	JP	Z, .change_direction_x
	JP	C, .pad_collision_ret
	SUB A, #16
	CP	B
	JP	Z, .change_direction_x
	JP	NC, .pad_collision_ret

	JP .change_direction_y

.pad_collision_ret:
	RET

.lose_ball:
	LD	A, #STARTX
	LD	(.ball_position_x), A
	LD	A, #STARTY
	LD	(.ball_position_y), A
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
