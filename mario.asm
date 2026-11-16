; =====================================================================
; MARIO.COM — Modules 1 + 2 (Absolute Bulletproof Fix)
; =====================================================================
[BITS 16]
[ORG 100h]

; CONSTANTS
SCREEN_W        equ     320
SCREEN_H        equ     200
VIDEO_SEG       equ     0A000h

start:
        ; 1. Force the CPU to finish any pending instructions
        cli                     ; Disable interrupts
        mov     ax, cs
        mov     ds, ax
        mov     es, ax
        mov     ss, ax
        mov     sp, 0FFFEh
        sti                     ; Enable interrupts

        ; 2. Switch to VGA Mode 13h
        mov     ax, 0013h
        int     10h

        ; 3. Draw Sky (Light Blue)
        mov     ax, VIDEO_SEG
        mov     es, ax
        xor     di, di
        mov     cx, 64000
        mov     al, 09h
        rep     stosb

        ; 4. Draw Ground (Brown)
        mov     ax, VIDEO_SEG
        mov     es, ax
        mov     di, 176 * 320
        mov     cx, 320 * 24
        mov     al, 06h
        rep     stosb

        ; 5. Draw Green Line on Ground
        mov     ax, VIDEO_SEG
        mov     es, ax
        mov     di, 176 * 320
        mov     cx, 320 * 2
        mov     al, 02h
        rep     stosb

        ; 6. Draw 8 Color Swatches
        mov     bx, 16          ; X start
        mov     dx, 60          ; Y start

.swatch_loop:
        cmp     bx, 272
        jge     .draw_cross

        mov     ax, VIDEO_SEG
        mov     es, ax

        mov     bp, 40          ; height
        mov     si, dx          ; current Y

.swatch_row:
        mov     ax, si
        mov     cx, 320
        mul     cx              ; AX = Y * 320
        add     ax, bx          ; AX = (Y*320) + X
        mov     di, ax

        push    cx
        mov     cx, 32          ; width
        mov     al, 04h         ; Default red
        
        ; Select color based on X
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

        ; 7. Draw Red Cross
.draw_cross:
        mov     ax, VIDEO_SEG
        mov     es, ax
        mov     di, (130 * 320) + 150
        mov     cx, 21
        mov     al, 04h
        rep     stosb

        mov     ax, VIDEO_SEG
        mov     es, ax
        mov     di, (120 * 320) + 160
        mov     cx, 21
        mov     al, 04h
.v_line:
        stosb
        add     di, 319
        dec     cx
        jnz     .v_line
       
        ; Modules 3 and 4
        call    InitMap
        call    ResetMap
        call    DrawMap
        call    DrawSpriteDemo

        ; 8. Wait for Key & Exit
        xor     ah, ah
        int     16h

        mov     ax, 0003h
        int     10h

        mov     ax, 4C00h
        int     21h


; ==========================================
; MODULE 3 - LEVEL MAP AND TILE DRAWING
; ==========================================

MAP_WIDTH       equ 60
MAP_HEIGHT      equ 12
TILE_SIZE       equ 16

; ------------------------------------------
; InitMap
; Creates the original level
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
        mov cx, 720
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
; ResetMap
; Copies original map into working map
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
        mov cx, 720
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
; DrawTile
; Inputs: X, Y, tile code on stack
; [BP+4] = X
; [BP+6] = Y
; [BP+8] = tile code
; ------------------------------------------

DrawTile:
        push bp
        mov bp, sp
        push ax
        push bx
        push cx
        push di
        push es

        ; [bp+4] = X, [bp+6] = Y, [bp+8] = tile code
        mov ax, [bp+6]
        shl ax, 4
        mov bx, 320
        mul bx
        mov di, ax

        mov ax, [bp+4]
        shl ax, 4
        add di, ax

        mov ax, 0A000h
        mov es, ax

        xor bx, bx
        mov bl, [bp+8]
        mov al, [tile_colors+bx]

        mov byte [tile_row], 16
.tile_row_loop:
        mov cx, 16
        rep stosb
        add di, 304
        dec byte [tile_row]
        jnz .tile_row_loop

        pop es
        pop di
        pop cx
        pop bx
        pop ax
        pop bp
        ret


; ------------------------------------------
; DrawMap
; Draws visible 20 columns of the map
; camera_x is measured in tiles
; ------------------------------------------

DrawMap:
        push ax
        push bx
        push cx
        push dx
        push si
        push di

        mov word [map_row], 0

.row_loop:
        mov word [map_col], 0

.col_loop:
        ; Find world column
        mov ax, [camera_x]
        add ax, [map_col]

        cmp ax, 60
        jae .empty_tile

        ; Calculate map index
        mov bx, 60
        mov dx, [map_row]
        mov ax, dx
        mul bx

        add ax, [camera_x]
        add ax, [map_col]

        mov si, ax
        xor dx, dx
        mov dl, [level_working+si]
        jmp .draw_tile

.empty_tile:
        xor dx, dx

.draw_tile:
        push dx
        push word [map_row]
        push word [map_col]
        call DrawTile
        add sp, 6

        inc word [map_col]
        cmp word [map_col], 20
        jne .col_loop

        inc word [map_row]
        cmp word [map_row], 12
        jne .row_loop

        pop di
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret


; ------------------------------------------
; GetTile
; Inputs: pixel X and pixel Y on stack
; Output: AL = tile code
; ------------------------------------------

GetTile:
        push bp
        mov bp, sp

        push bx
        push dx
        push si

        ; Check screen boundaries
        cmp word [bp+4], 320
        jae .outside

        cmp word [bp+6], 192
        jae .outside

        ; Convert pixel X into tile column
        mov ax, [bp+4]
        shr ax, 4
        add ax, [camera_x]

        cmp ax, 60
        jae .outside

        mov si, ax

        ; Convert pixel Y into tile row
        mov ax, [bp+6]
        shr ax, 4

        mov bx, 60
        mul bx

        add ax, si
        mov si, ax

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


; ------------------------------------------
; DrawSpriteDemo
; Shows every Module 4 sprite in one clean row.
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
        mov ax, 0A000h
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

        ; Find source column (reverse it when mirrored)
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

        ; Bit 1 skips alternate pixels for transparency
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

; ==========================================
; MODULE 3 DATA
; ==========================================

level_original:
        times 720 db 0

level_working:
        times 720 db 0

camera_x       dw 0
map_row        dw 0
map_col        dw 0

tile_code      db 0
tile_row       db 0
tile_col       db 0

; One VGA colour for each tile code (0 to 12)
tile_colors:
        db 09h, 06h, 04h, 0Eh, 0Eh, 06h, 02h
        db 02h, 02h, 02h, 04h, 0Eh, 07h

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
