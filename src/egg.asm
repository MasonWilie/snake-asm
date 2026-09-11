%include "egg.inc"

section .text

global Egg_ctor
global Egg_CheckAndUpdate

;-----------------------------
; Function: Egg_ctor
; Description: Construct an egg
; Args:
;   rdi = Egg* (pre-allocated)
;   rsi = screen buffer
;   rdx = screen buffer length
;   cl = background char
;   r8b = snake char
;   r9b = egg char
; Returns: None
;-----------------------------
Egg_ctor:
    sub rsp, 8

    mov [rdi + Egg_buffer], rsi
    mov [rdi + Egg_bufferLen], rdx
    mov [rdi + Egg_backgroundChar], cl
    mov [rdi + Egg_snakeChar], r8b
    mov [rdi + Egg_eggChar], r9b
    
    mov qword [rdi + Egg_eggIdx], 0

    call Egg_UpdatePosition

    add rsp, 8

    ret

;-----------------------------
; Function: Egg_CheckAndUpdate
; Description: Check if the egg is overlapping
;               with the snake. If it is, then
;               move the egg.
; Args: rdi = this*
; Returns: al = True if the egg is overlapping
;               with the snake
;-----------------------------
Egg_CheckAndUpdate:
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    mov r12, rdi                        ; r12 = this
    mov r13, [r12 + Egg_buffer]         ; r13 = screen buffer
    mov r14, [r12 + Egg_eggIdx]         ; r14 = egg Idx
    mov r15b, [r12 + Egg_snakeChar]     ; r15b = snake char

    cmp r15b, [r13 + r14]               ; Check if the egg has been overwritten by the snake
    jne .exit

    mov rdi, r12
    call Egg_UpdatePosition

.exit_true:
    mov al, 1
    jmp .exit    

.exit_false:
    mov al, 0

.exit:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12

    ret

;-----------------------------
; Function: Egg_UpdatePosition
; Description: Choose a new spot for the egg
; Args: rdi = this
; Returns: None
;-----------------------------
Egg_UpdatePosition:
    push r12
    mov r12, rdi                        ; r12 = this

    mov rdi, [r12 + Egg_buffer]         ; rsi = screen buffer
    mov rsi, [r12 + Egg_bufferLen]      ; rdx = screen buffer length
    mov dl, [r12 + Egg_backgroundChar]  ; dl = background char
    call Egg_GetNumAvailableSpaces

    mov rdi, rax
    call Egg_GetRand

    mov rdi, r12
    mov rsi, rax
    call Egg_PlaceEgg

    pop r12

    ret

;-----------------------------
; Function: Egg_GetNumAvailableSpaces
; Description: Calculates the number of available
;               spaces in the screen buffer
; Args:
;   rdi = screen buffer
;   rsi = screen buffer length
;   dl = background character
; Returns: rax = num available spaces
;-----------------------------
Egg_GetNumAvailableSpaces:
    xor r10, r10        ; Loop counter
    xor rax, rax        ; Num spaces
.loop:
    cmp r10, rsi
    je .loop_exit

    cmp dl, [rdi + r10]
    jne .loop_continue

    inc rax

.loop_continue:
    inc r10
    jmp .loop

.loop_exit:
    ret

;-----------------------------
; Function: Egg_GetRand
; Description: Return a random integer
; Args: rdi = threshold
; Returns: eax = random value [0, threshold)
;-----------------------------
Egg_GetRand:
    push rbx

.retry:
    rdrand rax
    jnc .retry
    xor rdx, rdx
    mov rbx, rdi
    div rbx

    mov eax, edx

    pop rbx
    ret

;-----------------------------
; Function: Egg_PlaceEgg
; Description: Place the egg in the screen buffer
;               based on an offset of the number of
;               background characters encountered
; Args:
;   rdi = this
;   rsi = placement offset
; Returns: rax = result
;-----------------------------
Egg_PlaceEgg:
    mov r8, [rdi + Egg_buffer]          ; r8 = screen buffer
    mov r9b, [rdi + Egg_backgroundChar] ; r9b = backgroud char
    mov r10b, [rdi + Egg_eggChar]       ; r10b = egg char
    xor r11, r11                        ; r11 = buffer index
    xor rdx, rdx                        ; rdx = background characters encountered

.loop:
    cmp rsi, rdx
    je .loop_exit

    cmp [r8 + r11], r9b
    jne .continue

    inc rdx

.continue:
    inc r11
    jmp .loop

.loop_exit:

    mov [rdi + Egg_eggIdx], r11
    mov [r8 + r11], r10b

    ret