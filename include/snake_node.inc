%ifndef SNAKE_NODE_INC
%define SNAKE_NODE_INC

; struct SnakeNode {
;   int x;
;   int y;
;   SnakeNode* nextNode{nullptr};
;   SnakeNode* prevNode{nullptr};
; };

SnakeNode_x         equ 0
SnakeNode_y         equ 4
SnakeNode_nextNode  equ 8
SnakeNode_prevNode  equ 16
SnakeNode_size      equ 24

%endif