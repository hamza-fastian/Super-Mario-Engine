; =====================================================================
; MARIO.COM — Super Mario Engine (EL2003 Semester Project)
; Modules 1 + 2: Program skeleton, video mode, PutPixel, FillRect
; ---------------------------------------------------------------------
; Build :  nasm -f bin mario.asm -o MARIO.COM
; Run   :  MARIO.COM   (inside DOSBox)
; =====================================================================

[BITS 16]
[ORG 100h]

; =====================================================================
; CONSTANTS  (Module 1: named constants as EQU)
; =====================================================================
SCREEN_W        equ     320
SCREEN_H        equ     200
VIDEO_SEG       equ     0A000h
TILE_SIZE       equ     16

; ── Game colour palette (VGA default, 0..255) ──
COL_SKY         equ     09h         ; light blue
COL_GROUND_TOP  equ     02h         ; dark green
COL_GROUND      equ     06h         ; brown
COL_BRICK       equ     04h         ; red
COL_PIPE        equ     02h         ; green
COL_HERO        equ     04h         ; red
COL_HERO_SKIN   equ     0Eh         ; yellow
COL_ENEMY       equ     06h         ; brown
COL_COIN        equ     0Eh         ; yellow
COL_TEXT        equ     0Fh         ; white
COL_HUD_BG      equ     00h         ; black
COL_QUESTION    equ     0Eh         ; yellow
COL_BLACK       equ     00h

; =====================================================================
; ENTRY POINT  (Module 1: ORG 100h, DS/ES setup, clean exit)
; =====================================================================
start:
        ; ── Set DS and ES = CS  (a .COM starts with DS = PSP) ──
        mov     ax, cs
        mov     ds, ax
        mov     es, ax

        ; ── Module 2: switch to VGA Mode 13h ──
        call    InitVideo

        ; ── Module 2: test screen ──
        call    DrawTestScreen

        ; ── Wait for any keypress ──
        xor     ah, ah
        int     16h

        ; ── Restore text mode and exit cleanly ──
        call    RestoreVideo
        mov     ax, 4C00h
        int     21h

; =====================================================================
; InitVideo
;   Purpose : switch display to VGA Mode 13h (320×200, 256 colours)
;   Inputs  : none
;   Outputs : none
;   Clobbers: AX
; =====================================================================
InitVideo:
        mov     ax, 0013h
        int     10h
        ret

; =====================================================================
; RestoreVideo
;   Purpose : restore standard 80×25 text mode
;   Inputs  : none
;   Outputs : none
;   Clobbers: AX
; =====================================================================
RestoreVideo:
        mov     ax, 0003h
        int     10h
        ret

; =====================================================================
; PutPixel
;   Purpose : write one pixel in Mode 13h video memory
;   Inputs  : [bp+4]  = x (0..319)
;             [bp+6]  = y (0..199)
;             [bp+8]  = colour (0..255)
;   Outputs : pixel written; nothing returned
;   Clobbers: AX, BX, DI, ES
;   Note    : offset = y*320 + x  computed as (y<<8)+(y<<6)+x
; =====================================================================
PutPixel:
        push    bp
        mov     bp, sp
        push    ax
        push    bx
        push    di

        ; clamp x and y (safety — do not write outside the frame)
        mov     ax, [bp+4]           ; x
        cmp     ax, SCREEN_W
        jae     .pp_done
        mov     bx, [bp+6]           ; y
        cmp     bx, SCREEN_H
        jae     .pp_done

        ; DI = y*320 + x
        mov     di, bx
        shl     di, 8                ; y * 256
        shl     bx, 6                ; y * 64
        add     di, bx               ; y * 320
        add     di, ax               ; + x

        ; write colour
        mov     es, [cs:videoSeg]
        mov     ax, [bp+8]
        mov     [es:di], al

.pp_done:
        pop     di
        pop     bx
        pop     ax
        pop     bp
        ret     6                    ; 3 word params

; =====================================================================
; FillRect
;   Purpose : draw a filled axis-aligned rectangle
;   Inputs  : [bp+4]  = x,  [bp+6] = y,  [bp+8] = w,
;             [bp+10] = h,  [bp+12] = colour
;   Outputs : rectangle painted in video memory
;   Clobbers: AX, BX, CX, DX, DI, ES
; =====================================================================
FillRect:
        push    bp
        mov     bp, sp
        push    ax
        push    bx
        push    cx
        push    dx
        push    di

        mov     cx, [bp+10]          ; CX = h (rows to draw)
        cmp     cx, 0
        jle     .fr_done

        mov     es, [cs:videoSeg]

