# calcSquarePitsFC

## Overview

This program calculates the FC value for pipelines with square-shaped pitting corrosion defects. The script separately constructs an uncorroded model and a model with a square-shaped pitting defect. Electric potentials are extracted at equally spaced electrodes, and voltages are then computed. The FC is subsequently derived from the two models. The computational results are output exclusively to the MATLAB Command Window.

## Requirements

Consistent with the VDMMBESP.

## Getting Started

1. open `calcSquarePitFC.m` in MATLAB.
2. Modify the required input parameters at the beginning of the script.
3. Run the script.
4. View the output FC values in the Command Window.

The pitting depth (`pith`) allows multiple values to be input at once. The uncorroded model is solved only once, after which the pitted models and their corresponding FC values are calculated sequentially for each depth.

## Input Parameters

Simply modify the variables at the beginning of the script; all other parameters should remain as single values.

### 1. Pipe Parameters


| Parameter  | Default Value | Unit | Description         |
| ---------- | ------------- | ---- | ------------------- |
| pipeLength | 1500          | mm   | Pipe length         |
| piper      | 150           | mm   | Pipe outer radius   |
| pipes      | 10            | mm   | Pipe wall thickness |
| current    | 3             | A    | Excitation current  |




### 2. Pitting Parameters


| Parameter | Default Value | Unit | Description                                                                         |
| --------- | ------------- | ---- | ----------------------------------------------------------------------------------- |
| pitLength | 10            | mm   | Side length of the square pit                                                       |
| pith      | `[1,2,3,4,5]` | mm   | Pit depth. Can be a single value (e.g., 5) or multiple values (e.g., `[1,2,3,4,5]`) |




### 3. Electrode Parameters

Electrodes are arranged at equal intervals along the middle of the pipe's outer surface. 


| Parameter | Default Value | Unit | Description                              |
| --------- | ------------- | ---- | ---------------------------------------- |
| rows      | 3             | —    | Number of electrode rows, must be ≥ 1    |
| cols      | 4             | —    | Number of electrode columns, must be ≥ 2 |
| spacing   | 30            | mm   | Spacing between adjacent electrodes      |




## Output

- The Command Window outputs only the FC.
- For a single depth, the FC matrix for that depth is printed directly.
- For multiple depths, the corresponding `pith` value is printed first, followed by the FC matrix for that depth.

