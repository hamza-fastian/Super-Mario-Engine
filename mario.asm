; =====================================================================
; MARIO.COM - Modules 1 to 6
; Build:  nasm -f bin mario.asm -o MARIO.COM
; Keys:   Left/Right (or A/D) move Mario, ESC quits
; =====================================================================
[BITS 16]
[ORG 100h]

; ---------------------------------------------------------------------
; CONSTANTS (Module 1)
; ---------------------------------------------------------------------
SCREEN_W        equ     320
SCREEN_H        equ     200
VIDEO_SEG       equ     0A000h
FRAME_WORDS     equ     32000           ; 64000 bytes as words

TILE_SIZE       equ     16
MAP_WIDTH       equ     60
MAP_HEIGHT      equ     12
MAP_SIZE        equ     MAP_WIDTH * MAP_HEIGHT
LEVEL_W_PX      equ     MAP_WIDTH * TILE_SIZE       ; 960
LEVEL_H_PX      equ     MAP_HEIGHT * TILE_SIZE      ; 192
VIEW_COLS       equ     21              ; 20 columns + 1 partial column

CAM_FOLLOW_X    equ     160             ; camera follows once screen_x > 160
CAM_MAX_X       equ     LEVEL_W_PX - SCREEN_W       ; 640

COL_SKY         equ     09h

SC_ESC          equ     01h
SC_A            equ     1Eh
SC_D            equ     20h
SC_LEFT         equ     4Bh
SC_RIGHT        equ     4Dh

HERO_START_X    equ     32
HERO_START_Y    equ     144
HERO_SPEED      equ     4

start:
        cli
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 0FFFEh
        sti

        ; Frame buffer = the 64 KB segment right after our own segment
        mov     ax, cs
        add     ax, 1000h
        mov     [frame_seg], ax

        ; VGA Mode 13h
        mov     ax, 0013h
        int     10h

        ; Module 2 test screen (drawn straight to video memory)
        call    ShowTestScreen
        xor     ah, ah
        int     16h

        ; Level + game state
        call    InitMap
        call    ResetLevelState

        ; Module 4 sprite demo, now drawn through the frame buffer
        call    ClearFrame
        call    DrawMap
        call    DrawSpriteDemo
        call    Present
        xor     ah, ah
        int     16h

        ; Game loop (Modules 5 and 6)
        call    InstallKeyboard
        call    GameLoop
        call    RestoreKeyboard

        mov     ax, 0003h
        int     10h
        mov     ax, 4C00h
        int     21h


; =====================================================================
; MODULE 2 - TEST SCREEN
; =====================================================================
ShowTestScreen:
        ; Sky
        mov     ax, VIDEO_SEG
        mov     es, ax
        xor     di, di
        mov     cx, 64000
        mov     al, 09h
        rep     stosb

        ; Ground
        mov     di, 176 * 320
        mov     cx, 320 * 24
        mov     al, 06h
        rep     stosb

        ; Green line on ground
        mov     di, 176 * 320
        mov     cx, 320 * 2
        mov     al, 02h
        rep     stosb

        ; 8 colour swatches
        mov     bx, 16
        mov     dx, 60

.swatch_loop:
        cmp     bx, 272
        jge     .draw_cross

        mov     bp, 40
        mov     si, dx

.swatch_row:
        mov     ax, si
        mov     cx, 320
        mul     cx
        add     ax, bx
        mov     di, ax

        push    cx
        mov     cx, 32
        mov     al, 04h

        cmp     bx, 16
        je      .do_draw
        cmp     bx, 48
        jne     .c2
        mov     al, 02h
        jmp     .do_draw
.c2:    cmp     bx, 80
        jne     .c3
        mov     al, 04h
        jmp     .do_draw
.c3:    cmp     bx, 112
        jne     .c4
        mov     al, 0Eh
        jmp     .do_draw
.c4:    cmp     bx, 144
        jne     .c5
        mov     al, 06h
        jmp     .do_draw
.c5:    cmp     bx, 176
        jne     .c6
        mov     al, 0Eh
        jmp     .do_draw
