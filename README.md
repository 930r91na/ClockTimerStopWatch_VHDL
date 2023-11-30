# ClockTimerStopWatch_VHDL

# Clock Implementation in VHDL

## Overview
This project involves the design and implementation of a multi-mode digital clock using VHDL. The clock operates in several modes: standard clock, timer, chronometer, and alarm. The code is structured to handle inputs for various controls and display the time in different formats on a 7-segment display.

## Features
- **Multiple Modes**: Clock, Timer, Chronometer, and Alarm.
- **User Controls**: Includes controls for setting time, starting/pausing the chronometer, incrementing/decrementing time values, and switching between modes.
- **7-Segment Display Outputs**: Separate 7-segment display outputs for hours, minutes, and seconds.

## Entity Declaration
- **Inputs**:
  - `clk50mz`: Clock input.
  - `rst`: Reset control.
  - `rst_mode`: Mode reset control.
  - `control`: Mode control input.
  - `init_ps`: Start/pause control.
  - `incrementar`: Increment time control.
  - `decrementar`: Decrement time control.
  - `cambiar_hora`: Change time control.
- **Outputs**:
  - `seg_hr1`, `seg_hr2`: 7-segment displays for hours.
  - `seg_min1`, `seg_min2`: 7-segment displays for minutes.
  - `seg_sec1`, `seg_sec2`: 7-segment displays for seconds.

## Architecture
The architecture `arch_clock` of the entity `clock` defines constants, signals, and processes required for clock operation.

### Constants and Signals
- Constants for time measurement and signals for maintaining time counters.
- `ONE_SECOND_COUNT`: Constant for the one-second count.
- `ONE_HOUR_COUNT`, `ONE_MINUTE_COUNT`, `TW_HOUR_COUNT`: Constants for time units.
- Various signal declarations for hour, minute, second, and state management.

### Processes
- **State Management**: Handles the current state of the clock and transitions based on user input.
- **Clock Logic**: Implements the logic for different clock modes, including standard clock, timer, and chronometer.
- **Display Logic**: Converts numerical time values into 7-segment display outputs.

### State Management
- Uses a finite state machine (FSM) approach for transitioning between different clock modes.

### Clock Logic
- Implements the functional logic for each mode, including time increment/decrement, reset, and mode-specific behaviors.

### Display Logic
- Converts time values into appropriate 7-segment display codes using the `digit_to_7seg` function.

## Function `digit_to_7seg`
- Maps integer digits to corresponding 7-segment display codes.

## How to Use
- To operate the clock, provide the necessary input signals such as `clk50mz` for the clock pulse, and use the control inputs to interact with different functionalities of the clock.
- The outputs will be shown on the connected 7-segment displays as per the current mode and operations performed.

## Notes
- Ensure that the FPGA or simulation environment is properly set up to handle the clock's frequency and input/output constraints.
- The implementation is designed for educational and demonstration purposes and can be extended or modified for more complex applications.
