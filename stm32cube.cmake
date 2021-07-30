# 1. set variable MCU_TYPE and STM32CUBE_PATH(default to stm32cube)
# 2. change global options as you like

# global compile and link options
add_compile_options(
        -Wall
        -fdata-sections
        -ffunction-sections
        -fno-exceptions
        $<$<CONFIG:Debug>:-Og>)
add_link_options(-specs=nano.specs -lc -lm -lnosys)
#add_link_options(-specs=nosys.specs -lc -lm -lnosys)


if (NOT STM32CUBE_PATH)
    set(STM32CUBE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/stm32cube)
endif ()
add_subdirectory(stm32cube-cmake)

add_compile_options(${MCU})
add_link_options(${MCU})

# Create hex file
function(generate_binary_file EXECUTABLE_TARGET)
    string(REPLACE ".elf" "" TARGET_NOEXT ${EXECUTABLE_TARGET})
    add_custom_command(TARGET ${EXECUTABLE_TARGET}
            POST_BUILD
            COMMAND arm-none-eabi-objcopy -O ihex ${EXECUTABLE_TARGET} ${TARGET_NOEXT}.hex
            COMMAND arm-none-eabi-objcopy -O binary ${EXECUTABLE_TARGET} ${TARGET_NOEXT}.bin
            )
endfunction()

# Print executable size
function(print_executable_size EXECUTABLE_TARGET)
    add_custom_command(TARGET ${EXECUTABLE_TARGET}
            POST_BUILD
            COMMAND arm-none-eabi-size ${EXECUTABLE_TARGET})
endfunction()

