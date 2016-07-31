;
; MD201607, 256 SPLITS WITH UPPER/LOWER BORDERS OPEN
;

; Code and "graphics" by T.M.R/cosine
; Music by Sack/Cosine


; Select an output filename
		!to "md201607.prg",cbm


; Yank in binary data
		* = $3600
music		!binary "data/bliss.raw"

		* = $c000
char_set	!binary "data/aladdin.chr"

		* = $c800
		!binary "data/copyright.chr"

		* = $ce00
sprite_data	!binary "data/2016_sprites.raw"

; Constants: raster split positions
rstr1p		= $00
rstr2p		= $18


; Labels
rn		= $50
sync		= $51
rt_store_1	= $52
irq_store_1	= $53

cos_at_1	= $54

cos_at_2	= $55
cos_speed_2	= $fd	; constant
cos_offset_2	= $07	; constant
cos_at_3	= $56
cos_speed_3	= $02	; constant
cos_offset_3	= $f5	; constant

spindle_flag	= $57

scroll_x	= $58
scroll_x_buffer	= $59

buffer_cnt	= $5a

cos_at_4	= $5b	; sprite X
cos_speed_4	= $03	; constant
cos_offset_4	= $fd	; constant

cos_at_5	= $5c
cos_speed_5	= $ff	; constant
cos_offset_5	= $1a	; constant

cos_at_6	= $5d
cos_speed_6	= $fc	; constant
cos_offset_6	= $1c	; constant

cos_at_7	= $5e	; sprite Y
cos_speed_7	= $fd	; constant
cos_offset_7	= $3a	; constant

cos_at_8	= $5f	; logo
cos_speed_8	= $ff

split_buffer	= $0300
scroll_line	= $e258

; Add a BASIC startline
		* = $0801
		!word entry-2
		!byte $00,$00,$9e
		!text "2066"
		!byte $00,$00,$00


; Entry point at $0812
		* = $0812
entry		sei

; Whoops... this was left in for the release code so it stays...
		ldx #$00
test		txa
		sta split_buffer,x
		inx
		bne test

		lda #$00
		sta $d020
		sta $d021
		lda #$0b
		sta $d011

; Clear zero page workspace
		ldx #$50
		lda #$00
nuke_zp		sta $00,x
		inx
		bne nuke_zp

; Render blind effect/reset buffer RAM
		ldy #$3f
blind_master	sty irq_store_1
		ldx #$00
blind_loop	lda bar_seqs,y
		sta $4000,x
		sta $4100,x
		iny
		inx
		txa
		and #$07
		bne bl_no_nudge
		tya
		sec
		sbc #$07
		tay
bl_no_nudge	cpx #$00
		bne blind_loop

		inc blind_loop+$05
		inc blind_loop+$05
		inc blind_loop+$08
		inc blind_loop+$08
		ldy irq_store_1
		dey
		cpy #$ff
		bne blind_master

; Construct the dissolved fonts
		lda #$ee
		sta irq_store_1
font_copy_1	lda char_set+$000,x
		and irq_store_1
		sta char_set+$200,x
		lda char_set+$100,x
		and irq_store_1
		sta char_set+$300,x
		lda irq_store_1
		asl
		adc #$00
		sta irq_store_1
		inx
		bne font_copy_1

		lda irq_store_1
		asl
		adc #$00
		sta irq_store_1

font_copy_2	lda char_set+$200,x
		and irq_store_1
		sta char_set+$400,x
		lda char_set+$300,x
		and irq_store_1
		sta char_set+$500,x
		lda irq_store_1
		asl
		adc #$00
		sta irq_store_1
		inx
		bne font_copy_2

		lda irq_store_1
		asl
		adc #$00
		sta irq_store_1

font_copy_3	lda char_set+$400,x
		and irq_store_1
		sta char_set+$600,x
		lda char_set+$500,x
		and irq_store_1
		sta char_set+$700,x
		lda irq_store_1
		asl
		adc #$00
		sta irq_store_1
		inx
		bne font_copy_3

; Initialise the screen
		ldx #$00
		txa
screen_clear	sta $0400,x
		sta $0500,x
		sta $0600,x
		sta $d800,x
		sta $d900,x
		sta $da00,x
		sta $dae8,x
		inx
		bne screen_clear

; Clear the top video bank ($d000 to $feff)
		lda #$34
		sta $01

		lda #$00
		ldx #$00
bank_4_nuke	sta $d000,x
		inx
		bne bank_4_nuke
		ldy bank_4_nuke+$02
		iny
		sty bank_4_nuke+$02
		cpy #$ff
		bne bank_4_nuke-$02

; Copy the sprite data (wedging it into smaller spaces)
		ldx #$00
sprite_copy	lda sprite_data+$000,x
		sta $d700,x
		lda sprite_data+$100,x
		sta $db00,x
		lda #$00
		sta sprite_data+$000,x
		sta sprite_data+$100,x
		inx
		bne sprite_copy


; Set up the various screens for the logo
		ldx #$00
logo_draw

!set line_cnt=$00
!do {
		lda logo_data+(line_cnt*$0e),x
		sta $cc00+$07+(line_cnt*$28),x
		sta $d400+$08+(line_cnt*$28),x
		sta $d800+$09+(line_cnt*$28),x
		sta $dc00+$0a+(line_cnt*$28),x
		sta $e000+$0b+(line_cnt*$28),x
		sta $e400+$0c+(line_cnt*$28),x
		sta $e800+$0d+(line_cnt*$28),x
		sta $ec00+$0e+(line_cnt*$28),x
		sta $f000+$0f+(line_cnt*$28),x
		sta $f400+$10+(line_cnt*$28),x
		sta $f800+$11+(line_cnt*$28),x
		sta $fc00+$12+(line_cnt*$28),x

		!set line_cnt=line_cnt+$01
} until line_cnt=$0e

		inx
		cpx #$0e
		beq *+$05
		jmp logo_draw

; Modify the logo to get two dithered versions
		ldx #$00
		lda #$55
		sta irq_store_1
logo_render_1	lda $c800,x
		and irq_store_1
		sta $d000,x
		lda $c900,x
		and irq_store_1
		sta $d100,x
		lda $ca00,x
		and irq_store_1
		sta $d200,x
		lda $cb00,x
		and irq_store_1
		sta $d300,x
		lda irq_store_1
		eor #$ff
		sta irq_store_1
		inx
		bne logo_render_1

		ldx #$00
		lda #$aa
		sta irq_store_1
