# MVP Chip - Dual-Core RISC-V SoC

A minimal viable product (MVP) system-on-chip (SoC) design featuring dual RV32I cores with basic peripherals, implemented in Verilog-2001.

## 📋 Architecture Overview

### Key Specifications

- **CPU**: 2× RV32I cores with 2-stage pipeline (Fetch/Execute)
- **Clock**: 100 MHz
- **Voltage**: 1.0 V
- **RAM**: 1 MB internal SRAM (dual-port, single-cycle access)
- **GPIO**: 10 general-purpose I/O pins
- **UART**: 1× UART interface (115200 baud, 8N1)
- **Flash**: 10 MB external SPI Flash (Mode 0, XIP boot)
- **PMU**: Power Management Unit with sleep mode and UART wake-up
- **Bus**: 32-bit address bus, 32-bit data bus, memory-mapped I/O

### Features

- ✅ No interrupts (simple polling architecture)
- ✅ No CSR (Control and Status Registers)
- ✅ Integer operations only (RV32I base instruction set)
- ✅ Boot from external Flash via Execute-in-Place (XIP)
- ✅ Dual-port SRAM for concurrent CPU access
- ✅ Shared peripheral access with simple arbiter

## 🏗️ Module Descriptions

### Top-Level Module: `mvp_chip.v`

Main chip integration module that instantiates and interconnects all components.

**Ports:**
- `clk` - 100 MHz system clock input
- `rst` - Active-high reset input
- `gpio_pins[9:0]` - Bidirectional GPIO pins
- `uart_rx` - UART receive input
- `uart_tx` - UART transmit output
- `flash_cs` - SPI Flash chip select (active low)
- `flash_sclk` - SPI Flash clock
- `flash_mosi` - SPI Flash Master Out Slave In
- `flash_miso` - SPI Flash Master In Slave Out

### CPU Core: `rv32i_core.v`

RV32I CPU core with 2-stage pipeline (black box implementation).

**Pipeline Stages:**
1. **Fetch**: Instruction fetch from memory or Flash
2. **Execute**: Instruction decode and execution

**Features:**
- 32-bit address space
- Byte-addressable memory
- Byte enable signals for partial word access
- Clock gating support for power management

### SRAM: `sram_1mb.v`

1 MB dual-port synchronous SRAM.

**Configuration:**
- Size: 1,048,576 bytes (262,144 words)
- Word size: 32 bits
- Access: Single-cycle synchronous read/write
- Ports: 2 independent ports (one per CPU)

### GPIO Controller: `gpio_controller.v`

10-pin general-purpose I/O controller with dual-port access.

**Features:**
- Programmable direction per pin (input/output)
- Direct read of input values
- Direct write to output values
- No pull-up/pull-down resistors
- No interrupt capability

### UART Controller: `uart_controller.v`

Serial communication interface with wake-up capability.

**Configuration:**
- Baud rate: 115200 (configurable via `BAUD_DIV` parameter)
- Format: 8 data bits, no parity, 1 stop bit (8N1)
- TX/RX with status flags
- Generates wake-up signal on RX start bit

### PMU Controller: `pmu_controller.v`

Power Management Unit for sleep mode control.

**Features:**
- Software-controlled sleep mode entry
- UART wake-up from sleep
- CPU clock enable control
- Status reporting

### SPI Flash Interface: `spi_flash_interface.v`

SPI controller for external Flash memory access.

**Configuration:**
- SPI Mode 0 (CPOL=0, CPHA=0)
- Up to 100 MHz clock
- Read command support (0x03)
- 24-bit addressing (10 MB accessible)

## 🗺️ Memory Map

| Address Range | Size | Description | Access |
|--------------|------|-------------|--------|
| `0x00000000 - 0x000FFFFF` | 1 MB | Internal SRAM | RW |
| `0x40000000 - 0x40000FFF` | 4 KB | GPIO Registers | RW |
| `0x40001000 - 0x40001FFF` | 4 KB | UART Registers | RW |
| `0x40002000 - 0x40002FFF` | 4 KB | PMU Registers | RW |

### GPIO Register Map (Base: 0x40000000)

| Offset | Register | Description |
|--------|----------|-------------|
| `0x0` | DATA | GPIO data (read: input, write: output) |
| `0x4` | DIR | Direction (0=input, 1=output) |

### UART Register Map (Base: 0x40001000)

| Offset | Register | Description |
|--------|----------|-------------|
| `0x0` | DATA | TX/RX data register |
| `0x4` | STATUS | [31:2]=Reserved, [1]=RX ready, [0]=TX busy |
| `0x8` | CONTROL | [31:1]=Reserved, [0]=UART enable |

### PMU Register Map (Base: 0x40002000)

| Offset | Register | Description |
|--------|----------|-------------|
| `0x0` | CONTROL | [31:1]=Reserved, [0]=Sleep request |
| `0x4` | STATUS | [31:1]=Reserved, [0]=Sleep mode active |

## 🔨 Build Instructions

### Prerequisites

- **ModelSim** (or QuestaSim)
- **Verilog-2001** compatible simulator

### Compilation

