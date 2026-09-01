section .bss
    ts_req resq 2

section .text

global sleep_ms

;-----------------------------
; Function: sleep_ms
; Args:     rdi = ms to sleep
; Returns:  rax = None
;-----------------------------
sleep_ms:
    mov rax, rdi
    xor rdx, rdx
    mov rcx, 1000
    div rcx
    mov [ts_req], rax

    imul rdx, rdx, 1000000
    mov [ts_req + 8], rdx

    mov rax, 35
    mov rdi, ts_req
    xor rsi, rsi
    syscall

    ret