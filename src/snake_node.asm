%include "snake_node.inc"

section .text

global SnakeNode_ctor
global SnakeNode_ConflictingDirections
global SnakeNode_UpdatePosition

;-----------------------------
; Function: SnakeNode_ctor
; Description: Construct a SnakeNode
; Args:
;   rdi = SnakeNode* (pre-allocated)
;   esi = x
;   edx = y
;   cl = direction
; Returns:  None (Constructs in-place)
;-----------------------------
SnakeNode_ctor:
    mov dword [rdi + SnakeNode_x], esi
    mov dword [rdi + SnakeNode_y], edx
    mov byte [rdi + SnakeNode_direction], cl
    mov qword [rdi + SnakeNode_nextNode], 0
    ret

;-----------------------------
; Function: SnakeNode_ConflictingDirections
; Description: Check if the directions oppose eachother
; Args: dil = direction one, sil = direction two
; Returns: al = 0 if not conflicting, 1 if conflicting
;-----------------------------
SnakeNode_ConflictingDirections:
    ; Not conflicting if they are the same direction
    cmp dil, sil
    je .exit_success
    
    ; If they are the same sign, then they are conflicting
    movsx eax, dil
    movsx ecx, sil
    imul eax, ecx
    cmp dil, 0
    jg .exit_fail

.exit_success:
    xor al, al
    ret

.exit_fail:
    mov al, 1
    ret

;-----------------------------
; Function: SnakeNode_UpdatePosition
; Description: Update the position of a snake node
; Args:
;   rdi = this
;   esi = max x
;   edx = max y
; Returns: None
;-----------------------------
SnakeNode_UpdatePosition:
    mov cl, [rdi + SnakeNode_direction]

    cmp cl, SnakeDirection_UP
    je .move_up

    cmp cl, SnakeDirection_DOWN
    je .move_down

    cmp cl, SnakeDirection_LEFT
    je .move_left

    cmp cl, SnakeDirection_RIGHT
    je .move_right

.move_up:
    dec dword [rdi + SnakeNode_y]
    jmp .exit

.move_down:
    inc dword [rdi + SnakeNode_y]
    jmp .exit

.move_left:
    dec dword [rdi + SnakeNode_x]
    jmp .exit

.move_right:
    inc dword [rdi + SnakeNode_x]
    jmp .exit

.exit:
    ; All arguments still in place
    call SnakeNode_WrapPosition

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