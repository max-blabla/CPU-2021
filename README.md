# RISCV-CPU

## 文件结构主要介绍：

### 实现Tomasulo算法

### 组成模块如下：

```
Fetcher
InstrQueue
Decoder
RegFile
ReOrderBuffer
StoreLoadBuffer
ReverseStation
ArithmeticLogicUnit
```

#### Fetcher

循环队列，负责与内存交互，接受来自$InstrQueue$与$StoreLoadBuffer$的请求。

#### InstrQueue

循环队列，负责获取指令与发射指令，若指令处理模块阻滞，不会更新发射指令。

#### Decoder

负责解码指令。

#### RegFile

负责寄存器重命名的存储以及寄存器数值的存储，同时兼顾将指令分发给$ReOrderBuffer$、$StoreLoadBuffer$与$ReverseStation$的任务。

#### ReOrderBuffer

循环队列，负责将乱序执行的内容顺序输出与精确中断。

#### StoerLoadBuffer

循环队列，负责$Store$与$Load$相关指令，并与$Fetcher$交互。

#### ReverseStation

负责算数指令，并与$ArithmeticLogicUnit$交互。

#### ArithmeticLogicUnit

进行算数运算的单元。