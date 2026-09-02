%include "snake_node.inc"
%include "snake.inc"

; snake.asm
extern Snake_ctor
extern Snake_dtor
extern Snake_Update
extern Snake_Draw

; memory.asm
extern alloc
extern dealloc

; screen.asm
extern Screen_GetSize
extern Screen_ctor
extern Screen_dtor
extern Screen_PlaceSnakeNode
extern Screen_Clear
extern Screen_Draw

; user_input.asm
extern read_user_input

; Helper Constants
SYS_EXIT equ 60
SIGINT equ 2

; Screen Constants
RES_X equ 30
RES_Y equ 10

section .bss
    snake_ptr resb 8
    screen_ptr resb 8
    running_flag resb 1

section .text

extern sleep_ms
extern enable_raw_input
extern disable_raw_input
extern sig_install

global _start

_start:
    ; Set up signal and raw input handler
    mov rdi, SIGINT
    lea rsi, [rel sigint_handler]
    call sig_install
    call enable_raw_input

    ; Alloc snake
    mov rdi, Snake_size
    call alloc
    mov [snake_ptr], rax

    ; Construct snake
    mov rdi, [snake_ptr]
    mov esi, RES_X / 2              ; Initial x
    mov edx, RES_Y / 2              ; Initial y
    mov ecx, RES_X - 1              ; Max x
    mov r8d, RES_Y - 1              ; Max y
    call Snake_ctor

    ; Alloc screen
    call Screen_GetSize
    mov rdi, rax
    call alloc
    mov [screen_ptr], rax

    ; Construct Screen
    mov rdi, [screen_ptr]
    mov esi, RES_X
    mov edx, RES_Y
    call Screen_ctor

    mov byte [rel running_flag], 1

.game_loop:
    cmp byte [running_flag], 1
    jne .exit

    mov rdi, [screen_ptr]
    call Screen_Clear

    call read_user_input

    mov rdi, [snake_ptr]
    mov sil, al
    call Snake_Update

    mov rdi, [snake_ptr]
    lea rsi, [rel draw_snake_node]
    call Snake_Draw

    mov rdi, [screen_ptr]
    call Screen_Draw

    ; Sleep
    mov rdi, 300
    call sleep_ms

    jmp .game_loop

.exit:

    call disable_raw_input

    ; Deconstruct screen
    mov rdi, [screen_ptr]
    call Screen_dtor

    ; Deallocate screen
    mov rdi, [snake_ptr]
    call dealloc

    ; Deconstruct snake
    mov rdi, [snake_ptr]
    call Snake_dtor

    ; Deallocate snake
    mov rdi, [snake_ptr]
    call dealloc

    ;; exit
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

sigint_handler:
    mov byte [rel running_flag], 0
    ret

;-----------------------------
; Function: draw_snake_node
; Description: Draw a node of a snake
; Args: edi = x, esi = y
; Returns: None
;-----------------------------
draw_snake_node:
    mov edx, esi
    mov esi, edi
    mov rdi, [screen_ptr]
    call Screen_PlaceSnakeNode
    ret
