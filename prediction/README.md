#  predict_with_saved_model — Usage Guide

## 📋 Overview

`predict_with_saved_model.m` is a supplementary prediction script for VDMM-BESP. It can be used to:

1. Load a trained model (.mat) that has been exported from the **Prediction Model Construction** module.
2. Perform prediction on a single sample.
3. Print prediction results in the command window.

Supported Model Types:

| Model Type | Description                      |
| ---------- | -------------------------------- |
| BP         | Backpropagation Neural Network   |
| RF         | Random Forest                    |
| GBDT       | Gradient Boosting Decision Tree  |
| SER        | Simultaneous Equation Regression |

---

## 💻 Requirements

1. A trained model must be exported from the **Prediction Model Construction** module.
2. MATLAB
3. The model file and samples to be predicted are prepared. Refer to the example models located in [../models](../models).

---

## 🚀 Getting Started

### 1. Configure the model file path

Modify the `modelFile` parameter in the script:

```matlab
modelFile = '../models/TrainedModel_BP.mat';
```

### 2. Fill in the samples to be predicted

Assign values to `Xnew` following the column order of `XNames` used during model training:

```matlab
Xnew = [5.26, -7.12, 22.4];
```

**Notes**:

- `Xnew` must be a **1×p row vector** (where p denotes the number of input features).
- The column order must match `XNames` defined at training stage; otherwise, outputs will be invalid.

### 3. Run the script

Open and execute this script in MATLAB (or press **F5**). The script will automatically perform the following operations:

- Load the model and read the structure `PredTrainedModel`
- Print model `Type`, input variables `XNames`, and output variables `YNames`
- Output the prediction result `Prediction`

---

## 📤 Output

The command window outputs the following contents sequentially:

| Field      | Description                   |
| ---------- | ----------------------------- |
| Type       | Model type                    |
| XNames     | List of input variable names  |
| YNames     | List of output variable names |
| Prediction | Table of prediction results   |

Example:

```text
Type: BP
XNames: FC1, FC2, FC3, FC4
YNames: Pitr, Pith
Prediction:
    Pitr      Pith
    ______    ______
    2.1563    4.8731
```