logo_render_2	lda $c800,x
		and irq_store_1
		sta $c800,x
		lda $c900,x
		and irq_store_1
		sta $c900,x
		lda $ca00,x
		and irq_store_1
		sta $ca00,x
		lda $cb00,x
		and irq_store_1
		sta $cb00,x
		lda irq_store_1
		eor #$ff
		sta irq_store_1
		inx
		bne logo_render_2

; Set things up for a raster interrupt
		lda #$35
		sta $01

		lda #<nmi
		sta $fffa
		lda #>nmi
		sta $fffb

		lda #<int
		sta $fffe
		lda #>int
		sta $ffff

		lda #$7f
		sta $dc0d
		sta $dd0d

		lda $dc0d
		lda $dd0d

		lda #rstr1p
		sta $d012

		lda #$1b
		sta $d011
		lda #$01
		sta $d019
		sta $d01a

; Zero the bank 0 ghostbyte (not needed in the end!) and init some variables
		lda #$00
		sta $3fff
		sta buffer_cnt

		lda #$01
		sta rn

; Reset the scroller
		jsr reset

; Init music
		jsr music+$00

; Set colours
		lda #$0f
		sta $d020
		sta $d021

		cli

; Render large bar 1
		ldy #$32
		jsr sync_wait_long

		lda #$10
		sta cos_at_1
		ldy #$00
render_main_1a	sty rt_store_1

		ldx cos_at_1
		ldy bar_cosinus,x

		ldx #$00
render_loop_1a	lda large_bar_blue,x
rl_write_1a	sta $4000,y
		iny
		inx
		cpx #$1e
		bne render_loop_1a

		inc rl_write_1a+$02
		inc cos_at_1

		ldy rt_store_1
		iny
		cpy #$80
		bne render_main_1a

; Render large bar 3
		ldy #$32
		jsr sync_wait_long

		lda #$20
		sta cos_at_1
		ldy #$00
render_main_2a	sty rt_store_1

		ldx cos_at_1
		ldy bar_cosinus,x

		ldx #$00
render_loop_2a	lda large_bar_mix,x
rl_write_2a	sta $4000,y
		iny
		inx
		cpx #$1e
		bne render_loop_2a

		inc rl_write_2a+$02
		inc cos_at_1

		ldy rt_store_1
		iny
		cpy #$80
		bne render_main_2a

; Render large bar 5
		ldy #$32
		jsr sync_wait_long

		lda #$30
		sta cos_at_1
		ldy #$00
render_main_3a	sty rt_store_1

		ldx cos_at_1
		ldy bar_cosinus,x

		ldx #$00
render_loop_3a	lda large_bar_brown,x
rl_write_3a	sta $4000,y
		iny
		inx
		cpx #$1e
		bne render_loop_3a

		inc rl_write_3a+$02
		inc cos_at_1

		ldy rt_store_1
		iny
		cpy #$80
		bne render_main_3a

; Render large bar 2
		ldy #$32
		jsr sync_wait_long

		lda #$15
		sta cos_at_1
		ldy #$00
render_main_1b	sty rt_store_1

		ldx cos_at_1
		ldy bar_cosinus,x

		ldx #$00
render_loop_1b	lda large_bar_blue,x
rl_write_1b	sta $4000,y
		iny
		inx
		cpx #$1e
		bne render_loop_1b

		inc rl_write_1b+$02
		inc cos_at_1

		ldy rt_store_1
		iny
		cpy #$80
		bne render_main_1b

; Render large bar 4
		ldy #$32
		jsr sync_wait_long

		lda #$25
		sta cos_at_1
		ldy #$00
render_main_2b	sty rt_store_1

		ldx cos_at_1
		ldy bar_cosinus,x

		ldx #$00
render_loop_2b	lda large_bar_mix,x
rl_write_2b	sta $4000,y
		iny
		inx
		cpx #$1e
		bne render_loop_2b

		inc rl_write_2b+$02
		inc cos_at_1

		ldy rt_store_1
		iny
		cpy #$80
		bne render_main_2b

; Render large bar 6
		ldy #$32
		jsr sync_wait_long

		lda #$35
		sta cos_at_1
		ldy #$00
render_main_3b	sty rt_store_1

		ldx cos_at_1
		ldy bar_cosinus,x

		ldx #$00
render_loop_3b	lda large_bar_brown,x
rl_write_3b	sta $4000,y
		iny
		inx
		cpx #$1e
		bne render_loop_3b

		inc rl_write_3b+$02
		inc cos_at_1

		ldy rt_store_1
		iny
		cpy #$80
		bne render_main_3b

; Enable the spindle bars
		ldy #$64
		jsr sync_wait_long

		lda #$01
		sta spindle_flag

; All done at runtime, so into an infinite loop
		jmp *


; IRQ interrupt
int		pha
		txa
		pha
		tya
		pha

		lda $d019
		and #$01
		sta $d019
		bne ya
		jmp ea31

ya		lda rn
		cmp #$02
		bne *+$05
		jmp rout2


; Raster split 1 - called only once
rout1		lda #$02
		sta rn
		lda #rstr2p
		sta $d012

		jmp ea31


		* = ((*/$100)+1)*$100	; start at next page boundary

; Raster split 2
rout2		nop
		nop
		nop
		nop
		nop
		bit $ea

		lda $d012
		cmp #rstr2p+$01
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		nop
		nop
		lda $d012
		cmp #rstr2p+$02
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea
		lda $d012
		cmp #rstr2p+$03
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea
		lda $d012
		cmp #rstr2p+$04
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea
		lda $d012
		cmp #rstr2p+$05
		bne *+$02
;		sta $d020

		ldx #$0a
		dex
		bne *-$01
		bit $ea
		lda $d012
		cmp #rstr2p+$06
		bne *+$02
;		sta $d020

		ldy #$06
		dey
		bne *-$01

; Video registers for the logo
logo_d016	lda #$08
		sta $d016
logo_d018	lda #$32
		sta $d018
		lda #$c4
		sta $dd00
		nop
		nop
		nop

; Upper border splits
		ldx #$00
splitter_1	nop
		nop
		nop
		nop
		nop
		lda split_buffer,x
		sta $d020
split_read_1a	lda $4000,x
		sta split_buffer,x
		ldy #$04
		dey
		bne *-$01
		nop
		inx
		lda #$0f
		sta $d020
		cpx #$14
		bne splitter_1

; First splitter for the screen - logo area
splitter_2	ldy split_buffer,x
		sty $d021