.c6:    cmp     bx, 208
        jne     .c7
        mov     al, 0Fh
        jmp     .do_draw
.c7:    mov     al, 0Eh

.do_draw:
        rep     stosb
        pop     cx

        inc     si
        dec     bp
        jnz     .swatch_row

        add     bx, 32
        jmp     .swatch_loop

.draw_cross:
        mov     di, (130 * 320) + 150
        mov     cx, 21
        mov     al, 04h
        rep     stosb

        mov     di, (120 * 320) + 160
        mov     cx, 21
        mov     al, 04h
.v_line:
        stosb
        add     di, 319
        dec     cx
        jnz     .v_line

        mov     ax, cs
        mov     es, ax
        ret


; =====================================================================
; MODULE 3 - LEVEL MAP AND TILE DRAWING
; =====================================================================

; ------------------------------------------
; InitMap - builds the original level
; ------------------------------------------
InitMap:
        push ax
        push cx
        push di
        push es

        mov ax, cs
        mov es, ax

        mov di, level_original
        xor al, al
        mov cx, MAP_SIZE
        cld
        rep stosb

        ; Ground rows 10 and 11
        mov di, level_original + 600
        mov al, 1
        mov cx, 120
        rep stosb

        ; Two pits
        mov byte [level_original+610], 0
        mov byte [level_original+611], 0
        mov byte [level_original+670], 0
        mov byte [level_original+671], 0

        mov byte [level_original+630], 0
        mov byte [level_original+631], 0
        mov byte [level_original+632], 0
        mov byte [level_original+690], 0
        mov byte [level_original+691], 0
        mov byte [level_original+692], 0

        ; First brick group
        mov byte [level_original+427], 2
        mov byte [level_original+428], 2
        mov byte [level_original+429], 2

        ; Second brick group
        mov byte [level_original+441], 2
        mov byte [level_original+442], 2
        mov byte [level_original+443], 2

        ; Three coin question blocks
        mov byte [level_original+365], 3
        mov byte [level_original+378], 3
        mov byte [level_original+386], 3

        ; Two mushroom question blocks
        mov byte [level_original+372], 4
        mov byte [level_original+400], 4

        ; First pipe - 2 tiles high
        mov byte [level_original+494], 6
        mov byte [level_original+495], 7
        mov byte [level_original+554], 8
        mov byte [level_original+555], 9

        ; Second pipe - 3 tiles high
        mov byte [level_original+458], 6
        mov byte [level_original+459], 7
        mov byte [level_original+518], 8
        mov byte [level_original+519], 9
        mov byte [level_original+578], 8
        mov byte [level_original+579], 9

        ; Ten free coins
        mov byte [level_original+303], 11
        mov byte [level_original+304], 11
        mov byte [level_original+254], 11
        mov byte [level_original+316], 11
        mov byte [level_original+265], 11
        mov byte [level_original+328], 11
        mov byte [level_original+275], 11
        mov byte [level_original+342], 11
        mov byte [level_original+287], 11
        mov byte [level_original+350], 11

        ; Four ascending stair steps
        mov byte [level_original+594], 10

        mov byte [level_original+535], 10
        mov byte [level_original+595], 10

        mov byte [level_original+476], 10
        mov byte [level_original+536], 10
        mov byte [level_original+596], 10

        mov byte [level_original+417], 10
        mov byte [level_original+477], 10
        mov byte [level_original+537], 10
        mov byte [level_original+597], 10

        ; Seven-tile flag pole
        mov byte [level_original+178], 12
        mov byte [level_original+238], 12
        mov byte [level_original+298], 12
        mov byte [level_original+358], 12
        mov byte [level_original+418], 12
        mov byte [level_original+478], 12
        mov byte [level_original+538], 12

        ; Flag pole base
        mov byte [level_original+598], 1

        pop es
        pop di
        pop cx
        pop ax
        ret


