# SPI Flash Read ID Test

## Purpose

This demo program tests the SPI interface by reading the JEDEC ID from a SPI Flash memory chip. It demonstrates basic SPI communication using the NEORV32 processor.

## Hardware Connection

Connect a SPI Flash memory chip to the NEORV32 SPI interface as follows:

- **MOSI** (Master Out Slave In) - Connect to Flash chip's DI/SI pin
- **MISO** (Master In Slave Out) - Connect to Flash chip's DO/SO pin
- **CS** (Chip Select) - Connect to Flash chip's CS/CE pin
- **CLK** (Clock) - Connect to Flash chip's SCK pin
- **VCC** - Connect to appropriate power supply (typically 3.3V)
- **GND** - Connect to ground

## Compilation Steps

1. Make sure the NEORV32 toolchain is properly installed and configured
2. Navigate to the demo directory: `cd sw/example/demo_spi_flash/`
3. Run the makefile: `make all`
4. The compiled executable will be generated as `demo_spi_flash.bin`

## Running the Program

1. Load the compiled binary to the NEORV32 processor
2. Connect to the UART0 interface at 19200 baud rate
3. Reset the processor
4. The program will output the JEDEC ID of the connected SPI Flash chip

## Expected Output

The program will output a message like:
```
<<< SPI Flash Read ID Test >>>

ID: 0xEF 0x40 0x18
```

Where the three hex values represent:
- Manufacturer ID (e.g., 0xEF for Winbond)
- Memory Type (e.g., 0x40 for W25Q series)
- Capacity (e.g., 0x18 for 16MB)

## Program Flow

1. Initialize UART0 for debug output
2. Check if SPI module is available
3. Disable global interrupts
4. Configure SPI with 64 prescaler, mode 0
5. Enable SPI module
6. Pull CS low to select the Flash chip
7. Send Read ID command (0x9F)
8. Read 3 bytes of ID data
9. Pull CS high to deselect the Flash chip
10. Print the ID values via UART0
11. Enter infinite loop

## Notes

- This program uses SPI channel 0 (CS0)
- The SPI clock is configured for mode 0 (CPOL=0, CPHA=0)
- No dynamic memory allocation is used
- No interrupts are used after initialization