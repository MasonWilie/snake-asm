%include "screen.inc"
%include "sys_constants.inc"

; memory.asm
extern alloc
extern dealloc

; section .bss
;     screen_buffer resb RES_X_EFF * RES_Y
;     screen_bufer_size equ $ - screen_bufer

; class Screen
; {
; public:
;     Screen_ctor(int resX, int resY);

; private:
;     int resX;
;     int resY;
;     char* buffer;
; }


Screen_resX equ 0
Screen_resY equ 4
Screen_buffer equ 8
Screen_buffer_size equ 16
Screen_size equ 24 ; Extra 4 bytes for alignment

NEWLINE_CHAR equ 10
SCREEN_BACKGROUND_CHAR equ ' '
SNAKE_SEGMENT_CHAR equ '#'

section .data
    cursor_home db 27, "[H"
    cursor_home_len equ $ - cursor_home

section .text

global Screen_GetSize
global Screen_ctor
global Screen_dtor
global Screen_Clear
global Screen_Draw
global Screen_PlaceSnakeNode

;-----------------------------
; Function: Screen_GetSize
; Description: Return the size of a Screen object
; Args: None
; Returns: rax = size of a Screen object
;-----------------------------
Screen_GetSize:
    mov rax, Screen_size
    ret

;-----------------------------
; Function: Screen_ctor
; Description: Construct a Screen object using pre-allocated memory
; Args:
;   rdi = Screen* this (un-allocated)
;   esi = X resolution
;   edx = Y resolution
; Returns: rax = result
;-----------------------------
Screen_ctor:
    push r12
    mov r12, rdi

    mov [r12 + Screen_resX], esi
    mov [r12 + Screen_resY], edx

    ; Allocate screen buffer, adding a slot for newlines
    inc esi
    imul esi, edx
    mov [r12 + Screen_buffer_size], esi
    movsxd rdi, esi
    call alloc

    mov [r12 + Screen_buffer], rax

    pop r12
    ret

;-----------------------------
; Function: Screen_dtor
; Description: Destruct a Screen object
; Args: rdi = Screen* this
; Returns: None
;-----------------------------
Screen_dtor:
    push r12                            ; r12 = this
    mov r12, rdi

    mov rdi, [r12 + Screen_buffer]
    mov rsi, [r12 + Screen_buffer_size]

    call dealloc

    pop r12
    ret


;-----------------------------
; Function: Screen_Clear
; Description: Resets the screen to just the background
; Args: rdi = Screen* this
; Returns: None
;-----------------------------
Screen_Clear:
    mov r8d, [rdi + Screen_resX]        ; r8d = resX
    mov r9d, [rdi + Screen_resY]        ; r9d = resY
    xor r10d, r10d                      ; r10d = counter x
    xor r11d, r11d                      ; r11d = counter y

    mov rsi, [rdi + Screen_buffer]      ; rsi = buffer cursor

.y_loop:
    cmp r11d, r9d
    je .end_y_loop
    inc r11d

    xor r10d, r10d                      ; x counter = 0
.x_loop:
    cmp r10d, r8d
    je .end_x_loop
    inc r10d

    mov byte [rsi], SCREEN_BACKGROUND_CHAR
    inc rsi

    jmp .x_loop
.end_x_loop:

    mov byte [rsi], NEWLINE_CHAR
    inc rsi

    jmp .y_loop
.end_y_loop:

    ret

;-----------------------------
; Function: Screen_Draw
; Description: Draw the buffer out onto the screen
; Args: rdi = Screen* this
; Returns: None
;-----------------------------
Screen_Draw:
    push r12
    mov r12, rdi                        ; r12 = this*

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, cursor_home
    mov rdx, cursor_home_len
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, [r12 + Screen_buffer]
    mov edx, dword [r12 + Screen_buffer_size]
    syscall

    pop r12

    ret

;-----------------------------
; Function: Screen_PlaceSnakeNode
; Description: Places a snake node in the buffer
; Args:
;   rdi = Screen* this
;   esi = x
;   edx = y
; Returns: None
;-----------------------------
Screen_PlaceSnakeNode:
    mov ecx, [rdi + Screen_resX]
    inc ecx                             ; ecx = resX + 1 for newline 

    imul edx, ecx                       ; edx = y * (resX + 1)
    add edx, esi                        ; edx = y * (resX + 1) + x

    mov r8, [rdi + Screen_buffer]       ; r8 = this->buffer
    mov byte [r8 + rdx], SNAKE_SEGMENT_CHAR

    ret