; ------------------------------------------
; ResetMap - original map -> working map
; ------------------------------------------
ResetMap:
        push ax
        push cx
        push si
        push di
        push ds
        push es

        push cs
        pop ds
        push cs
        pop es

        mov si, level_original
        mov di, level_working
        mov cx, MAP_SIZE
        cld
        rep movsb

        pop es
        pop ds
        pop di
        pop si
        pop cx
        pop ax
        ret


; ------------------------------------------
; ResetLevelState - call on new game AND on every new life.
; Restores the map, resets the camera to 0 and puts Mario at the start.
; ------------------------------------------
ResetLevelState:
        call    ResetMap
        mov     word [camera_x], 0
        mov     word [hero_x], HERO_START_X
        mov     word [hero_y], HERO_START_Y
        mov     byte [hero_flip], 1
        mov     byte [hero_moving], 0
        ret


; ------------------------------------------
; DrawTile - draws one solid 16x16 tile into the frame buffer,
; clipped at the left and right screen edges.
;   [BP+4] = screen X in pixels (signed, may be negative)
;   [BP+6] = screen Y in pixels
;   [BP+8] = tile code
; ------------------------------------------
DrawTile:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es

        ; Horizontal clipping: si = first visible x, dx = visible width
        mov si, [bp+4]
        mov ax, si
        add ax, TILE_SIZE               ; right edge
        cmp si, 0
        jge .left_ok
        xor si, si
.left_ok:
        cmp ax, SCREEN_W
        jle .right_ok
        mov ax, SCREEN_W
.right_ok:
        sub ax, si
        jle .done                       ; fully off-screen
        mov dx, ax

        ; di = y*320 + x  (y*256 + y*64)
        mov ax, [bp+6]
        mov di, ax
        shl ax, 8
        shl di, 6
        add di, ax
        add di, si

        mov ax, [frame_seg]
        mov es, ax

        xor bx, bx
        mov bl, [bp+8]
        mov al, [tile_colors+bx]

        mov bx, TILE_SIZE
.tile_row_loop:
        mov cx, dx
        rep stosb
        add di, SCREEN_W
        sub di, dx
        dec bx
        jnz .tile_row_loop

.done:
        pop es
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret


; ------------------------------------------
; DrawMap - draws the visible part of the level (Module 6 scrolling).
; First column = camera_x / 16, pixel offset = camera_x mod 16.
; Tile 0 (sky) is skipped because ClearFrame already filled the sky.
; ------------------------------------------
DrawMap:
        push ax
        push bx
        push cx
        push dx
        push si
        push di

        mov ax, [camera_x]
        shr ax, 4
        mov [map_start], ax
        mov ax, [camera_x]
        and ax, 15
        mov [map_off], ax

        mov word [map_row], 0

.row_loop:
        mov word [map_col], 0

.col_loop:
        mov ax, [map_start]
        add ax, [map_col]               ; world column
        cmp ax, MAP_WIDTH
        jae .next_col

        mov si, ax
        mov ax, [map_row]
        mov bx, MAP_WIDTH
        mul bx
        add si, ax

        xor ax, ax
        mov al, [level_working+si]
        cmp al, 0
        je .next_col
        mov dx, ax                      ; tile code

        mov ax, [map_col]
        shl ax, 4
        sub ax, [map_off]               ; screen x = col*16 - offset
        mov bx, [map_row]
        shl bx, 4                       ; screen y

        push dx
        push bx
        push ax
        call DrawTile
        add sp, 6

.next_col:
        inc word [map_col]
        cmp word [map_col], VIEW_COLS
        jne .col_loop

        inc word [map_row]
        cmp word [map_row], MAP_HEIGHT
        jne .row_loop

        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret


; ------------------------------------------
; GetTile - pixel position -> tile code
; Takes WORLD pixel coordinates (not screen), so collision code never
; has to think about the camera.
;   [BP+4] = world X, [BP+6] = world Y
; Output: AL = tile code (0 when outside the level)
; ------------------------------------------
GetTile:
        push bp
        mov bp, sp
        push bx
        push dx
        push si

        mov ax, [bp+4]
        cmp ax, LEVEL_W_PX
        jae .outside                    ; also catches negative X
        mov ax, [bp+6]
        cmp ax, LEVEL_H_PX
        jae .outside

        mov ax, [bp+4]
        shr ax, 4
        mov si, ax

        mov ax, [bp+6]
        shr ax, 4
        mov bx, MAP_WIDTH
        mul bx
        add si, ax

        mov al, [level_working+si]
        jmp .done

