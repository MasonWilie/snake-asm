%ifndef SNAKE_INC
%define SNAKE_INC

SnakeDirection_INVALID equ 0
SnakeDirection_UP equ 1
SnakeDirection_DOWN equ 2
SnakeDirection_RIGHT equ -1
SnakeDirection_LEFT equ -2

Snake_head equ 0
Snake_tail equ 8
Snake_maxX equ 16
Snake_maxY equ 20
Snake_direction equ 24
Snake_size equ 32           ; 7 bytes of padding

%endif