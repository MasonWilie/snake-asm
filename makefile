ASM      = nasm
ASMFLAGS = -f elf64 -g -F dwarf -I $(INC_DIR)/
LD       = ld
LDFLAGS  =

SRC_DIR   = src
INC_DIR   = include
BUILD_DIR = build
BIN_DIR   = bin

SRCS = $(wildcard $(SRC_DIR)/*.asm)
OBJS = $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/%.o,$(SRCS))
DEPS = $(patsubst $(SRC_DIR)/%.asm,$(BUILD_DIR)/%.d,$(SRCS))
BIN  = $(BIN_DIR)/main

all: $(BIN)

$(BIN): $(OBJS) | $(BIN_DIR)
	$(LD) $(LDFLAGS) -o $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.asm | $(BUILD_DIR)
	$(ASM) $(ASMFLAGS) -MD $(BUILD_DIR)/$*.d $< -o $@

$(BUILD_DIR) $(BIN_DIR):
	mkdir -p $@

-include $(DEPS)

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

.PHONY: all clean