.outside:
        xor al, al

.done:
        pop si
        pop dx
        pop bx
        pop bp
        ret


; =====================================================================
; MODULE 4 - SPRITES
; =====================================================================

; ------------------------------------------
; DrawSpriteDemo - every Module 4 sprite in one row (screen coordinates).
; Flag bit 0 = mirror, bit 1 = checkerboard transparency, bit 2 = 16x32.
; Stack order: flags, address, Y, X.
; ------------------------------------------
DrawSpriteDemo:
        push word 0
        push word mario_stand
        push word 24
        push word 8
        call DrawSprite
        add sp, 8

        push word 1
        push word mario_run
        push word 24
        push word 32
        call DrawSprite
        add sp, 8

        push word 0
        push word mario_jump
        push word 24
        push word 56
        call DrawSprite
        add sp, 8

        push word 0
        push word goomba_walk
        push word 24
        push word 80
        call DrawSprite
        add sp, 8

        push word 0
        push word goomba_flat
        push word 24
        push word 104
        call DrawSprite
        add sp, 8

        push word 1
        push word koopa_walk
        push word 24
        push word 128
        call DrawSprite
        add sp, 8

        push word 0
        push word shell_sprite
        push word 24
        push word 152
        call DrawSprite
        add sp, 8

        push word 0
        push word mushroom_sprite
        push word 24
        push word 176
        call DrawSprite
        add sp, 8

        push word 2
        push word coin_sprite
        push word 24
        push word 200
        call DrawSprite
        add sp, 8

        push word 4
        push word super_stand
        push word 24
        push word 224
        call DrawSprite
        add sp, 8

        push word 5
        push word super_run
        push word 24
        push word 248
        call DrawSprite
        add sp, 8

        push word 4
        push word super_jump
        push word 24
        push word 272
        call DrawSprite
        add sp, 8

        ret


; ------------------------------------------
; DrawSprite - draws into the frame buffer, clipped on all four edges.
;   [BP+4] = screen X (signed), [BP+6] = screen Y (signed)
;   [BP+8] = sprite address,    [BP+10] = flags
; ------------------------------------------
DrawSprite:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push dx
        push si
        push di
        push es

        mov ax, [bp+4]
        mov [sprite_x], ax
        mov ax, [bp+6]
        mov [sprite_y], ax
        mov ax, [bp+8]
        mov [sprite_addr], ax
        mov ax, [bp+10]
        mov [sprite_flags], al

        mov byte [sprite_height], 16
        test byte [sprite_flags], 4
        jz .height_ready
        mov byte [sprite_height], 32
.height_ready:
        mov ax, [frame_seg]
        mov es, ax
        mov byte [sprite_row], 0

.row_loop:
        mov ax, [sprite_y]
        xor bx, bx
        mov bl, [sprite_row]
        add ax, bx
        cmp ax, 0
        jge .check_bottom
        jmp near .next_row
.check_bottom:
        cmp ax, 200
        jl .row_visible
        jmp near .next_row
.row_visible:
        mov [sprite_screen_y], ax

        mov byte [sprite_col], 0
.col_loop:
        mov ax, [sprite_x]
        xor bx, bx
        mov bl, [sprite_col]
        add ax, bx
        cmp ax, 0
        jge .check_right
        jmp near .next_col
.check_right:
        cmp ax, 320
        jl .x_visible
        jmp near .next_col
.x_visible:
        mov [sprite_screen_x], ax

        ; Destination pixel position
        mov ax, [sprite_screen_y]
        mov bx, 320
        mul bx
        add ax, [sprite_screen_x]
        mov [sprite_dest], ax

        ; Source column (reversed when mirrored)
        xor ax, ax
        mov al, [sprite_col]
        test byte [sprite_flags], 1
        jz .source_col_ready
        mov ax, 15
        xor bx, bx
        mov bl, [sprite_col]
        sub ax, bx
