# Design notes

This accelerator is intentionally minimal. It focuses on clarity rather than raw throughput.

- Arithmetic: inputs and weights are 16-bit signed fixed-point (Q1.15). Multiply results are 32-bit. The accumulation is performed at 32-bit precision and the final result is presented as 32-bit Q15.

- Interface: a simple valid/ready streaming protocol for inputs and weights keeps the core easy to hook up to other logic. A production design would add DMA/AXI interfaces and on-chip RAM for input/weight storage.

- Extensions:
  - Add an AXI-lite control block for configuration registers (start, base addresses).
  - Add a weight buffer and double-buffering to overlap weight transfer and compute.
  - Implement a systolic array for parallel MACs and higher throughput.