split_read_2a	lda $4000,x
		sta split_buffer,x
		inx

		lda split_buffer,x
		sta $d021
split_read_2b	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		nop
		inx

		lda split_buffer,x
		sta $d021
split_read_2c	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		nop
		inx

		lda split_buffer,x
		sta $d021
split_read_2d	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		nop
		inx

		lda split_buffer,x
		sta $d021
split_read_2e	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		nop
		inx

		lda split_buffer,x
		sta $d021
split_read_2f	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		nop
		inx

		lda split_buffer,x
		sta $d021
split_read_2g	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		nop
		inx

		lda split_buffer,x
		sta $d021
split_read_2h	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx
		cpx #$84
		beq *+$05
		jmp splitter_2

; Char line before the scroller
splitter_3	ldy split_buffer,x
		sty $d021
split_read_3a	lda $4000,x
		sta split_buffer,x
		inx

		lda split_buffer,x
		sta $d021
split_read_3b	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_3c	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_3d	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_3e	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_3f	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_3g	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_3h	lda $4000,x
		sta split_buffer,x
		ldy #$03
		dey
		bne *-$01
		inx

; Set up video registers for the scroller
		lda #$80
		sta $d018
		lda scroll_x_buffer
		sta $d016
		nop
		nop
		nop
		nop

; Scroller area
splitter_4	ldy split_buffer,x
		sty $d021
split_read_4a	lda $4000,x
		sta split_buffer,x
		inx

		lda split_buffer,x
		sta $d021
split_read_4b	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_4c	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_4d	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_4e	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_4f	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_4g	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		bit $ea
		inx

		lda split_buffer,x
		sta $d021
split_read_4h	lda $4000,x
		sta split_buffer,x
		ldy #$07
		dey
		bne *-$01
		inx

; Set video registers for the sprites
		lda #$88
		sta $d018
		bit $ea
		nop
		nop

; Badline before the sprite area
splitter_5	lda split_buffer,x
		sta $d021
split_read_5a	lda $4000,x
		sta split_buffer,x
		inx

; Sprite area - starts at scanline $95
splitter_6

!set line_cnt=$95
!do {
		lda split_buffer+line_cnt
		sta $d021
		lda $d012
		and #$07
		ora #$18
		sta $d011
		lda $4000+line_cnt
		sta split_buffer+line_cnt

		!set line_cnt=line_cnt+$01
}until line_cnt=$e2-8

		lda #$1b
		sta $d011

		ldy #$02
		dey
		bne *-$01
		nop
		nop

		ldx #$e2-8

; Final couple of scanlines before the lower border
		lda split_buffer,x
		sta $d021
split_read_7g	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		nop
		inx

		lda split_buffer,x
		sta $d021
split_read_7h	lda $4000,x
		sta split_buffer,x
		ldy #$08
		dey
		bne *-$01
		inx

		ldy #$03
		dey
		bne *-$01

; Lower border splits
splitter_8	nop
		nop
		nop
		nop
		nop
		lda split_buffer,x
		sta $d020
split_read_8a	lda $4000,x
		sta split_buffer,x
		ldy #$04
		dey
		bne *-$01
		nop
		inx
		lda #$0f
		sta $d020
		cpx #$00
		bne splitter_8

		lda #$08
		sta $d016

; Draw the spindle bars
		lda spindle_flag
		bne *+$05
		jmp spindle_skip

		lda cos_at_2
		clc
		adc #cos_speed_2
		sta cos_at_2
		tax
		lda cos_at_3
		clc
		adc #cos_speed_3
		sta cos_at_3
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		sty irq_store_1
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$02
		sta split_buffer+$01,y
		lda #$0a
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$07
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$07
		sta split_buffer+$06,y
		lda #$0f
		sta split_buffer+$07,y
		lda #$0a
		sta split_buffer+$08,y
		lda #$02
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

		txa
		clc
		adc #cos_offset_2
		tax
		lda irq_store_1
		clc
		adc #cos_offset_3
		sta irq_store_1
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$02
		sta split_buffer+$01,y
		lda #$0e
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$07
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$07
		sta split_buffer+$06,y
		lda #$0f
		sta split_buffer+$07,y
		lda #$0a
		sta split_buffer+$08,y
		lda #$02
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

		txa
		clc
		adc #cos_offset_2
		tax
		lda irq_store_1
		clc
		adc #cos_offset_3
		sta irq_store_1
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$02
		sta split_buffer+$01,y
		lda #$0e
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$07
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$07
		sta split_buffer+$06,y
		lda #$03
		sta split_buffer+$07,y
		lda #$0a
		sta split_buffer+$08,y
		lda #$02
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

		txa
		clc
		adc #cos_offset_2
		tax
		lda irq_store_1
		clc
		adc #cos_offset_3
		sta irq_store_1
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$02
		sta split_buffer+$01,y
		lda #$0e
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$0d
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$07
		sta split_buffer+$06,y
		lda #$03
		sta split_buffer+$07,y
		lda #$0a
		sta split_buffer+$08,y
		lda #$02
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

		txa
		clc
		adc #cos_offset_2
		tax
		lda irq_store_1
		clc
		adc #cos_offset_3
		sta irq_store_1
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$02
		sta split_buffer+$01,y
		lda #$0e
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$0d
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$07
		sta split_buffer+$06,y
		lda #$03
		sta split_buffer+$07,y
		lda #$0a
		sta split_buffer+$08,y
		lda #$0b
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

		txa
		clc
		adc #cos_offset_2
		tax
		lda irq_store_1
		clc
		adc #cos_offset_3
		sta irq_store_1
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$02
		sta split_buffer+$01,y
		lda #$0e
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$0d
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$0d
		sta split_buffer+$06,y
		lda #$03
		sta split_buffer+$07,y
		lda #$0a
		sta split_buffer+$08,y
		lda #$0b
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

		txa
		clc
		adc #cos_offset_2
		tax
		lda irq_store_1
		clc
		adc #cos_offset_3
		sta irq_store_1
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$0b
		sta split_buffer+$01,y
		lda #$0e
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$0d
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$0d
		sta split_buffer+$06,y
		lda #$03
		sta split_buffer+$07,y
		lda #$0a
		sta split_buffer+$08,y
		lda #$0b
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

		txa
		clc
		adc #cos_offset_2
		tax
		lda irq_store_1
		clc
		adc #cos_offset_3
		sta irq_store_1
		tay
		lda spindle_cosinus,x
		clc
		adc spindle_cosinus,y
		tay
		lda #$00
		sta split_buffer+$00,y
		lda #$0b
		sta split_buffer+$01,y
		lda #$0e
		sta split_buffer+$02,y
		lda #$0f
		sta split_buffer+$03,y
		lda #$0d
		sta split_buffer+$04,y
		lda #$01
		sta split_buffer+$05,y
		lda #$0d
		sta split_buffer+$06,y
		lda #$03
		sta split_buffer+$07,y
		lda #$0e
		sta split_buffer+$08,y
		lda #$0b
		sta split_buffer+$09,y
		lda #$00
		sta split_buffer+$0a,y

