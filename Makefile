TARGET := blink

TRIPLE  = 	arm-none-eabi
CC 		=	${TRIPLE}-gcc
LD 		= 	${TRIPLE}-ld
AS 		= 	${TRIPLE}-as
GDB 	= 	${TRIPLE}-gdb
OBJCOPY =  	${TRIPLE}-objcopy
SIZE =  	${TRIPLE}-size

OPENOCD_BASE = /opt/openocd
BUILD_DIR := build
SRC_DIRS := src hal/src
INC_DIRS := include hal/include hal/include/legacy cmsis/include

INCFLAGS := $(addprefix -I,$(INC_DIRS))
CFLAGS := -mcpu=cortex-m3 -mfloat-abi=soft -mthumb -g3 -std=gnu11 --specs=nano.specs -DDEBUG -DUSE_HAL_DRIVER -DSTM32F103xB $(INCFLAGS) -O0 -ffunction-sections -fdata-sections -Wall -fstack-usage -MMD -MP
LDFLAGS := -mcpu=cortex-m3 -mfloat-abi=soft -mthumb --specs=nosys.specs -Wl,--gc-sections -static  -Wl,--start-group -lc -lm -Wl,--end-group
ASFLAGS := -mcpu=cortex-m3 -mfloat-abi=soft -mthumb -g3 --specs=nano.specs -DDEBUG -x assembler-with-cpp -MMD -MP 
	
SRCS := $(shell find $(SRC_DIRS) -name '*.c')
SRSS := $(shell find $(SRC_DIRS) -name '*.s')

OBJS := $(SRSS:%.s=$(BUILD_DIR)/%.o) $(SRCS:%.c=$(BUILD_DIR)/%.o) 


$(BUILD_DIR)/$(TARGET).elf: $(OBJS) STM32F103C8TX_FLASH.ld
	@echo "LD => " $@
	@$(CC) -o $@ $(OBJS) -T"STM32F103C8TX_FLASH.ld" $(LDFLAGS) -Wl,-Map="$(BUILD_DIR)/$(TARGET).map"
	$(SIZE) $@


$(BUILD_DIR)/%.o: %.c
	@echo "CC " $< "=>" $@
	@mkdir -p $(dir $@)
	@$(CC) -c $< $(CFLAGS) -MT"$@" -o $@


$(BUILD_DIR)/%.o: %.s
	@echo "AS " $< "=>" $@
	@mkdir -p $(dir $@)
	@$(CC) $(ASFLAGS) -c $< -MF"build/src/startup_stm32f103c8tx.d" -MT"$@" -o $@

flash:
	openocd -d2 -s $(OPENOCD_BASE)/scripts -f interface/stlink.cfg -c "transport select hla_swd" -f target/stm32f1x.cfg -c "program {$(BUILD_DIR)/$(TARGET).elf}  verify reset; shutdown;"


clean:
	rm -rf $(BUILD_DIR)