.source_col_ready:
        mov bx, ax
        xor ax, ax
        mov al, [sprite_row]
        shl ax, 4
        add ax, bx
        add ax, [sprite_addr]
        mov si, ax
        mov al, [si]
        mov [sprite_pixel], al
        cmp al, 0
        je .next_col

        ; Bit 1 skips alternate pixels (half transparent)
        test byte [sprite_flags], 2
        jz .put_pixel
        mov ax, [sprite_screen_x]
        add ax, [sprite_screen_y]
        test ax, 1
        jnz .next_col

.put_pixel:
        mov di, [sprite_dest]
        mov al, [sprite_pixel]
        mov [es:di], al

.next_col:
        inc byte [sprite_col]
        cmp byte [sprite_col], 16
        jae .next_row
        jmp near .col_loop

.next_row:
        inc byte [sprite_row]
        mov al, [sprite_row]
        cmp al, [sprite_height]
        jae .draw_done
        jmp near .row_loop

.draw_done:
        pop es
        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        pop bp
        ret


; =====================================================================
; MODULE 5 - FRAME BUFFER AND BLOCK OPERATIONS
; =====================================================================

; ------------------------------------------
; ClearFrame - fills the off-screen buffer with sky using REP STOSW
; ------------------------------------------
ClearFrame:
        push ax
        push cx
        push di
        push es

        mov ax, [frame_seg]
        mov es, ax
        xor di, di
        mov ax, (COL_SKY << 8) | COL_SKY
        mov cx, FRAME_WORDS
        cld
        rep stosw

        pop es
        pop di
        pop cx
        pop ax
        ret


; ------------------------------------------
; Present - copies the whole frame buffer to video memory
; with ONE block move (REP MOVSW)
; ------------------------------------------
Present:
        push ax
        push cx
        push si
        push di
        push ds
        push es

        mov ax, [frame_seg]
        mov ds, ax
        mov ax, VIDEO_SEG
        mov es, ax
        xor si, si
        xor di, di
        mov cx, FRAME_WORDS
        cld
        rep movsw

        pop es
        pop ds
        pop di
        pop si
        pop cx
        pop ax
        ret


; ------------------------------------------
; WaitTick - waits for the next BIOS timer tick (once per frame),
; then for the start of vertical retrace so the copy does not tear.
; ------------------------------------------
WaitTick:
        push ax
        push dx
        push es

        mov ax, 0040h
        mov es, ax
.wait_tick:
        mov ax, [es:006Ch]
        cmp ax, [last_tick]
        je .wait_tick
        mov [last_tick], ax

        mov dx, 03DAh
.wait_end:
        in al, dx
        test al, 8
        jnz .wait_end
.wait_start:
        in al, dx
        test al, 8
        jz .wait_start

        pop es
        pop dx
        pop ax
        ret


; =====================================================================
; MODULE 6 - CAMERA AND SCROLLING
; =====================================================================

; ------------------------------------------
; UpdateCamera
;   screen_x = world_x - camera_x
;   - camera follows Mario once screen_x > 160
;   - clamped to 0 .. (level width - 320)
;   - never moves left
; ------------------------------------------
UpdateCamera:
        push ax

        mov ax, [hero_x]
        sub ax, [camera_x]              ; screen_x
        cmp ax, CAM_FOLLOW_X
        jbe .done                       ; not past 160 yet

        mov ax, [hero_x]
        sub ax, CAM_FOLLOW_X            ; camera that puts Mario at 160
        cmp ax, CAM_MAX_X
        jbe .clamped
        mov ax, CAM_MAX_X
.clamped:
        cmp ax, [camera_x]
        jbe .done                       ; never scroll back left
        mov [camera_x], ax
.done:
        pop ax
        ret


