This folder contains a small helper to generate test vectors. The accelerator expects 16-bit signed fixed-point values (Q1.15). The Python tool converts floats in [-1,1] to Q15 and emits a golden output in 32-bit Q15 form.

Use these files with your own testbench additions or to feed a C/host driver when integrating with a simulation harness that reads files.