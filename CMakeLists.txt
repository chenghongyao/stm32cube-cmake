
string(REGEX MATCH "^STM32([A-Z][0-9])_?(M[47])?" MCU_FAMILY ${MCU_TYPE})

if (${MCU_FAMILY} STREQUAL "STM32F1")
        set(CPU "-mcpu=cortex-m3")
        set(FPU "")
        set(FLOAT-ABI "")
elseif(${MCU_FAMILY} STREQUAL "STM32F4")
        set(CPU "-mcpu=cortex-m4")
        set(FPU "-mfpu=fpv4-sp-d16" )
        set(FLOAT-ABI "-mfloat-abi=hard")
elseif(${MCU_FAMILY} STREQUAL "STM32L0")
        set(CPU "-mcpu=cortex-m0plus")
        set(FPU "")
        set(FLOAT-ABI "")
endif()
set(MCU_ ${CPU} -mthumb ${FPU} ${FLOAT-ABI})
set(MCU ${MCU_} PARENT_SCOPE)


file(GLOB LINKER_SCRIPT ${STM32CUBE_PATH}/*.ld)
file(GLOB SETUP_ASM ${STM32CUBE_PATH}/*.s)

# CMISS
add_library(cmiss INTERFACE)
target_include_directories(cmiss
        INTERFACE
        ${STM32CUBE_PATH}/Drivers/CMSIS/Device/ST/${MCU_FAMILY}xx/Include
        ${STM32CUBE_PATH}/Drivers/CMSIS/Include
        )
target_compile_options(cmiss INTERFACE ${MCU_})
target_compile_definitions(cmiss INTERFACE -D${MCU_TYPE})
add_library(stm32cube::cmiss ALIAS cmiss)

# HAL
add_library(stm32cube_hal)
target_link_libraries(stm32cube_hal PUBLIC cmiss)
aux_source_directory(${STM32CUBE_PATH}/Drivers/${MCU_FAMILY}xx_HAL_Driver/Src HAL_SOURCES)
target_sources(stm32cube_hal PRIVATE ${HAL_SOURCES})
target_include_directories(stm32cube_hal
        PUBLIC
        ${STM32CUBE_PATH}/Drivers/${MCU_FAMILY}xx_HAL_Driver/Inc
        ${STM32CUBE_PATH}/Drivers/${MCU_FAMILY}xx_HAL_Driver/Inc/Legacy
        ${STM32CUBE_PATH}/Core/Inc
        )
target_compile_definitions(stm32cube_hal PUBLIC -DUSE_HAL_DRIVER)
add_library(stm32cube::hal ALIAS stm32cube_hal)





# middlewares
## fatfs
if(
        EXISTS ${STM32CUBE_PATH}/FATFS
        AND
        EXISTS ${STM32CUBE_PATH}/Middlewares/Third_Party/FatFs)

        set(STM32CUBE_FATFS_LIB stm32cube_fatfs)
        aux_source_directory(${STM32CUBE_PATH}/FATFS/App STM32CUBE_FATFS_APP_SRCS)
        aux_source_directory(${STM32CUBE_PATH}/FATFS/Target STM32CUBE_FATFS_TARGET_SRCS)
        aux_source_directory(${STM32CUBE_PATH}/Middlewares/Third_Party/FatFs/src/option STM32CUBE_FATFS_OPTION_SRCS)
        aux_source_directory(${STM32CUBE_PATH}/Middlewares/Third_Party/FatFs/src STM32CUBE_FATFS_SRCS)

        add_library(${STM32CUBE_FATFS_LIB})
        target_sources(${STM32CUBE_FATFS_LIB}
                PRIVATE
                ${STM32CUBE_FATFS_APP_SRCS}
                ${STM32CUBE_FATFS_TARGET_SRCS}
                ${STM32CUBE_FATFS_OPTION_SRCS}
                ${STM32CUBE_FATFS_SRCS}
                )

        target_include_directories(stm32cube_hal
                PUBLIC
                ${STM32CUBE_PATH}/FATFS/Target
                ${STM32CUBE_PATH}/Middlewares/Third_Party/FatFs/src
                ${STM32CUBE_PATH}/FATFS/App
                )

        target_link_libraries(${STM32CUBE_FATFS_LIB}
                PUBLIC
                stm32cube_hal)
        add_library(stm32cube::fatfs ALIAS ${STM32CUBE_FATFS_LIB})

endif()

# for
add_library(stm32cube_app INTERFACE)
target_link_libraries(stm32cube_app
        INTERFACE
        stm32cube_hal
        ${STM32CUBE_FATFS_LIB})
aux_source_directory(${STM32CUBE_PATH}/Core/Src CORE_SOURCES)
target_sources(stm32cube_app
        INTERFACE
        ${CORE_SOURCES}
        ${SETUP_ASM}
        )
target_link_options(stm32cube_app
        INTERFACE
        -T${LINKER_SCRIPT}
        -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map,--cref
        -Wl,--gc-sections
        -Wl,--print-memory-usage
        )
add_library(stm32cube::app ALIAS stm32cube_app)