; ------------------------------------------
; DrawWorldSprite - same stack layout as DrawSprite, but X is a WORLD
; position. Converts to screen_x = world_x - camera_x and only draws the
; entity when -16 < screen_x < 320.
;   [BP+4] = world X, [BP+6] = Y, [BP+8] = sprite address, [BP+10] = flags
; ------------------------------------------
DrawWorldSprite:
        push bp
        mov bp, sp
        push ax

        mov ax, [bp+4]
        sub ax, [camera_x]              ; screen_x (signed)
        cmp ax, -15
        jl .skip                        ; screen_x <= -16
        cmp ax, SCREEN_W
        jge .skip                       ; screen_x >= 320

        push word [bp+10]
        push word [bp+8]
        push word [bp+6]
        push ax
        call DrawSprite
        add sp, 8
.skip:
        pop ax
        pop bp
        ret


; ------------------------------------------
; DrawEntities - a few demo enemies/items placed in WORLD coordinates
; to show that they scroll with the map and are culled off-screen.
; ------------------------------------------
DrawEntities:
        push word 0
        push word goomba_walk
        push word 144
        push word 400
        call DrawWorldSprite
        add sp, 8

        push word 1
        push word koopa_walk
        push word 144
        push word 560
        call DrawWorldSprite
        add sp, 8

        push word 0
        push word mushroom_sprite
        push word 144
        push word 700
        call DrawWorldSprite
        add sp, 8

        push word 0
        push word coin_sprite
        push word 100
        push word 600
        call DrawWorldSprite
        add sp, 8
        ret


; ------------------------------------------
; DrawHero - Mario at his world position (stand / run animation)
; ------------------------------------------
DrawHero:
        push ax
        push bx

        mov ax, mario_stand
        cmp byte [hero_moving], 0
        je .pick_done
        inc byte [anim_cnt]
        test byte [anim_cnt], 1
        jz .pick_done
        mov ax, mario_run
.pick_done:
        xor bx, bx
        mov bl, [hero_flip]
        push bx
        push ax
        push word [hero_y]
        push word [hero_x]
        call DrawWorldSprite
        add sp, 8

        pop bx
        pop ax
        ret


; ------------------------------------------
; UpdateInput - moves Mario in WORLD coordinates.
; He can never go left of the camera (left screen edge) or past the
; right end of the level.
; ------------------------------------------
UpdateInput:
        push ax
        mov byte [hero_moving], 0

        mov al, [key_state+SC_RIGHT]
        or  al, [key_state+SC_D]
        jz  .check_left
        mov ax, [hero_x]
        add ax, HERO_SPEED
        cmp ax, LEVEL_W_PX - TILE_SIZE
        jbe .store_right
        mov ax, LEVEL_W_PX - TILE_SIZE
.store_right:
        mov [hero_x], ax
        mov byte [hero_flip], 1
        mov byte [hero_moving], 1

.check_left:
        mov al, [key_state+SC_LEFT]
        or  al, [key_state+SC_A]
        jz  .done
        mov ax, [hero_x]
        sub ax, HERO_SPEED
        jc  .clamp_left
        cmp ax, [camera_x]
        jae .store_left
.clamp_left:
        mov ax, [camera_x]              ; stop at the left edge of the screen
.store_left:
        mov [hero_x], ax
        mov byte [hero_flip], 0
        mov byte [hero_moving], 1
.done:
        pop ax
        ret


; ------------------------------------------
; GameLoop - one iteration per timer tick
; ------------------------------------------
GameLoop:
        push es
        mov ax, 0040h
        mov es, ax
        mov ax, [es:006Ch]
        pop es
        mov [last_tick], ax

.frame:
        call UpdateInput
        call UpdateCamera
        call ClearFrame
        call DrawMap
        call DrawEntities
        call DrawHero
        call WaitTick
        call Present
        cmp byte [key_state+SC_ESC], 0
        je .frame
        ret


; ------------------------------------------
; Keyboard handler (INT 9): keeps a pressed/released flag per scan code
; so Left/Right can be held down.
; ------------------------------------------
InstallKeyboard:
        push ax
        push bx
        push dx
        push es

        mov ax, 3509h
        int 21h
        mov [old_int9_off], bx
        mov [old_int9_seg], es

        mov dx, Int9Handler
        mov ax, 2509h
        int 21h

        pop es
        pop dx
        pop bx
        pop ax
        ret

