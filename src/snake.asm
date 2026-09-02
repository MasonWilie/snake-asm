%include "snake_node.inc"
%include "snake.inc"

; snake_node.asm
extern SnakeNode_ctor
extern SnakeNode_ConflictingDirections
extern SnakeNode_UpdatePosition

; memory.asm
extern alloc
extern dealloc

; class Snake {
;  public:
;   Snake_ctor(Snake* this, int initX, int initY, int maxX, int maxY);
;   Snake_dtor();
;
;   void Update(SnakeDirection newDirection);
;   void Draw(DrawFn*);
;
;  private:
;   void Snake_SetDirection(SnakeDirection newDirection);
;   void Snake_UpdatePositions();
;   SnakeNode* head;
; };



section .text

    global Snake_ctor
    global Snake_dtor
    global Snake_Update
    global Snake_Draw

;-----------------------------
; Function: Snake_ctor
; Description: Construct a snake
; Args:
;   rdi = Snake* (preallocated, uninitialized)
;   esi = Initial x position
;   edx = Initial y position
;   ecx = Max x position
;   r8d = Max y position
; Returns:  rax = result
;-----------------------------
Snake_ctor:
    push rbx
    push rbp
    push r12

    mov rbx, rdi        ; rbx = Snake*
    mov ebp, esi        ; ebp = initial x
    mov r12d, edx       ; r12d = initial y

    ; Set bounds
    mov [rdi + Snake_maxX], ecx
    mov [rdi + Snake_maxY], r8d

    ; Allocate an uninitialized section of memory for the head node
    mov edi, SnakeNode_size
    call alloc
    mov qword [rbx + Snake_head], rax

    ; Construct the head node
    mov rdi, qword [rbx + Snake_head]
    mov esi, ebp
    mov edx, r12d
    mov cl, SnakeDirection_LEFT
    call SnakeNode_ctor

    pop r12
    pop rbp
    pop rbx

    ret

;-----------------------------
; Function: Snake_dtor
; Description: Destructs a snake object
; Args: rdi = Snake* this
; Returns: None
;-----------------------------
Snake_dtor:
    sub rsp, 8

    mov rdi, qword [rdi + Snake_head]
    mov esi, SnakeNode_size
    call dealloc

    add rsp, 8
    ret

;-----------------------------
; Function: Snake_Update
; Description: Update the snake's direction and position
; Args: rdi = this, sil = New direction
; Returns: rax = result
;-----------------------------
Snake_Update:
    push rbx

    mov rbx, rdi

    call Snake_TrySetDirection

    mov rdi, rbx
    call Snake_UpdatePositions

    pop rbx
    ret

;-----------------------------
; Function: Snake_TrySetDirection
; Description:  Try to set the direction of the sanake
;               fails for invalid directions (moving
;               back into the next segment) 
; Args: rdi = this, sil = New direction
; Returns: None
;-----------------------------
Snake_TrySetDirection:
    push r12
    push r13
    sub rsp, 8

    mov r12, rdi
    mov r13d, esi

    ; Don't update if new direction is invalid
    cmp r13b, SnakeDirection_INVALID
    je .exit

    mov rcx, qword [r12 + Snake_head]               ; rcx = SnakeNode* head

    ; If the direction doesn't actually change, move on
    cmp r13b, [rcx + SnakeNode_direction]
    je .exit

    mov rdx, qword [rcx + SnakeNode_nextNode]       ; rdx = head->nextNode
    
    ; If there is no next node, can be any direction
    cmp rdx, 0
    je .set_direction

    ; Check to see if the new direction conflicts with the next node
    mov dil, [rdx + SnakeNode_direction]
    mov sil, r13b
    call SnakeNode_ConflictingDirections
    test al, al
    jnz .exit

    ; Recompute head address because it was clobbered
    mov rcx, [r12 + Snake_head]

.set_direction:
    mov byte [rcx + SnakeNode_direction], r13b

.exit:
    add rsp, 8
    pop r13
    pop r12
    ret

;-----------------------------
; Function: Snake_UpdatePositions
; Description: Update the position of the snake nodes
; Args:
;   rdi = this
; Returns: None
;-----------------------------
Snake_UpdatePositions:
    push rbx
    push r12
    push r13

    mov rbx, [rdi + Snake_head]
    mov r12d, [rdi + Snake_maxX]
    mov r13d, [rdi + Snake_maxY]

.loop:

    mov rdi, rbx
    mov esi, r12d
    mov edx, r13d
    call SnakeNode_UpdatePosition

    mov rbx, [rbx + SnakeNode_nextNode]
    cmp rbx, 0
    jne .loop

; End loop

    pop r13
    pop r12
    pop rbx

    ret

;-----------------------------
; Function: Snake_Draw
; Description: Draw the snake node
; Args: rdi = this, rsi = Function ptr
; Returns: rax = result
;-----------------------------
Snake_Draw:
    push r12 ; function pointer
    push r13 ; Node ptr
    sub rsp, 8

    mov r12, rsi
    mov r13, [rdi + Snake_head]

.loop:
    cmp r13, 0
    je .exit

    mov edi, [r13 + SnakeNode_x]
    mov esi, [r13 + SnakeNode_y]

    call r12

    mov r13, [r13 + SnakeNode_nextNode]

    jmp .loop

; end loop

.exit:
    add rsp, 8
    pop r13
    pop r12

    ret