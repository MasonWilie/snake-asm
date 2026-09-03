%include "snake_node.inc"
%include "snake.inc"

; snake_node.asm
extern SnakeNode_ctor
extern SnakeNode_UpdatePosition
extern SnakeNode_SetNext
extern SnakeNode_GetNext

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
;   
;   Direction direction;
;   SnakeNode* head;
;   SnakeNode* tail;
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

    mov [rdi + Snake_maxX], ecx
    mov [rdi + Snake_maxY], r8d
    mov byte [rdi + Snake_direction], SnakeDirection_LEFT

    ; Allocate an uninitialized section of memory for the head node
    mov edi, SnakeNode_size
    call alloc
    mov qword [rbx + Snake_head], rax

    ; Head is also the tail until a second node is added
    mov qword [rbx + Snake_tail], rax

    ; Construct the head node
    mov rdi, qword [rbx + Snake_head]
    mov esi, ebp
    mov edx, r12d
    mov rcx, 0
    call SnakeNode_ctor

    ; Add the second node, one cell to the right of the head
    mov r8, [rbx + Snake_head]      ; r8 = head
    mov esi, [r8 + SnakeNode_x]
    inc esi
    mov edx, [r8 + SnakeNode_y]
    mov rdi, rbx
    call Snake_AddNode

    xor eax, eax                    ; return success

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
    push r8
    push r9
    sub rsp, 8

    mov r8, qword [rdi + Snake_head]
.loop:
    mov rdi, r8
    call SnakeNode_GetNext
    mov r9, rax

    mov rdi, r8
    mov esi, SnakeNode_size
    call dealloc

    cmp r9, 0
    je .end_loop

    mov r8, r9
    jmp .loop

.end_loop:

    add rsp, 8
    pop r9
    pop r8

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

    ; If the direction is unchanged, do nothing
    mov r8b, byte [rdi + Snake_direction]
    cmp r8b, sil
    je .exit

    ; If the direction is invalid, do nothing
    cmp sil, SnakeDirection_INVALID
    je .exit

    ; Save args before function call
    mov r12, rdi                        ; r12 = this
    mov r13b, sil                       ; r13b = new direction

    mov dil, r13b
    call Snake_GetDxDyFromDirection     ; eax = dx, edx = dy

    mov r8, [r12 + Snake_head]          ; r8 = head

    ; If there is no next node, nothing to conflict with
    mov r11, [r8 + SnakeNode_nextNode]  ; r11 = head->next
    cmp r11, 0
    je .set_direction

    ; Simluate moving the head in that direction
    mov r9d, [r8 + SnakeNode_x]         ; r9d = head->x
    mov r10d, [r8 + SnakeNode_y]        ; r10d = head->y
    add r9d, eax
    add r10d, edx

    mov eax, [r11 + SnakeNode_x]        ; eax = head->nextNode->x
    mov edx, [r11 + SnakeNode_y]        ; edx = head->nextNode->y

    cmp r9d, eax
    jne .set_direction

    cmp r10d, edx
    je .exit

.set_direction:
    mov byte [r12 + Snake_direction], r13b

.exit:
    add rsp, 8
    pop r13
    pop r12
    ret


;-----------------------------
; Function: Snake_GetDxDyFromDirection
; Description: Get the change in X and Y given the direction
; Args: dil = direction
; Returns: eax = dx, edx = dy
;-----------------------------
Snake_GetDxDyFromDirection:
    cmp dil, SnakeDirection_UP
    je .up

    cmp dil, SnakeDirection_DOWN
    je .down

    cmp dil, SnakeDirection_LEFT
    je .left

    cmp dil, SnakeDirection_RIGHT
    je .right

    jmp .unknown_direction
.up:
    xor eax, eax
    mov edx, -1
    ret

.down:
    xor eax, eax
    mov edx, 1
    ret

.left:
    mov eax, -1
    xor edx, edx
    ret

.right:
    mov eax, 1
    xor edx, edx
    ret

.unknown_direction:
    xor eax, eax
    xor edx, edx
    ret

Snake_UpdatePositions:
    push r12
    mov r12, rdi                        ; r12 = this
    mov dil, byte [rdi + Snake_direction]
    call Snake_GetDxDyFromDirection     ; eax = dx, edx = dy

    ; Simluate moving the head in that direction
    mov r8, [r12 + Snake_head]          ; r8 = head
    mov r9d, [r8 + SnakeNode_x]         ; r9d = head->x
    add r9d, eax
    mov r10d, [r8 + SnakeNode_y]        ; r10d = head->y
    add r10d, edx

    mov r11, [r12 + Snake_tail]         ; r11 = tail
    cmp r8, r11
    je .single_node                     ; head == tail -> only one node

    ; Move the tail to the new position
    mov [r11 + SnakeNode_x], r9d
    mov [r11 + SnakeNode_y], r10d

    ; Save old tail's old prev
    mov r9, [r11 + SnakeNode_prevNode]

    ; Define the new head
    mov [r12 + Snake_head], r11
    mov [r8 + SnakeNode_prevNode], r11
    mov qword [r11 + SnakeNode_prevNode], 0
    mov [r11 + SnakeNode_nextNode], r8

    ; Define the new tail
    mov [r12 + Snake_tail], r9
    mov qword [r9 + SnakeNode_nextNode], 0
    jmp .exit

.single_node:
    ; Only one node: just update its position in place
    mov [r8 + SnakeNode_x], r9d
    mov [r8 + SnakeNode_y], r10d

.exit:
    pop r12
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

;-----------------------------
; Function: Snake_AddNode
; Description: Add a node to the end of the snake
; Args:
;   rdi = this
;   esi = x
;   edx = y
; Returns: None
;-----------------------------
Snake_AddNode:
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8

    mov r12, rdi
    mov r13d, esi
    mov r14d, edx

    ; Allocate an uninitialized section of memory for the new node
    mov edi, SnakeNode_size
    call alloc
    mov r15, rax                    ; r15 = new node

    mov r8, [r12 + Snake_tail]
    test r8, r8
    jz .empty

    mov [r8 + SnakeNode_nextNode], r15
    mov [r12 + Snake_tail], r15
    jmp .construct

.empty:
    mov [r12 + Snake_head], r15
    mov [r12 + Snake_tail], r15
    xor r8, r8                      ; prevNode = 0 for construction

.construct:
    ; Construct node
    mov rdi, r15
    mov esi, r13d
    mov edx, r14d
    mov rcx, r8
    call SnakeNode_ctor

    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    ret