spindle_skip

; Get the copiers ready for the next frame (self mod code)
		lda buffer_cnt
		clc
		adc #$40
		sta split_read_1a+$02

		sta split_read_2a+$02
		sta split_read_2b+$02
		sta split_read_2c+$02
		sta split_read_2d+$02
		sta split_read_2e+$02
		sta split_read_2f+$02
		sta split_read_2g+$02
		sta split_read_2h+$02

		sta split_read_3a+$02
		sta split_read_3b+$02
		sta split_read_3c+$02
		sta split_read_3d+$02
		sta split_read_3e+$02
		sta split_read_3f+$02
		sta split_read_3g+$02
		sta split_read_3h+$02

		sta split_read_4a+$02
		sta split_read_4b+$02
		sta split_read_4c+$02
		sta split_read_4d+$02
		sta split_read_4e+$02
		sta split_read_4f+$02
		sta split_read_4g+$02
		sta split_read_4h+$02

		sta split_read_5a+$02

!set line_cnt=$00
!do {
		sta splitter_6+$12+(line_cnt*$16)

		!set line_cnt=line_cnt+$01
} until line_cnt=$45

		sta split_read_7g+$02
		sta split_read_7h+$02

		sta split_read_8a+$02

		lda buffer_cnt
		clc
		adc #$01
		and #$7f
		sta buffer_cnt


; Update the scrolling message
		ldx scroll_x
		inx
		cpx #$04
		beq *+$05
		jmp scr_xb

		lda scroll_line+$02
		sta scroll_line+$01
		lda scroll_line+$03
		clc
		adc #$40
		sta scroll_line+$02

		lda scroll_line+$04
		sta scroll_line+$03
		lda scroll_line+$05
		clc
		adc #$40
		sta scroll_line+$04
		lda scroll_line+$06
		sta scroll_line+$05
		lda scroll_line+$07
		clc
		adc #$40
		sta scroll_line+$06
		lda scroll_line+$08
		sta scroll_line+$07
		lda scroll_line+$09
		sta scroll_line+$08

		lda scroll_line+$0a
		sta scroll_line+$09
		lda scroll_line+$0b
		sta scroll_line+$0a
		lda scroll_line+$0c
		sta scroll_line+$0b
		lda scroll_line+$0d
		sta scroll_line+$0c
		lda scroll_line+$0e
		sta scroll_line+$0d
		lda scroll_line+$0f
		sta scroll_line+$0e
		lda scroll_line+$10
		sta scroll_line+$0f
		lda scroll_line+$11
		sta scroll_line+$10

		lda scroll_line+$12
		sta scroll_line+$11
		lda scroll_line+$13
		sta scroll_line+$12
		lda scroll_line+$14
		sta scroll_line+$13
		lda scroll_line+$15
		sta scroll_line+$14
		lda scroll_line+$16
		sta scroll_line+$15
		lda scroll_line+$17
		sta scroll_line+$16
		lda scroll_line+$18
		sta scroll_line+$17
		lda scroll_line+$19
		sta scroll_line+$18

		lda scroll_line+$1a
		sta scroll_line+$19
		lda scroll_line+$1b
		sta scroll_line+$1a
		lda scroll_line+$1c
		sta scroll_line+$1b
		lda scroll_line+$1d
		sta scroll_line+$1c
		lda scroll_line+$1e
		sta scroll_line+$1d
		lda scroll_line+$1f
		sta scroll_line+$1e
		lda scroll_line+$20
		sec
		sbc #$40
		sta scroll_line+$1f
		lda scroll_line+$21
		sta scroll_line+$20

		lda scroll_line+$22
		sec
		sbc #$40
		sta scroll_line+$21
		lda scroll_line+$23
		sta scroll_line+$22
		lda scroll_line+$24
		sec
		sbc #$40
		sta scroll_line+$23
		lda scroll_line+$25
		sta scroll_line+$24


mread		lda scroll_text
		bne okay
		jsr reset
		jmp mread

okay		ora #$c0
		sta scroll_line+$25

		inc mread+$01
		bne *+$05
		inc mread+$02

		ldx #$00
scr_xb		stx scroll_x

		txa
		and #$03
		asl
		eor #$0f
		sta scroll_x_buffer

; Update the sprite X positions - pass 1
		lda cos_at_4
		clc
		adc #cos_speed_4
		sta cos_at_4
		tax
		lda cos_at_5
		clc
		adc #cos_speed_5
		sta cos_at_5
		tay
		lda spr_x_cosinus,x
		clc
		adc spr_x_cosinus,y
		sta sprite_x+$00

		txa
		clc
		adc #cos_offset_4
		tax
		tya
		clc
		adc #cos_offset_5
		tay
		lda spr_x_cosinus,x
		clc
		adc spr_x_cosinus,y
		sta sprite_x+$01

		txa
		clc
		adc #cos_offset_4
		tax
		tya
		clc
		adc #cos_offset_5
		tay
		lda spr_x_cosinus,x
		clc
		adc spr_x_cosinus,y
		sta sprite_x+$02

		txa
		clc
		adc #cos_offset_4
		tax
		tya
		clc
		adc #cos_offset_5
		tay
		lda spr_x_cosinus,x
		clc
		adc spr_x_cosinus,y
		sta sprite_x+$03

; Update the sprite X positions - pass 2
		lda #$00
		sta sprite_msb

		lda cos_at_6
		clc
		adc #cos_speed_6
		sta cos_at_6
		tax
		lda spr_x_cosinus,x
		clc
		adc sprite_x+$00
		bcc msb_skip_1
		tay
		lda sprite_msb
		ora #$04
		sta sprite_msb
		tya
msb_skip_1	sta sprite_x+$00

		txa
		clc
		adc #cos_offset_6
		tax
		lda spr_x_cosinus,x
		clc
		adc sprite_x+$01
		adc #$10
		bcc msb_skip_2
		tay
		lda sprite_msb
		ora #$08
		sta sprite_msb
		tya
