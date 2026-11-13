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

        ; 8. Wait for Key & Exit
        xor     ah, ah
        int     16h

        mov     ax, 0003h
        int     10h

        mov     ax, 4C00h
        int     21h