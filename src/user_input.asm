%include "snake_node.inc"

SYS_READ equ 0
STDIN equ 0

section .bss
    input_buffer resb 64
    input_buffer_length equ $ - input_buffer

section .text

global read_user_input

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