RestoreKeyboard:
        push ax
        push dx
        push ds

        mov dx, [old_int9_off]
        mov ax, [old_int9_seg]
        mov ds, ax
        mov ax, 2509h
        int 21h

        pop ds
        pop dx
        pop ax
        ret

Int9Handler:
        push ax
        push bx

        in al, 60h
        mov ah, al
        and al, 7Fh
        xor bx, bx
        mov bl, al                      ; scan code without the break bit
        mov al, ah
        shr al, 7
        xor al, 1                       ; 1 = pressed, 0 = released
        mov [cs:key_state+bx], al

        in al, 61h                      ; acknowledge keyboard
        mov ah, al
        or al, 80h
        out 61h, al
        mov al, ah
        out 61h, al

        mov al, 20h                     ; end of interrupt
        out 20h, al

        pop bx
        pop ax
        iret


; ==========================================
; DATA - variables grouped by purpose
; ==========================================

; --- map / camera
level_original:
        times MAP_SIZE db 0
level_working:
        times MAP_SIZE db 0

camera_x        dw 0                    ; PIXELS (world position of left screen edge)
map_row         dw 0
map_col         dw 0
map_start       dw 0
map_off         dw 0

; --- frame buffer / clock
frame_seg       dw 0
last_tick       dw 0

; --- hero
hero_x          dw HERO_START_X         ; world pixels
hero_y          dw HERO_START_Y
hero_flip       db 1                    ; 1 = mirror sprite (see note: art faces left)
hero_moving     db 0
anim_cnt        db 0

; --- keys
old_int9_off    dw 0
old_int9_seg    dw 0
key_state       times 128 db 0

; One VGA colour for each tile code (0 to 12)
tile_colors:
        db 09h, 06h, 04h, 0Eh, 0Eh, 06h, 02h
        db 02h, 02h, 02h, 04h, 0Eh, 07h

; sprite drawing work variables
sprite_x          dw 0
sprite_y          dw 0
sprite_addr       dw 0
sprite_flags      db 0
sprite_height     db 16
sprite_row        db 0
sprite_col        db 0
sprite_screen_x   dw 0
sprite_screen_y   dw 0
sprite_dest       dw 0
sprite_pixel      db 0

; ==========================================
; MODULE 4 SPRITE DATA
; ==========================================

mario_stand:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,00h,00h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,00h,00h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
mario_run:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,04h,04h,00h,00h,00h,00h,04h,04h,00h,00h,00h,00h
        db 00h,00h,00h,06h,06h,06h,00h,00h,00h,00h,06h,06h,06h,00h,00h,00h
        db 00h,00h,06h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,06h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
mario_jump:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,04h,04h,00h,00h,00h,00h,04h,04h,00h,00h,00h,00h
        db 00h,00h,00h,04h,04h,00h,00h,00h,00h,00h,00h,04h,04h,00h,00h,00h
        db 00h,00h,06h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,06h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
goomba_walk:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h
        db 00h,00h,00h,06h,06h,0Fh,0Fh,06h,06h,0Fh,0Fh,06h,06h,00h,00h,00h
        db 00h,00h,00h,06h,06h,0Fh,0Fh,06h,06h,0Fh,0Fh,06h,06h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h
        db 00h,00h,00h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,00h,00h,00h
        db 00h,00h,06h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,06h,00h,00h
        db 00h,00h,06h,06h,00h,00h,00h,00h,00h,00h,00h,00h,06h,06h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
goomba_flat:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h
        db 00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h
        db 00h,00h,06h,06h,0Fh,0Fh,06h,06h,06h,06h,0Fh,0Fh,06h,06h,00h,00h
        db 00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h
        db 00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