msb_skip_2	sta sprite_x+$01

		txa
		clc
		adc #cos_offset_6
		tax
		lda spr_x_cosinus,x
		clc
		adc sprite_x+$02
		adc #$20
		bcc msb_skip_3
		tay
		lda sprite_msb
		ora #$10
		sta sprite_msb
		tya
msb_skip_3	sta sprite_x+$02

		txa
		clc
		adc #cos_offset_6
		tax
		lda spr_x_cosinus,x
		clc
		adc sprite_x+$03
		adc #$30
		bcc msb_skip_4
		tay
		lda sprite_msb
		ora #$20
		sta sprite_msb
		tya
msb_skip_4	sta sprite_x+$03

; Update the sprite Y positions
		lda cos_at_7
		clc
		adc #cos_speed_7
		sta cos_at_7
		tay
		lda spr_y_cosinus,y
		sta sprite_y+$00
		tya
		clc
		adc #cos_offset_7
		tay
		lda spr_y_cosinus,y
		sta sprite_y+$01
		tya
		clc
		adc #cos_offset_7
		tay
		lda spr_y_cosinus,y
		sta sprite_y+$02

		tya
		clc
		adc #cos_offset_7
		tay
		lda spr_y_cosinus,y
		sta sprite_y+$03

; Calculate the sprite data pointers
		lda sprite_x+$00
		clc
		adc sprite_y+$00
		and #$01
		ora #$5c
		sta sprite_dp+$00

		lda sprite_x+$01
		clc
		adc sprite_y+$01
		and #$01
		ora #$5e
		sta sprite_dp+$01

		lda sprite_x+$02
		clc
		adc sprite_y+$02
		and #$01
		ora #$6c
		sta sprite_dp+$02

		lda sprite_x+$03
		clc
		adc sprite_y+$03
		and #$01
		ora #$6e
		sta sprite_dp+$03

; Set up the sprites
		lda #$3c
		sta $d015

		ldx #$00
		ldy #$00
sprite_set	lda sprite_x,x
		sta $d004,y
		lda sprite_y,x
		sta $d005,y
		lda sprite_dp,x
		sta $e3fa,x
		lda #$00
		sta $d029,x
		iny
		iny
		inx
		cpx #$04
		bne sprite_set

		lda sprite_msb
		sta $d010

; Update the logo
		lda cos_at_8
		clc
		adc #cos_speed_8
		sta cos_at_8
		tax
		lda logo_cosinus,x
		and #$07
		eor #$08
		sta logo_d016+$01

		lda logo_cosinus,x
		and #$01
		asl
		sta irq_store_1

		lda logo_cosinus,x
		lsr
		lsr
		lsr
		tax
		lda logo_d018_trans,x
		clc
		adc irq_store_1
		sta logo_d018+$01

; Play the music
		jsr music+$03

; Get ready for the next frame
		lda #rstr2p
		sta $d012

; Leave a marker for the runtime
		lda #$01
		sta sync


; Exit the interrupt
ea31		pla
		tay
		pla
		tax
		pla
nmi		rti


; Reset the scroller
reset		lda #<scroll_text
		sta mread+$01
		lda #>scroll_text
		sta mread+$02
		rts

; Wait for a cue from the interrupt
sync_wait	lda #$00
		sta sync
sw_loop		cmp sync
		beq sw_loop
		rts

sync_wait_long	jsr sync_wait
		dey
		bne sync_wait_long
		rts


		* = ((*/$100)+1)*$100	; start at next page boundary

; Cosinus table for the logo
logo_cosinus	!byte $5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f
		!byte $5f,$5e,$5e,$5e,$5d,$5d,$5d,$5c
		!byte $5c,$5b,$5b,$5a,$5a,$59,$59,$58
		!byte $57,$57,$56,$55,$55,$54,$53,$52
		!byte $51,$51,$50,$4f,$4e,$4d,$4c,$4b
		!byte $4a,$49,$48,$47,$46,$45,$44,$43
		!byte $42,$41,$40,$3e,$3d,$3c,$3b,$3a
		!byte $39,$38,$36,$35,$34,$33,$32,$31

		!byte $2f,$2e,$2d,$2c,$2b,$2a,$28,$27
		!byte $26,$25,$24,$23,$21,$20,$1f,$1e
		!byte $1d,$1c,$1b,$1a,$19,$18,$17,$16
		!byte $15,$14,$13,$12,$11,$10,$0f,$0e
		!byte $0d,$0d,$0c,$0b,$0a,$0a,$09,$08
		!byte $08,$07,$06,$06,$05,$05,$04,$04
		!byte $03,$03,$02,$02,$02,$01,$01,$01
		!byte $00,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$01,$01,$01,$02,$02,$02,$03
		!byte $03,$04,$04,$05,$05,$06,$06,$07
		!byte $08,$08,$09,$0a,$0b,$0b,$0c,$0d
		!byte $0e,$0f,$0f,$10,$11,$12,$13,$14
		!byte $15,$16,$17,$18,$19,$1a,$1b,$1c
		!byte $1d,$1e,$20,$21,$22,$23,$24,$25
		!byte $26,$28,$29,$2a,$2b,$2c,$2d,$2f

		!byte $30,$31,$32,$33,$34,$36,$37,$38
		!byte $39,$3a,$3b,$3d,$3e,$3f,$40,$41
		!byte $42,$43,$44,$45,$46,$47,$48,$49
		!byte $4a,$4b,$4c,$4d,$4e,$4f,$50,$51
		!byte $52,$52,$53,$54,$55,$56,$56,$57
		!byte $58,$58,$59,$59,$5a,$5b,$5b,$5c
		!byte $5c,$5c,$5d,$5d,$5e,$5e,$5e,$5e
		!byte $5f,$5f,$5f,$5f,$5f,$5f,$5f,$5f

