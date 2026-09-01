
KernelSigAction_handler_ptr equ 0
KernelSigAction_flags equ 8
KernelSigAction_restorer equ 16
KernelSigAction_mask equ 24
KernelSigAction_size equ 32

SA_RESTORER equ 0x04000000

SYSCALL_SIG_ACTION equ 13
SYSCALL_SIG_RETURN equ 15

section .text
    global sig_install

;-----------------------------
; Function: sig_install
; Description: Install a signal handler
; Args:     rdi = sig number, rsi = handler function pointer
; Returns:  None
;-----------------------------
sig_install:
    mov r8, rsi                                     ; r8 = handler ptr

    sub rsp, KernelSigAction_size                   ; Reserve size on the stack for Ker
    mov [rsp + KernelSigAction_handler_ptr], r8     ; Set signal handler
    mov qword [rsp + KernelSigAction_flags], SA_RESTORER
    lea rax, [rel sig_return]
    mov [rsp + KernelSigAction_restorer], rax
    mov qword [rsp + KernelSigAction_mask], 0

    mov rsi, rsp                                    ; Action
    xor rdx, rdx                                    ; Old action = NULL
    mov r10, 8                                      ; sizeof(sigset_t)
    mov rax, SYSCALL_SIG_ACTION
    syscall

    add rsp, KernelSigAction_size
    ret

;-----------------------------
; Function: sig_return
; Description: Stub to return from the signal action
; Args:     None
; Returns:  None
;-----------------------------
sig_return:
    mov rax, SYSCALL_SIG_RETURN
    syscall