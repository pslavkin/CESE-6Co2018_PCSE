# application name
PROJECT_NAME := $(notdir $(PROJECT))

# Modules needed by the application
PROJECT_MODULES := modules/$(TARGET)/sapi \
                   modules/$(TARGET)/fatfs_ssp \
                   modules/$(TARGET)/base \
                   modules/$(TARGET)/board \
                   modules/$(TARGET)/chip

# source files folder
PROJECT_SRC_FOLDERS := $(PROJECT)/src

# header files folder
PROJECT_INC_FOLDERS := $(PROJECT)/inc

# source files
PROJECT_C_FILES := $(wildcard $(PROJECT)/src/*.c)
PROJECT_ASM_FILES := $(wildcard $(PROJECT)/src/*.S)