; Cosinus tables for the sprites
spr_x_cosinus	!byte $4f,$4f,$4f,$4f,$4f,$4f,$4f,$4f
		!byte $4f,$4f,$4e,$4e,$4e,$4d,$4d,$4d
		!byte $4c,$4c,$4c,$4b,$4b,$4a,$4a,$49
		!byte $49,$48,$48,$47,$46,$46,$45,$44
		!byte $44,$43,$42,$42,$41,$40,$3f,$3e
		!byte $3e,$3d,$3c,$3b,$3a,$39,$39,$38
		!byte $37,$36,$35,$34,$33,$32,$31,$30
		!byte $2f,$2e,$2d,$2c,$2b,$2a,$29,$28

		!byte $27,$26,$25,$24,$24,$23,$22,$21
		!byte $20,$1f,$1e,$1d,$1c,$1b,$1a,$19
		!byte $18,$17,$16,$15,$15,$14,$13,$12
		!byte $11,$10,$10,$0f,$0e,$0d,$0d,$0c
		!byte $0b,$0a,$0a,$09,$09,$08,$07,$07
		!byte $06,$06,$05,$05,$04,$04,$03,$03
		!byte $02,$02,$02,$01,$01,$01,$01,$00
		!byte $00,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $00,$01,$01,$01,$01,$02,$02,$02
		!byte $03,$03,$03,$04,$04,$05,$05,$06
		!byte $06,$07,$07,$08,$09,$09,$0a,$0b
		!byte $0b,$0c,$0d,$0e,$0e,$0f,$10,$11
		!byte $11,$12,$13,$14,$15,$16,$17,$17
		!byte $18,$19,$1a,$1b,$1c,$1d,$1e,$1f
		!byte $20,$21,$22,$23,$24,$25,$26,$27

		!byte $28,$29,$2a,$2b,$2c,$2d,$2e,$2f
		!byte $30,$30,$31,$32,$33,$34,$35,$36
		!byte $37,$38,$39,$3a,$3b,$3b,$3c,$3d
		!byte $3e,$3f,$40,$40,$41,$42,$43,$43
		!byte $44,$45,$45,$46,$47,$47,$48,$48
		!byte $49,$49,$4a,$4a,$4b,$4b,$4c,$4c
		!byte $4d,$4d,$4d,$4e,$4e,$4e,$4e,$4f
		!byte $4f,$4f,$4f,$4f,$4f,$4f,$4f,$4f

spr_y_cosinus	!byte $e2,$e2,$e2,$e2,$e2,$e2,$e2,$e2
		!byte $e2,$e2,$e2,$e2,$e2,$e1,$e1,$e1
		!byte $e1,$e1,$e0,$e0,$e0,$e0,$df,$df
		!byte $df,$de,$de,$de,$dd,$dd,$dd,$dc
		!byte $dc,$db,$db,$db,$da,$da,$d9,$d9
		!byte $d8,$d8,$d8,$d7,$d7,$d6,$d6,$d5
		!byte $d5,$d4,$d4,$d3,$d3,$d2,$d1,$d1
		!byte $d0,$d0,$cf,$cf,$ce,$ce,$cd,$cd

		!byte $cc,$cb,$cb,$ca,$ca,$c9,$c9,$c8
		!byte $c8,$c7,$c6,$c6,$c5,$c5,$c4,$c4
		!byte $c3,$c3,$c2,$c2,$c1,$c1,$c0,$c0
		!byte $bf,$bf,$bf,$be,$be,$bd,$bd,$bc
		!byte $bc,$bc,$bb,$bb,$bb,$ba,$ba,$ba
		!byte $b9,$b9,$b9,$b8,$b8,$b8,$b8,$b7
		!byte $b7,$b7,$b7,$b7,$b6,$b6,$b6,$b6
		!byte $b6,$b6,$b6,$b6,$b6,$b6,$b6,$b6

		!byte $b6,$b6,$b6,$b6,$b6,$b6,$b6,$b6
		!byte $b6,$b6,$b6,$b6,$b6,$b7,$b7,$b7
		!byte $b7,$b7,$b8,$b8,$b8,$b8,$b9,$b9
		!byte $b9,$ba,$ba,$ba,$bb,$bb,$bb,$bc
		!byte $bc,$bd,$bd,$bd,$be,$be,$bf,$bf
		!byte $c0,$c0,$c1,$c1,$c1,$c2,$c2,$c3
		!byte $c3,$c4,$c5,$c5,$c6,$c6,$c7,$c7
		!byte $c8,$c8,$c9,$c9,$ca,$ca,$cb,$cc

		!byte $cc,$cd,$cd,$ce,$ce,$cf,$cf,$d0
		!byte $d1,$d1,$d2,$d2,$d3,$d3,$d4,$d4
		!byte $d5,$d5,$d6,$d6,$d7,$d7,$d8,$d8
		!byte $d9,$d9,$da,$da,$da,$db,$db,$dc
		!byte $dc,$dc,$dd,$dd,$dd,$de,$de,$de
		!byte $df,$df,$df,$e0,$e0,$e0,$e0,$e1
		!byte $e1,$e1,$e1,$e1,$e2,$e2,$e2,$e2
		!byte $e2,$e2,$e2,$e2,$e2,$e2,$e2,$e2

; Cosinus tables for the small and then large raster bars
spindle_cosinus	!byte $7b,$7b,$7b,$7b,$7b,$7b,$7b,$7b
		!byte $7a,$7a,$7a,$79,$79,$78,$78,$77
		!byte $77,$76,$76,$75,$74,$73,$73,$72
		!byte $71,$70,$6f,$6e,$6d,$6c,$6b,$6a
		!byte $69,$68,$67,$66,$65,$64,$62,$61
		!byte $60,$5f,$5d,$5c,$5b,$59,$58,$57
		!byte $55,$54,$52,$51,$4f,$4e,$4c,$4b
		!byte $4a,$48,$46,$45,$43,$42,$40,$3f

		!byte $3d,$3c,$3a,$39,$37,$36,$34,$33
		!byte $31,$30,$2e,$2d,$2b,$2a,$28,$27
		!byte $26,$24,$23,$21,$20,$1f,$1d,$1c
		!byte $1b,$1a,$18,$17,$16,$15,$14,$13
		!byte $12,$10,$0f,$0e,$0d,$0d,$0c,$0b
		!byte $0a,$09,$08,$07,$07,$06,$05,$05
		!byte $04,$04,$03,$03,$02,$02,$01,$01
		!byte $01,$00,$00,$00,$00,$00,$00,$00

		!byte $00,$00,$00,$00,$00,$00,$00,$00
		!byte $01,$01,$01,$02,$02,$03,$03,$04
		!byte $04,$05,$06,$06,$07,$08,$08,$09
		!byte $0a,$0b,$0c,$0d,$0e,$0f,$10,$11
		!byte $12,$13,$14,$15,$16,$18,$19,$1a
		!byte $1b,$1d,$1e,$1f,$21,$22,$23,$25
		!byte $26,$27,$29,$2a,$2c,$2d,$2f,$30
		!byte $32,$33,$35,$36,$38,$39,$3b,$3c

		!byte $3e,$3f,$41,$42,$44,$45,$47,$48
		!byte $4a,$4b,$4d,$4e,$50,$51,$53,$54
		!byte $56,$57,$58,$5a,$5b,$5c,$5e,$5f
		!byte $60,$62,$63,$64,$65,$66,$67,$69
		!byte $6a,$6b,$6c,$6d,$6e,$6f,$70,$70
		!byte $71,$72,$73,$74,$74,$75,$76,$76
		!byte $77,$77,$78,$79,$79,$79,$7a,$7a
		!byte $7a,$7b,$7b,$7b,$7b,$7b,$7b,$7b

