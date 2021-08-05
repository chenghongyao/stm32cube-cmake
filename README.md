这是一个基于STM32CubeMx，CMake及gcc编译工具链的自动构建脚本，用于快速构建STM32工程，自动接入STM32CubeMX生成的文件，同时也可以更方便地使用第三方的IDE，如[VSCode]()，[Clion]()等。更重要的是，本项目希望可以实现工程的模块化设计，可以更加方便地使用其他基于STM32 HAL库的设备驱动库或其它与硬件无关的库。

# Quick Start

本节将说明如何使用本项目搭建一个最简单的工程

## 环境搭建

环境主要需要三个工具：STM32CubeMX，arm-none-eabi-gcc，和CMake。其中的CMake也可以直接使用IDE自带的CMake，无需下载。

- `STM32CubeMX`：从[官网](https://www.st.com/zh/development-tools/stm32cubemx.html)下载后安装即可；

- `arm-none-eabi-gcc`：从[官网](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads)下载后解压到任意位置，并将解压后目录下的bin文件夹路径加入到环境变量，在终端输入`arm-none-eabi-gcc --version`检查是否成功；

- `CMake`：如果使用IDE（推荐）也可以不安装，使用自带的插件或功能即可：

  - `Windows`：从[官网](https://cmake.org/download/)下载后安装即可。

  - `Linux`：

    ```
    sudo apt install cmake
    ```

## 新建工程

1. 新建一个文件夹存放工程，命名为`hello_cube`；

2. 打开STM32CubeMX，新建一个工程，选择一个需要的芯片并设置相关硬件配置，最后打开`Project Manager`选项页：

   - 将`Project Name`设置为`stm32cube`（如果需要设置为别的名字，需要稍后修改CMakeLists.txt中地`STM32CUBE_PATH`变量）；
   - 将`Project Location`设置为之前新建的工程文件夹路径，即`/path/to/hello_cube`；
   - 将`Toolchain/IDE`设置为`Makefile`。

   最后点击`GENERATE CODE`生成文件

3. 克隆本项目到工程文件夹：

   ```bash
   cd /path/to/hello_cube
   git clone https://github.com/chenghongyao/stm32cube-cmake 
   ```

4. 新建`app.c`文件，写入示例代码：

```c
// app.c
#include "main.h"

void setup() {
    
}

void loop() {
    HAL_DELAY(1);
}
```

然后将这两个函数写入到STM32CubeMX生成的`main.c`文件中，路径为`stm32cube/Core/Src/main.c`，在`main`函数下的`USER CODE BEGIN 2`下添加：

```c
extern void setup();
extern void loop();
setup();
while(1) {loop();}
```

这是仿arduino的实现，也就是系统启动后先运行一次`setup()`函数，然后循环调用`loop()`函数。

5. 最后，新建CMakeLists.txt文件，开始编写工程构建程序。

```cmake
cmake_minimum_required(VERSION 3.10)
project(app C CXX ASM)

set(MCU_TYPE STM32F411xE)					# 芯片类型
include(stm32cube-cmake/stm32cube.cmake)	# 导入本项目提供的cmake文件

set(EXECUTABLE_NAME ${PROJECT_NAME}.elf)
add_executable(${EXECUTABLE_NAME} app.c)
target_link_libraries(${EXECUTABLE_NAME} 
                        PRIVATE 
                        stm32cube::app # executable目标必须添加这个目标
        			)
```

##  构建工程

### 命令行

在工程目录下新建build文件夹，最后打开终端输入

```bash
cd /path/to/hello_cube
cmake --build build -DCMAKE_TOOLCHAIN_FILE=stm32cube-cmake/arm-none-eabi-gcc.cmake
make
```

项目编译完成后，会`build`目录下生成`app.elf`文件。

### Clion

1. 使用Clion打开工程文件夹
2. 选择菜单`File->Settings`，进入`Build,Execution,Deployment->Cmake`选项页，在`CMake options`中添加`-DCMAKE_TOOLCHAIN_FILE=stm32cube-cmake/arm-none-eabi-gcc.cmake`，
3. 最后编译程序



### VSCode [TODO]

1. 先安装好插件`C/C++`，`CMake`，`CMake Tools`。

2. 使用VSCode打开工程文件夹
3. 

# 关于`stm32cube.cmake`

在工程的根CMakeLists.txt下需要先定义芯片类型变量`MCU_TYPE`（该变量可以在STM32CubeMX生成的Makefile文件中找到），然后导入`stm32cube.cmake`，

```
include(stm32cube-cmake/stm32cube.cmake)
```

这个文件主要是自动完成STM32CubeMX生成文件的导入，及全局编译参数的设置，这些参数有些是与硬件相关的。

这个文件执行后会生成3个主要目标：`stm32cube::cmsis`，`stm32cube::hal`，`stm32cube::app`

- `stm32cube::cmsis`，这个文件都是头文件，当需要访问stm32硬件相关的功能（如寄存器定义等）时需要链接此目标。
- `stm32cube::hal`：此目标包含了所有的HAL库文件，是一个静态库目标。HAL库硬件抽象的，当需要调用使用HAL库提供的API时需要链接此目标，同时在相关源文件中使用`#include "main.h"`包含库头文件
- `stm32cube::app`：此目标包含`main.c`,`*.s`启动文件，链接脚本等，可执行文件需要链接此目标

同时还有其他扩展目标，这些目标使用前可能需要在STM32CubeMx中使能相关功能

- `stm32cube::fatfs`
- `stm32cube::dsp`

# `stm32cube::sys`与`stm32cube::utils`





# 修改一些编译参数

[TODO]



# 下载

TODO



# 第三方库

本项目的主要是为了实现统一的第三方库接入，这是通过设置硬件相关的全局编译参数，导出`stm32cube::hal`目标实现的。

为了方便，第三方库实现使用一下命名方式

- `*-cmake`：与硬件无关，但是使用了全局编译参数
- `*-hc`：基于Hal库，该库链接了`stm32cube::hal`

对于依赖于Hal库的文件，很多功能可能需要在STM32CubeMX中设置，因此在第三方库的README文件中应当说明需要设置的GPIO，USART，SPI以及需要定义的常量等。

[待续]

# 现有库(TODO)

- [u8g2-cmake]()
- [u8g2_port_hal-hc]()
- [lvgl_port_lcd]()
