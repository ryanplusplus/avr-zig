BUILD_DIR:=build

LD=avr-ld
OBJDUMP=avr-objdump
OBJCOPY=avr-objcopy
LPATH=-L/usr/lib/gcc/avr/5.4.0/avr5
LARCH=-mavr5
LIBS=/usr/lib/avr/lib/avr5/crtatmega328p.o -lgcc
MCU=atmega328p
TARGET=-mmcu=$(MCU)
PROGRAM=avrdude
PROGRAM_CFG=/etc/avrdude.conf
PROGRAM_DEV=/dev/ttyACM0
EXECUTABLES=$(basename $(wildcard *.c)) $(basename $(wildcard *.zig))
ALL=$(foreach f, $(EXECUTABLES), $(f).s $(f).dmp $(f).hex)

.PHONY: default
default: $(BUILD_DIR)/main.hex

%.dmp: %.elf
	@$(OBJDUMP) -d -S -l $< > $@

.PRECIOUS: $(BUILD_DIR)/%.s
$(BUILD_DIR)/%.s: %.zig
	@echo Compiling $@...
	@mkdir -p $(dir $@)
	@zig build-obj -femit-asm -fno-emit-bin --strip -O ReleaseSmall -target avr-freestanding-none -mcpu=$(MCU) $<

.PRECIOUS: $(BUILD_DIR)/%.o
$(BUILD_DIR)/%.o: %.zig
	@echo Compiling $@...
	@mkdir -p $(dir $@)
	@zig build-obj --strip -O ReleaseSmall -target avr-freestanding-none -mcpu=$(MCU) -femit-bin=$@ $<

.PRECIOUS: $(BUILD_DIR)/%.elf
$(BUILD_DIR)/%.elf: $(BUILD_DIR)/%.o
	@echo Linking $@...
	@mkdir -p $(dir $@)
	@$(LD) $(LARCH) -o $@ $(LPATH) $^ $(LIBS)

.PRECIOUS: $(BUILD_DIR)/%.hex
$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf
	@echo Creating $@...
	@mkdir -p $(dir $@)
	@$(OBJCOPY) -O ihex $< $@

.PRECIOUS: $(BUILD_DIR)/%.bin
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf
	@echo Creating $@...
	@mkdir -p $(dir $@)
	@$(OBJCOPY) -O binary $< $@

upload-%.elf: $(BUILD_DIR)/%.elf
	@echo Uploading $<...
	@$(PROGRAM) -C$(PROGRAM_CFG) -v -V -patmega328p -carduino -P$(PROGRAM_DEV) -b115200 -D -Uflash:w:$<:e

upload-%.hex: $(BUILD_DIR)/%.hex
	@echo Uploading $<...
	@$(PROGRAM) -C$(PROGRAM_CFG) -v -V -patmega328p -carduino -P$(PROGRAM_DEV) -b115200 -D -Uflash:w:$<:i

.PHONY: clean
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
