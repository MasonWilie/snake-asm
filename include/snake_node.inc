%ifndef SNAKE_NODE_INC
%define SNAKE_NODE_INC



SnakeDirection_INVALID equ 0
SnakeDirection_UP equ 1
SnakeDirection_DOWN equ 2
SnakeDirection_RIGHT equ -1
SnakeDirection_LEFT equ -2

; struct SnakeNode {
;     int x;
;     int y;
;     SnakeNode* nextNode{nullptr};
;     int8_t direction;
;     std::array<uint8_t, 7> padding;
; };

SnakeNode_x         equ 0
SnakeNode_y         equ 4
SnakeNode_nextNode  equ 8
SnakeNode_direction equ 16
SnakeNode_size      equ 24 ; (Padding for alignment)

%endif