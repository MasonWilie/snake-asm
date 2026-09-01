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


; Helper Constants
SYS_EXIT equ 60
SYS_READ equ 0
SYS_WRITE equ 1
STDIN equ 0
STDOUT equ 1

SIGINT equ 2

; Screen Constants
SCREEN_BACKGROUND_CHAR equ ' '
RES_X equ 150
RES_Y equ 10
RES_X_EFF equ RES_X + 1


SNAKE_SYMBOL equ '#'

section .bss
    screen_buffer_size equ RES_X_EFF*RES_Y
    screen_buffer resb screen_buffer_size

    input_buffer resb 64
    input_buffer_length equ $ - input_buffer

    snake_ptr resb 8
    running_flag resb 1

section .data
    cursor_home db 27, "[H"
    cursor_home_len equ $ - cursor_home

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

    mov byte [rel running_flag], 1

.game_loop:
    cmp byte [running_flag], 1
    jne .exit


    call update_screen

    call read_user_input

    mov rdi, [snake_ptr]
    mov sil, al
    call Snake_Update

    mov rdi, [snake_ptr]
    lea rsi, [rel draw_snake_node]
    call Snake_Draw

    call draw_screen

    ; Sleep
    mov rdi, 300
    call sleep_ms

    jmp .game_loop

.exit:

    call disable_raw_input

    mov rdi, [snake_ptr]
    call Snake_dtor

    mov rdi, [snake_ptr]
    call dealloc

    ;; exit
    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall


update_screen:
    call clear_screen

    ret

clear_screen:
    xor rax, rax

; --- Fill the entire buffer with SCREEN_BACKGROUND_CHAR --- ;

.fill_loop:                                     ; while rax < screen_buffer_size
    cmp rax, screen_buffer_size
    je .new_line_loop_setup

    lea rcx, [screen_buffer + rax]
    mov byte [rcx], SCREEN_BACKGROUND_CHAR
    
    inc rax
    jmp .fill_loop

.new_line_loop_setup:
    xor rax, rax

.new_line_loop:
    cmp rax, RES_Y
    je .exit

    mov rcx, rax
    imul rcx, RES_X_EFF
    add rcx, screen_buffer
    mov byte [rcx], 10
    
    inc rax
    jmp .new_line_loop

.exit:
    ret


draw_screen:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, cursor_home
    mov rdx, cursor_home_len
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, screen_buffer
    mov rdx, screen_buffer_size
    syscall

    ret

get_buffer_index:
    ; edi = x
    ; esi = y

    mov eax, esi
    imul eax, RES_X_EFF
    add eax, edi

    ret


sigint_handler:
    mov byte [rel running_flag], 0
    ret



;-----------------------------
; Function: read_user_input
; Description: Read user input from the buffer and come up with
;               the desired new direction
; Args: None
; Returns: al = New direction
;-----------------------------
read_user_input:
    push r12
    push r13
    push r14

    ; Default to invalid direction
    mov r14b, SnakeDirection_INVALID

    ; Read input into buffer
    mov rax, SYS_READ
    mov rdi, STDIN
    mov rsi, input_buffer
    mov rdx, input_buffer_length
    syscall

    cmp rax, 0
    jle .return

    mov r12, rax

    ; Read the characters from the buffer
    ; r12 = bytes read
    ; r13 = counter
    ; r14b = proposed direction
    xor r13, r13

.loop:
    cmp r12, r13
    je .return

    mov dil, [input_buffer + r13]
    call decode_input
    cmp al, SnakeDirection_INVALID
    je .no_new_direction

    mov r14b, al

.no_new_direction:
    
    inc r13
    jmp .loop

; end loop

.return:
    mov al, r14b
    pop r14
    pop r13
    pop r12
    ret

;-----------------------------
; Function: decode_input
; Description: Decode the character input into
;               a snake direction
; Args: dil = input character
; Returns: al = snake direction
;-----------------------------
decode_input:
    cmp dil, 'w'
    je .return_up

    cmp dil, 's'
    je .return_down

    cmp dil, 'a'
    je .return_left

    cmp dil, 'd'
    je .return_right

    ; Return invalid
    mov al, SnakeDirection_INVALID
    ret

.return_up:
    mov al, SnakeDirection_UP
    ret

.return_down:
    mov al, SnakeDirection_DOWN
    ret

.return_left:
    mov al, SnakeDirection_LEFT
    ret

.return_right:
    mov al, SnakeDirection_RIGHT
    ret

;-----------------------------
; Function: draw_snake_node
; Description: Draw a node of a snake
; Args: edi = x, esi = y
; Returns: None
;-----------------------------
draw_snake_node:
    call get_buffer_index ; Arguments already in the correct registers
    mov byte [screen_buffer + rax], SNAKE_SYMBOL
    ret

