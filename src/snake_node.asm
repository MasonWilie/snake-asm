%include "snake_node.inc"

section .text

global SnakeNode_ctor

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