.fr_row:
        ; compute row start offset for current y
        mov     ax, [bp+6]           ; y
        mov     bx, ax
        shl     ax, 8                ; y*256
        shl     bx, 6                ; y*64
        add     ax, bx               ; y*320
        add     ax, [bp+4]           ; + x  → DI = row start offset
        mov     di, ax

        ; draw the row: w pixels of the colour
        push    cx
        mov     cx, [bp+8]           ; CX = w
        mov     al, [bp+12]          ; AL = colour
        rep     stosb
        pop     cx

        ; next row
        inc     word [bp+6]          ; y++
        dec     cx
        jnz     .fr_row

.fr_done:
        pop     di
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        pop     bp
        ret     10                   ; 5 word params

; =====================================================================
; DrawTestScreen
;   Purpose : Module 2 "Done when" test — show every game colour
;             and prove PutPixel + FillRect work.
;   Inputs  : none
;   Outputs : screen filled with labelled colour blocks
;   Clobbers: all (it is only called once)
; =====================================================================
DrawTestScreen:
        ; ── Sky background ──
        push    word 0
        push    word 0
        push    word SCREEN_W
        push    word SCREEN_H
        push    word COL_SKY
        call    FillRect

        ; ── Sky strip (top): a band of light blue across y=16..40 ──
        push    word 0
        push    word 16
        push    word SCREEN_W
        push    word 24
        push    word 09h
        call    FillRect

        ; ── Ground strip at bottom: rows 176..199 ──
        push    word 0
        push    word 176
        push    word SCREEN_W
        push    word 24
        push    word COL_GROUND
        call    FillRect
        ; ground top highlight (2 px)
        push    word 0
        push    word 176
        push    word SCREEN_W
        push    word 2
        push    word COL_GROUND_TOP
        call    FillRect

        ; ── Colour swatches across the middle ──
        ; 8 swatches × 32 px wide, at y = 60, height 40
        ; x positions: 16, 48, 80, 112, 144, 176, 208, 240
        ; colours:   brick, pipe, hero, hero skin, enemy, coin, text, question

        ; swatch 1: brick red
        push    word 16
        push    word 60
        push    word 32
        push    word 40
        push    word COL_BRICK
        call    FillRect

        ; swatch 2: pipe green
        push    word 48
        push    word 60
        push    word 32
        push    word 40
        push    word COL_PIPE
        call    FillRect

        ; swatch 3: hero red
        push    word 80
        push    word 60
        push    word 32
        push    word 40
        push    word COL_HERO
        call    FillRect

        ; swatch 4: hero skin yellow
        push    word 112
        push    word 60
        push    word 32
        push    word 40
        push    word COL_HERO_SKIN
        call    FillRect

        ; swatch 5: enemy brown
        push    word 144
        push    word 60
        push    word 32
        push    word 40
        push    word COL_ENEMY
        call    FillRect

        ; swatch 6: coin yellow (same as skin but ok)
        push    word 176
        push    word 60
        push    word 32
        push    word 40
        push    word COL_COIN
        call    FillRect

        ; swatch 7: text white
        push    word 208
        push    word 60
        push    word 32
        push    word 40
        push    word COL_TEXT
        call    FillRect

        ; swatch 8: question yellow
        push    word 240
        push    word 60
        push    word 32
        push    word 40
        push    word COL_QUESTION
        call    FillRect

        ; ── PutPixel sanity: draw a red cross at centre ──
        ; horizontal bar: y = 130, x = 150..170
        mov     word [varTmpX], 150
.pp_hloop:
        push    word [varTmpX]
        push    word 130
        push    word COL_BRICK
        call    PutPixel
        inc     word [varTmpX]
        cmp     word [varTmpX], 171
        jl      .pp_hloop

        ; vertical bar: x = 160, y = 120..140
        mov     word [varTmpY], 120
.pp_vloop:
        push    word 160
        push    word [varTmpY]
        push    word COL_BRICK
        call    PutPixel
        inc     word [varTmpY]
        cmp     word [varTmpY], 141
        jl      .pp_vloop

        ret

; =====================================================================
; DATA
; =====================================================================
section .data

videoSeg        dw      VIDEO_SEG
varTmpX         dw      0
varTmpY         dw      0