koopa_walk:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,02h,02h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,02h,02h,02h,02h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,02h,02h,02h,02h,02h,02h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,02h,02h,02h,02h,02h,02h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,02h,02h,02h,02h,02h,02h,02h,02h,00h,00h,00h,00h
        db 00h,00h,00h,00h,02h,02h,0Eh,0Eh,0Eh,0Eh,02h,02h,00h,00h,00h,00h
        db 00h,00h,00h,00h,02h,02h,0Eh,0Eh,0Eh,0Eh,02h,02h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,02h,02h,02h,02h,02h,02h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,02h,02h,02h,02h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,00h,00h,00h,00h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,06h,06h,06h,00h,00h,00h,00h,06h,06h,06h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
shell_sprite:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,02h,02h,02h,02h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,02h,02h,02h,02h,02h,02h,02h,02h,00h,00h,00h,00h
        db 00h,00h,00h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,00h,00h,00h
        db 00h,00h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,00h,00h
        db 00h,00h,02h,02h,02h,02h,0Eh,0Eh,0Eh,0Eh,02h,02h,02h,02h,00h,00h
        db 00h,00h,02h,02h,02h,02h,0Eh,0Eh,0Eh,0Eh,02h,02h,02h,02h,00h,00h
        db 00h,00h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,00h,00h
        db 00h,00h,00h,02h,02h,02h,02h,02h,02h,02h,02h,02h,02h,00h,00h,00h
        db 00h,00h,00h,00h,02h,02h,02h,02h,02h,02h,02h,02h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,06h,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
mushroom_sprite:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,00h,00h,00h
        db 00h,00h,04h,04h,04h,04h,0Fh,0Fh,04h,04h,04h,04h,04h,04h,00h,00h
        db 00h,00h,04h,04h,04h,04h,0Fh,0Fh,04h,04h,04h,04h,04h,04h,00h,00h
        db 00h,00h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,00h,00h
        db 00h,00h,00h,04h,04h,04h,04h,04h,04h,04h,04h,04h,04h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,0Eh,0Eh,00h,00h,00h,00h,0Eh,0Eh,00h,00h,00h,00h
        db 00h,00h,00h,00h,0Eh,0Eh,00h,00h,00h,00h,0Eh,0Eh,00h,00h,00h,00h
        db 00h,00h,00h,00h,0Eh,0Eh,00h,00h,00h,00h,0Eh,0Eh,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
coin_sprite:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h
        db 00h,00h,00h,0Eh,0Eh,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h
        db 00h,00h,00h,0Eh,0Eh,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h
        db 00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h
        db 00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h
        db 00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h
        db 00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h
        db 00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
super_stand:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,00h,00h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,00h,00h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,00h,00h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,00h,00h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
super_run:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,00h,00h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,04h,04h,00h,00h,00h,00h,04h,04h,00h,00h,00h,00h
        db 00h,00h,00h,00h,04h,04h,00h,00h,00h,00h,04h,04h,00h,00h,00h,00h
        db 00h,00h,00h,06h,06h,06h,00h,00h,00h,00h,06h,06h,06h,00h,00h,00h
        db 00h,00h,00h,06h,06h,06h,00h,00h,00h,00h,06h,06h,06h,00h,00h,00h
        db 00h,00h,06h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,06h,00h,00h
        db 00h,00h,06h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,06h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
super_jump:
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,04h,04h,04h,04h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,04h,04h,04h,04h,04h,04h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,0Eh,0Fh,0Fh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,0Eh,0Eh,0Eh,0Eh,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,0Eh,06h,06h,06h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,06h,06h,06h,06h,06h,06h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,04h,04h,00h,00h,00h,00h,04h,04h,00h,00h,00h,00h
        db 00h,00h,00h,00h,04h,04h,00h,00h,00h,00h,04h,04h,00h,00h,00h,00h
        db 00h,00h,00h,04h,04h,00h,00h,00h,00h,00h,00h,04h,04h,00h,00h,00h
        db 00h,00h,00h,04h,04h,00h,00h,00h,00h,00h,00h,04h,04h,00h,00h,00h
        db 00h,00h,06h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,06h,00h,00h
        db 00h,00h,06h,06h,06h,00h,00h,00h,00h,00h,00h,06h,06h,06h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h
        db 00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h,00h