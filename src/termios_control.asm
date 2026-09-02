Termios_size equ 60

section .bss
    original_termios resb Termios_size
    new_termios resb Termios_size

section .text

global enable_raw_input
global disable_raw_input

;-----------------------------
; Function: enable_raw_input
; Description: Disabled cononical input and enables raw for non-buffered input
; Args:     None
; Returns:  None
;-----------------------------
enable_raw_input:
    ; Get the current termios
    mov eax, 16                 ; IOCTL
    mov edi, 0                  ; STDIN
    mov esi, 0x5401             ; TCGETS
    mov rdx, original_termios
    syscall

    ; Copy the original termios into the new buffer
    mov rsi, original_termios
    mov rdi, new_termios
    mov ecx, Termios_size
    cld
    rep movsb

    ; Clear canonical and echo bits
    mov eax, [new_termios + 12]
    and eax, 0xFFFFFFF5
    mov [new_termios + 12], eax

    mov byte [new_termios + 17 + 6], 0  ; VMIN = 0
    mov byte [new_termios + 17 + 5], 0  ; VTIME = 0

    ; Set the new termios
    mov eax, 16
    mov edi, 0                  ; STDIN
    mov esi, 0x5402             ; TCSETS
    mov rdx, new_termios
    syscall

    ret

;-----------------------------
; Function: disable_raw_input
; Description: Reverts the termios to the original struct
; Args:     None
; Returns:  None
;-----------------------------
disable_raw_input:
    mov eax, 16
    mov edi, 0                  ; STDIN
    mov esi, 0x5402             ; TCSETS
    mov rdx, original_termios
    syscall
    ret