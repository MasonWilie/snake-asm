%include "snake_node.inc"

section .text

global SnakeNode_ctor
global SnakeNode_UpdatePosition
global SnakeNode_SetNext
global SnakeNode_GetNext

;-----------------------------
; Function: SnakeNode_ctor
; Description: Construct a SnakeNode
; Args:
;   rdi = SnakeNode* (pre-allocated)
;   esi = x
;   edx = y
;   rcx = SnakeNode* prevNode
; Returns:  None (Constructs in-place)
;-----------------------------
SnakeNode_ctor:
    mov dword [rdi + SnakeNode_x], esi
    mov dword [rdi + SnakeNode_y], edx
    mov qword [rdi + SnakeNode_prevNode], rcx
    mov qword [rdi + SnakeNode_nextNode], 0
    ret

;-----------------------------
; Function: SnakeNode_SetNext
; Description: Set the next node
; Args:
;   rdi = this
;   rsi = next
; Returns: rax = result
;-----------------------------
SnakeNode_SetNext:
    mov [rdi + SnakeNode_nextNode], rsi
    ret

;-----------------------------
; Function: SnakeNode_GetNext
; Description: Get the next node
; Args: rdi = this
; Returns: rax = this->nextNode
;-----------------------------
SnakeNode_GetNext:
    mov rax, [rdi + SnakeNode_nextNode]
    ret

;-----------------------------
; Function: SnakeNode_UpdatePosition
; Description: Update the position of a snake node
; Args:
;   rdi = this
;   esi = max x
;   edx = max y
;   ecx = dx
;   r8d = dy
; Returns: None
;-----------------------------
SnakeNode_UpdatePosition:
    sub rsp, 8

    ; Move X
    mov r9d, [rdi + SnakeNode_x]
    add r9d, ecx
    mov [rdi + SnakeNode_x], r9d

    ; Move Y
    mov r9d, [rdi + SnakeNode_y]
    add r9d, r8d
    mov [rdi + SnakeNode_y], r9d

    ; rdi = this, esi = max x, edx = max y
    call SnakeNode_WrapPosition

    add rsp, 8
    ret

;-----------------------------
; Function: SnakeNode_WrapPosition
; Description: Wrap the position of the snake node around
;               the screen if applicable
; Args:
;   rdi = this
;   esi = max x
;   edx = max y
; Returns: None
;-----------------------------
SnakeNode_WrapPosition:

.check_lower_x:
    cmp dword [rdi + SnakeNode_x], 0
    jge .check_upper_x
    mov [rdi + SnakeNode_x], esi
    jmp .exit

.check_upper_x:
    cmp [rdi + SnakeNode_x], esi
    jle .check_lower_y
    mov dword [rdi + SnakeNode_x], 0
    jmp .exit

.check_lower_y:
    cmp dword [rdi + SnakeNode_y], 0
    jge .check_upper_y
    mov [rdi + SnakeNode_y], edx
    jmp .exit

.check_upper_y:
    cmp [rdi + SnakeNode_y], edx
    jle .exit
    mov dword [rdi + SnakeNode_y], 0
    jmp .exit

.exit:
    ret