bar_cosinus	!byte $e2,$e2,$e2,$e1,$e0,$df,$de,$dc
		!byte $da,$d7,$d5,$d2,$cf,$cc,$c8,$c5
		!byte $c1,$bd,$b9,$b4,$b0,$ab,$a6,$a1
		!byte $9c,$97,$91,$8c,$86,$81,$7b,$76
		!byte $70,$6a,$65,$5f,$5a,$54,$4f,$4a
		!byte $45,$3f,$3a,$36,$31,$2c,$28,$24
		!byte $20,$1c,$18,$15,$12,$0f,$0c,$0a
		!byte $08,$06,$04,$03,$01,$00,$00,$00

		!byte $00,$00,$00,$01,$02,$03,$05,$07
		!byte $09,$0b,$0e,$11,$14,$17,$1b,$1e
		!byte $22,$26,$2b,$2f,$34,$39,$3e,$43
		!byte $48,$4d,$52,$58,$5d,$63,$69,$6e
		!byte $74,$79,$7f,$84,$8a,$8f,$95,$9a
		!byte $9f,$a4,$a9,$ae,$b3,$b7,$bb,$c0
		!byte $c3,$c7,$cb,$ce,$d1,$d4,$d7,$d9
		!byte $db,$dd,$df,$e0,$e1,$e2,$e2,$e2

		!byte $e2,$e2,$e2,$e1,$e0,$df,$de,$dc
		!byte $da,$d7,$d5,$d2,$cf,$cc,$c8,$c5
		!byte $c1,$bd,$b9,$b4,$b0,$ab,$a6,$a1
		!byte $9c,$97,$91,$8c,$86,$81,$7b,$76
		!byte $70,$6a,$65,$5f,$5a,$54,$4f,$4a
		!byte $45,$3f,$3a,$36,$31,$2c,$28,$24
		!byte $20,$1c,$18,$15,$12,$0f,$0c,$0a
		!byte $08,$06,$04,$03,$01,$00,$00,$00

		!byte $00,$00,$00,$01,$02,$03,$05,$07
		!byte $09,$0b,$0e,$11,$14,$17,$1b,$1e
		!byte $22,$26,$2b,$2f,$34,$39,$3e,$43
		!byte $48,$4d,$52,$58,$5d,$63,$69,$6e
		!byte $74,$79,$7f,$84,$8a,$8f,$95,$9a
		!byte $9f,$a4,$a9,$ae,$b3,$b7,$bb,$c0
		!byte $c3,$c7,$cb,$ce,$d1,$d4,$d7,$d9
		!byte $db,$dd,$df,$e0,$e1,$e2,$e2,$e2

; Colour data for the large bars
large_bar_blue	!byte $00,$00,$06,$06,$04,$06,$04,$04
		!byte $0e,$04,$0e,$0e,$03,$0e,$03,$03
		!byte $0e,$03,$0e,$0e,$04,$0e,$04,$04
		!byte $06,$04,$06,$06,$00,$00,$00,$00

large_bar_mix	!byte $00,$00,$06,$06,$08,$06,$08,$08
		!byte $0e,$08,$0e,$0e,$0f,$0e,$0f,$0f
		!byte $0e,$0f,$0e,$0e,$08,$0e,$08,$08
		!byte $06,$08,$06,$06,$00,$00,$00,$00

large_bar_brown	!byte $00,$00,$09,$09,$08,$09,$08,$08
		!byte $0a,$08,$0a,$0a,$0f,$0a,$0f,$0f
		!byte $0a,$0f,$0a,$0a,$08,$0a,$08,$08
		!byte $09,$08,$09,$09,$00,$00,$00,$00


		* = ((*/$100)+1)*$100	; start at next page boundary

; Colour data for the blind effect
bar_seqs	!byte $0b,$08,$0c,$0a,$0f,$07,$01,$07
		!byte $0f,$0a,$0c,$08,$0b,$0b,$0b,$0b
		!byte $0b,$04,$0e,$05,$03,$0d,$01,$0d
		!byte $03,$05,$0e,$04,$0b,$0b,$0b,$0b

		!byte $0b,$08,$0c,$0a,$0f,$07,$01,$07
		!byte $0f,$0a,$0c,$08,$0b,$0b,$0b,$0b
		!byte $0b,$04,$0e,$05,$03,$0d,$01,$0d
		!byte $03,$05,$0e,$04,$0b,$0b,$0b,$0b

		!byte $0b,$08,$0c,$0a,$0f,$07,$01,$07
		!byte $0f,$0a,$0c,$08,$0b,$0b,$0b,$0b
		!byte $0b,$04,$0e,$05,$03,$0d,$01,$0d
		!byte $03,$05,$0e,$04,$0b,$0b,$0b,$0b

		!byte $0b,$08,$0c,$0a,$0f,$07,$01,$07
		!byte $0f,$0a,$0c,$08,$0b,$0b,$0b,$0b
		!byte $0b,$04,$0e,$05,$03,$0d,$01,$0d
		!byte $03,$05,$0e,$04,$0b,$0b,$0b,$0b

; Sprite positions
sprite_x	!byte $00,$00,$00,$00
sprite_msb	!byte $00
sprite_y	!byte $b6,$c6,$d6,$e6

sprite_dp	!byte $00,$00,$00,$00

