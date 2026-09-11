%ifndef EGG_INC
%define EGG_INC

; class Egg {
;  public:
;     ctor(char*, bufferLen, backgroundChar, snakeChar, eggChar);
;     bool checkAndUpdate();

;  private:
;     void UpdatePosition();

;     char* buffer;
;     size_t buffer_len;
;     size_t eggIdx;
;     char backgroundChar;
;     char snakeChar;
;     char eggChar;
; };

Egg_buffer equ 0
Egg_bufferLen equ 8
Egg_eggIdx equ 16
Egg_backgroundChar equ 24
Egg_snakeChar equ 25
Egg_eggChar equ 26
Egg_paddingStart equ 27
Egg_size equ 32

%endif