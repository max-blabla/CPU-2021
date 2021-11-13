# CPU 模块设计

## **若模块A的输出在时序里修改与模块B在时序里的输入共线的话，那么B只能收集到A修改前的值。**

## RAM_MANAGER

```verilog
input wire[31:0] din
output wire[31:0] dout
input wire[31:0] ain
output wire[31:0] aout
//上述只与总线交互
output wire busy //prepare
input wire rq
input wire wr // 0为读 1为写
//上述只与总线控制器交互
reg [31:0] dmem
reg [31:0] ca//其实只要17位
reg wr
reg [2:0] //四周期计数器，即做完ram 操作后 为 10 时 下个周期即将完成 这时可以通知
```

## Instr_Queue

```verilog
module Instr_Queue
#
(
    parameter QueueStorage = 4'b1111,
    parameter PointerStorage = 2'b11//头指针和尾指针长度
)
(
    input wire rst,
    input wire clk,
    input wire is_stall_from_rs,
    input wire is_stall_from_rob,
    input wire is_exception_from_rob,
    input wire is_hit_from_fetcher,
    input wire[`InstrLength:`Zero] instr_from_fetcher,
    output wire is_empty_to_decoder,
    output wire[`InstrLength:`Zero] instr_to_decoder,
    output wire[`PcLength:`Zero] pc_to_decoder,
    
    input wire[`PcLength:`Zero] pc_from_rob,
    output wire[`PcLength:`Zero] pc_to_fetcher
//锁存与保持？
);
```