; Logo screen data
logo_data	!byte $00,$00,$00,$01,$02,$03,$04
		!byte $04,$05,$06,$07,$00,$00,$00

		!byte $00,$00,$08,$09,$04,$0a,$0b
		!byte $0c,$0d,$04,$0e,$0f,$00,$00

		!byte $00,$10,$04,$11,$12,$13,$14
		!byte $15,$16,$17,$18,$04,$19,$00

		!byte $1a,$09,$1b,$1c,$09,$04,$04
		!byte $04,$04,$0e,$1d,$1e,$0e,$1f

		!byte $20,$04,$21,$09,$22,$23,$24
		!byte $25,$26,$27,$28,$29,$04,$2a

		!byte $2b,$2c,$2d,$04,$2e,$00,$00
		!byte $00,$00,$00,$00,$2f,$30,$31

		!byte $04,$32,$33,$04,$34,$00,$00
		!byte $00,$00,$00,$00,$00,$35,$04

		!byte $04,$36,$37,$04,$38,$00,$00
		!byte $00,$00,$00,$00,$00,$39,$04

		!byte $3a,$3b,$3c,$04,$3d,$00,$00
		!byte $00,$00,$00,$00,$3e,$3f,$40

		!byte $41,$04,$42,$43,$0e,$44,$45
		!byte $46,$47,$48,$49,$4a,$04,$4b

		!byte $4c,$43,$4d,$4e,$43,$04,$04
		!byte $04,$04,$22,$4f,$50,$22,$51

		!byte $00,$52,$04,$53,$54,$55,$56
		!byte $57,$58,$59,$5a,$04,$5b,$00

		!byte $00,$00,$5c,$43,$04,$5d,$5e
		!byte $5f,$60,$04,$22,$61,$00,$00

		!byte $00,$00,$00,$62,$63,$64,$04
		!byte $04,$65,$66,$67,$00,$00,$00

; Data for logo movement
logo_d018_trans	!byte $32,$52,$62,$72,$82,$92,$a2,$b2
		!byte $c2,$d2,$e2,$f2

; And finally, here comes the drivel...=
scroll_text	!scr "ahh...   i do love a good raster bar or two!"
		!scr "    "

		!scr "welcome to   --- md201607 ---   a raster-laden "
		!scr "production that was found down the back of the cosine "
		!scr "sofa and hosed off for release!"
		!scr "        "

		!scr "the code is based on something i've had in the "
		!scr $22,"parts box",$22," for close to a decade (although "
		!scr "this final reworking was literally hammered together "
		!scr "over the last eighteen hours) and was inspired by a "
		!scr "couple of classic old school demos, in particular "
		!scr "the second part of upfront's toaster and the intro "
		!scr "to new gold dream by logic."
		!scr "   "

		!scr "both of those releases seemed to be doing the "
		!scr "impossible when i first saw them and i've used most "
		!scr "of the ",$22,"cheap",$22," tricks i could think of "
		!scr "to get a similar level of movement with 256 scanlines "
		!scr "of colour splits.   "

		!scr "the logo uses multiple screens so it doesn't need to "
		!scr "be redrawn each frame, most of the bars are "
		!scr "pre-rendered and even the code to update this scroller "
		!scr "has been unrolled!"
		!scr "   "

		!scr "the upper and lower borders aren't actually open in "
		!scr "order to avoid problems with the ghostbyte in bank 3 "
		!scr "so that part of the screen is instead handled with "
		!scr "vertical colour splits and the light grey borders "
		!scr "were an only partially successful attempt to hide "
		!scr "the colour change ",$22,"sparkle",$22," present on "
		!scr "newer machines!"
		!scr "        "

		!scr "the mdeia in this part has mostly been gathering "
		!scr "virtual dust along with the previous iteration of the "
		!scr "code;  this character set was taken from aladdin on "
		!scr "the sega master system ages ago (it's my regular test "
		!scr "font) whilst the goattracker file for sack's tune is "
		!scr "dated 2001 - the atari 8-bit version was used in our "
		!scr" 2012 release greetz0rz."
		!scr "        "

		!scr "i probably haven't left myself much in the way of ram "
		!scr "this time (the buffer for the raster bars takes 32k on "
		!scr "it's own and the graphics are using most of the top "
		!scr "video bank) and, as is always the case, what little "
		!scr $22,"inspiration",$22," i had for text has deserted me, "
		!scr "so i'd better get on with dishing out the greetings "
		!scr "and winding things up...!"
		!scr "        "

		!scr "so...   cosine's raster-filled hellos (updated after "
		!scr "crackers' demo 5 since we got a few new greets there) "
		!scr "head out towards:  "

		!scr "absence, "
		!scr "abyss connection, "
		!scr "arkanix labs, "
		!scr "artstate, "
		!scr "ate bit, "
		!scr "atlantis and f4cg, "
		!scr "booze design, "
		!scr "camelot, "
		!scr "censor design, "
		!scr "chorus, "
		!scr "chrome, "
		!scr "cncd, "
		!scr "cpu, "
		!scr "crescent, "
		!scr "crest, "
		!scr "covert bitops, "
		!scr "defence force, "
		!scr "dekadence, "
		!scr "desire, "
		!scr "dac, "
		!scr "dmagic, "
		!scr "dualcrew, "
		!scr "exclusive on, "
		!scr "fairlight, "
		!scr "fire, "
		!scr "flat 3, "
		!scr "focus, "
		!scr "french touch, "
		!scr "funkscientist productions, "
		!scr "genesis project, "
		!scr "gheymaid inc., "
		!scr "hitmen, "
		!scr "hokuto force, "
		!scr "legion of doom, "
		!scr "level64, "
		!scr "maniacs of noise, "
		!scr "mayday, "
		!scr "meanteam, "
		!scr "metalvotze, "
		!scr "noname, "
		!scr "nostalgia, "
		!scr "nuance, "
		!scr "offence, "
		!scr "onslaught, "
		!scr "orb, "
		!scr "oxyron, "
		!scr "padua, "
		!scr "plush, "
		!scr "professional protection cracking service, "
		!scr "psytronik, "
		!scr "reptilia, "
		!scr "resource, "
		!scr "rgcd, "
		!scr "secure, "
		!scr "shape, "
		!scr "side b, "
		!scr "singular, "
		!scr "slash, "
		!scr "slipstream, "
		!scr "success and trc, "
		!scr "style, "
		!scr "suicyco industries, "
		!scr "taquart, "
		!scr "tempest, "
		!scr "tek, "
		!scr "triad, "
		!scr "trsi, "
		!scr "viruz, "
		!scr "vision, "
		!scr "wow, "
		!scr "wrath "
		!scr "and xenon."
		!scr "   "

		!scr "get in touch to tell me if your group should be added, "
		!scr "okay?!"
		!scr "        "

		!scr "and i think that's everything sorted...   so i'll "
		!scr "just add a quick plug the website --- cosine.org.uk --- "
		!scr "and wander off;  ta for reading this drivel and that "
		!scr "was the magic roundabout of cosine on the last day of "
		!scr "july 2016... .. .  .   ."
		!scr "            "

		!byte $00
