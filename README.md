# 8086 Microwave Oven Simulator

A low-level control system simulation developed in 8086 Assembly language, focusing on hardware-software interfacing and modular logic.

## 🚀 Features
- **Preset Cooking Modes:** Specific configurations for Defrost (30°C), Heating (70°C), and Light Cooking (120°C).
- **Manual Time Control:** Real-time increment/decrement of cooking timers using `+` and `-` keys.
- **Interrupt-Driven I/O:** Uses BIOS (INT 16h) for keyboard input and DOS (INT 21h) for console output.
- **Audio Feedback:** Integrated PC-Speaker "BEEP" notification upon cycle completion.

## 🛠️ Technical Challenges & Solutions
- **Memory & Jump Limits:** Encountered the "Relative Jump out of range" (±128 bytes) limitation of the 8086 architecture. 
- **The Solution:** Implemented **Conditional Jump Inversion** combined with unconditional `JMP` instructions to allow long-range branching within the code segment.
- **Timing Precision:** Created custom software delay loops calibrated to simulate a 1-second real-time countdown.

