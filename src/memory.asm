PROT_READ_WRITE equ 3           ; PROD_READ (1) | PROT_WRITE (2)
MAP_PRIVATE_ANONYMOUS equ 0x22  ; MAP_PRIVATE (0x02) | MAP_ANONYMOUS (0x20)
SYS_MMAP equ 9
SYS_MUNMAP equ 11
SYS_WRITE equ 1
STDOUT equ 1
SYS_EXIT equ 60

section .data:
    failed_to_alloc_msg db "Failed to allocate memory", 10, 0
    failed_to_alloc_msg_len equ $ - failed_to_alloc_msg

section .text
    global alloc
    global dealloc

;-----------------------------
; Function: alloc
; Description: Allocates memory
; Args: rdi = size in bytes of memory to allocate
; Returns: rax = resulting pointer to allocated memory
;-----------------------------
alloc:
    mov rax, SYS_MMAP
    mov rsi, rdi                    ; Set length
    xor rdi, rdi                    ; Let kernel choose address
    mov rdx, PROT_READ_WRITE        ; Set readable/writeable
    mov r10, MAP_PRIVATE_ANONYMOUS  ; Set private/anonymous
    mov r8, -1                      ; No file-descriptor
    xor r9, r9                      ; Offset = 0
    syscall

    cmp rax, 0
    jge .return

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, failed_to_alloc_msg
    mov rdx, failed_to_alloc_msg_len
    syscall

    ;; exit
    mov rax, SYS_EXIT
    mov rdi, -1
    syscall

.return:

    ret                             ; Address already stored in rax

;-----------------------------
; Function: dealloc
; Description: Deallocate memory
; Args: rdi = ptr, rsi = size
; Returns: None
;-----------------------------
dealloc:
    mov rax, SYS_MUNMAP
    syscall                         ; dealloc function arguments are the same for mmunmap
    ret
