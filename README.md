# FPGA-Based FFT Engine for Edge Detection

## Overview
This project implements a real-time, hardware-accelerated 2-D Fast Fourier Transform (FFT) pipeline for image edge detection on the Xilinx Zynq-7000 SoC. 

Conventional spatial-domain edge detectors (like Sobel or Canny) suffer from noise amplification and limited angular resolution[cite: 11]. This project bypasses those limitations by transforming the image into the frequency domain, isolating high-frequency boundary content using a dynamically configurable circular high-pass filter (HPF), and reconstructing the spatial edge map via an Inverse FFT (IFFT).

## Key Architectural Features

### 1. Single-Path Delay-Feedback (SDF) FFT Core
To overcome the massive computational burden of real-time 2-D spectral transforms, the core uses a memory-efficient 1024-point radix-2 Decimation-In-Frequency (DIF) SDF architecture. 
*   **Memory Efficiency: Reduces memory requirements to the theoretical minimum of $N-1$ words (utilizing only 5 Block RAM tiles total).
*   **Throughput: Achieves a deterministic throughput of one sample per clock cycle after the initial pipeline fill.

### 2. Q1.15 Convergent-Rounding Arithmetic
The datapath utilizes custom Q1.15 fixed-point arithmetic instead of floating-point to save logic resources[cite: 11]. To prevent the accumulation of DC bias over the 10 pipeline stages, the Butterfly units implement strict convergent rounding (round-half-to-even) alongside arithmetic saturation, achieving a Mean Absolute Pixel Error (MAPE) of just 2.85% compared to a double-precision floating-point reference mode.

### 3. Dynamic In-Line High-Pass Filter (HPF)
A fully sequential AXI4-Stream pass-through filter dynamically calculates the wrapped spectral distance from the DC corner. Frequency bins falling within the configurable cut-off radius are zeroed out, isolating isotropic structural edges without requiring multiple DMA round-trips.

## Hardware-Software Co-Design
The system utilizes a hybrid processing approach via the AXI4-Stream interface:
*   **Programmable Logic (Hardware): Executes the heavy $O(N \log_{2}N)$ operations, including the Row/Column FFTs, High-Pass Filtering, and IFFT conjugations.
*   **Processing System (Software): An ARM Cortex-A9 runs a bare-metal C application to orchestrate DMA transfers, normalize images from an SD card, perform the critical in-place matrix transpositions between passes, and execute final pixel rescaling.

## Performance & Implementation Results
Synthesised on the ZedBoard (XC7Z020) at a 70 MHz clock frequency:
*   **Timing: Zero failing endpoints (WNS: 5.089 ns). (so can push till 109 MHz)
*   **Resource Utilization:
    *   Slice LUTs: 21.0% (11,171)
    *   DSP48E1: 19.1% (42)
    *   Block RAM: 3.6% (5)

## Current Status & Future Implementations (Work in Progress)
This repository is under active development.

Implemented & Verified:
*   1024-point radix-2 DIF SDF FFT core
*   Q1.15 fixed-point arithmetic with convergent rounding
*   Dynamic circular High-Pass Filter (HPF)
*   Software-side matrix transposition and IFFT scaling

Coming Soon:
*   **Ping-Pong Bit-Reversal Buffer:** Integration of a dual-bank memory architecture to correct the scrambled DIF output into natural order in hardware with zero latency overhead.