```bash
# Create work library
vlib work

# Compile all source files
vcom -work work -2001 rv32i_core.v
vcom -work work -2001 sram_1mb.v
vcom -work work -2001 gpio_controller.v
vcom -work work -2001 uart_controller.v
vcom -work work -2001 pmu_controller.v
vcom -work work -2001 spi_flash_interface.v
vcom -work work -2001 mvp_chip.v

# Compile testbench
vcom -work work -2001 tb_mvp_chip.v
```

### Simulation

```bash
# Load the testbench
vsim -t 1ps work.tb_mvp_chip

# Add signals to waveform
add wave -radix hex sim:/tb_mvp_chip/*

# Run simulation
run -all
```

Or use the GUI:

```bash
# Start ModelSim GUI
vsim -gui

# In the GUI:
# 1. File -> New -> Project
# 2. Add all .v files
# 3. Compile all
# 4. Simulate -> Start Simulation -> select tb_mvp_chip
# 5. Add waves and run
```

## 🧪 Testbench

The provided testbench (`tb_mvp_chip.v`) performs the following tests:

1. **Reset sequence** - Applies and releases reset
2. **UART RX test** - Sends byte 0x55 via UART receive line
3. **GPIO toggle test** - Drives GPIO pins with various patterns
4. **Clock cycles** - Runs for multiple clock cycles to observe operation

### Expected Behavior

- System boots from reset
- UART receives the test byte
- GPIO pins respond to external stimulus
- UART wake signal triggers on RX activity
- All modules respond to bus transactions

## 📂 Project Structure

```
chip/
├── README.md                    # This file
├── mvp_chip.v                   # Top-level SoC module
├── rv32i_core.v                 # RV32I CPU core (black box)
├── sram_1mb.v                   # 1 MB dual-port SRAM
├── gpio_controller.v            # GPIO peripheral
├── uart_controller.v            # UART peripheral
├── pmu_controller.v             # Power Management Unit
├── spi_flash_interface.v        # SPI Flash controller
└── tb_mvp_chip.v                # Testbench
```

## ⚙️ Configuration Parameters

### UART Baud Rate

Default: 115200 baud (100 MHz / 868 = 115207 baud)

To change, modify `BAUD_DIV` parameter in `uart_controller.v`:

```verilog
localparam BAUD_DIV = 868;  // 100 MHz / 115200
```

For different baud rates:
- 9600: `BAUD_DIV = 10417`
- 19200: `BAUD_DIV = 5208`
- 38400: `BAUD_DIV = 2604`
- 57600: `BAUD_DIV = 1736`

### SPI Clock Speed

The SPI controller generates clock cycles on every system clock edge during transactions. For a 100 MHz system clock, the effective SPI clock is 50 MHz.

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/prokopsafranek/chip.git
cd chip
```

### 2. Compile the Design

```bash
# Using ModelSim
vlib work
vlog -work work *.v
```

### 3. Run Simulation

```bash
vsim -c -do "run -all" work.tb_mvp_chip
```

### 4. View Waveforms

```bash
vsim -gui work.tb_mvp_chip
# Add waves and run interactively
```

## 🔧 Development Notes

### CPU Core Implementation

The `rv32i_core.v` module is currently a black box placeholder. A full implementation would include:

- Complete RV32I instruction decoder
- Register file (32×32-bit registers)
- ALU with all integer operations
- Branch/jump logic
- Load/store unit
- Pipeline control and hazard handling

### Future Enhancements

Possible improvements for future versions:

- [ ] Complete RV32I core implementation
- [ ] Interrupt controller (PLIC)
- [ ] Timer peripheral
- [ ] DMA controller
- [ ] Cache hierarchy
- [ ] Debug interface (JTAG)
- [ ] Additional SPI/I2C peripherals
- [ ] Extended memory (DDR controller)

## 📝 Design Constraints

- **No interrupts**: All I/O is polling-based
- **No CSR**: No Control and Status Registers
- **Integer only**: No floating-point operations
- **Simple arbiter**: Round-robin CPU access (may cause stalls)
- **No cache**: Direct memory access only
- **No protection**: No memory protection or privilege levels

## 🐛 Troubleshooting

### Simulation Issues

**Problem**: Memory initialization warnings

**Solution**: This is normal. The SRAM initializes to zeros at startup.

---

**Problem**: UART timing mismatches

**Solution**: Verify `BAUD_DIV` calculation matches your system clock frequency.

---

**Problem**: SPI Flash not responding

**Solution**: Ensure `flash_miso` is driven in testbench or by Flash model.

### Synthesis Issues

**Problem**: Large memory arrays

**Solution**: SRAM blocks should be mapped to FPGA block RAM. Configure synthesis tool accordingly.

---

**Problem**: Timing violations

**Solution**: Add pipeline stages or reduce clock frequency. The design targets 100 MHz.

## 📄 License

This project is provided as-is for educational and research purposes.

## 👤 Author

**Prokop Šafránek**
- GitHub: [@prokopsafranek](https://github.com/prokopsafranek)

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📚 References

- [RISC-V Specification](https://riscv.org/technical/specifications/)
- [RV32I Base Integer Instruction Set](https://github.com/riscv/riscv-isa-manual)
- [Verilog-2001 Quick Reference](https://sutherland-hdl.com/pdfs/verilog_2001_ref_guide.pdf)

---

**Note**: This is a minimal educational design. It is not intended for production use without significant enhancements.
