# VDMMBESP

**VDMMBESP** (Version 1.0) is a batch simulation application built on **MATLAB App Designer** that integrated with the **COMSOL Multiphysics** finite element engine. It is designed to simulate and analyze the potential distribution of metal pipelines containing pitting defects under electrical excitation.

## 📋 Overview

VDMMBESP integrates physical modeling, batch sample generation, statistical analysis, and parameter inversion model construction into a unified workflow, providing:

- **Single Model Calculation:** Perform simulation with a fixed set of parameters and view the voltage matrix, *FC* distribution, electric potential distribution, and current density field.
- **Batch Model Calculation:** Automatically sweep multiple parameter sets, generate simulation samples in batches, and export the corresponding data.
- **Data Analysis:** Load data from multiple sources, filter data by parameters, visualize single-model *FC* results, and perform correlation analysis and regression fitting.
- **Prediction Model Construction:** Build prediction models (BP, RF, GBDT, and SER) to predict pitting parameters from *FC* values, and output model evaluation metrics.

---



## 📂 Project Structure

```text
VDMMBESP/
├── 📱 VDMMBESP.mlapp              # Main application (App Designer source)
├── 📜 LICENSE                     # MIT License
├── 📖 README.md                   # This document
├── 📂 data/                       # Example and test data
│   ├── 📊 analysis_data.xlsx      # Sample data for the Data Analysis
│   └── 📊 train_data.xlsx         # Sample data for the Prediction Model Construction
├── 📂 db/                         # Database scripts
│   └── 🗄️ simulation_records.sql  # MySQL table creation script
├── 📂 docs/                       # User documentation
│   └── 📘 VDMM-BESP Users Guide.pdf   # User guide (PDF)
├── 📂 models/                     # Pre-trained example models (.mat)
│   ├── 🤖 TrainedModel_BP.mat
│   ├── 🤖 TrainedModel_RF.mat
│   ├── 🤖 TrainedModel_GBDT.mat
│   └── 🤖 TrainedModel_SER.mat
├── 📂 prediction/                 # Helper script for saved models
│   ├── 🧮 predict_with_saved_model.m
│   └── 📖 README.md               # Usage instructions for the helper script
└── 📂 release/                    # Packaged installer
│   └── 📦 VDMMBESP.mlappinstall   # MATLAB App installer
└── 📂 verification/               
    └── 🧮 calcSquarePitFC         # Verification and comparison script
    └── 📖 README.md               # Usage instructions for the helper script
```



## 💻 Requirements

The following hardware and software environment is required to run VDMMBESP:


| Item                | Requirement                                      | Notes                                                                    |
| ------------------- | ------------------------------------------------ | ------------------------------------------------------------------------ |
| Operating System    | Windows 10 / 11 (64-bit)                         | Windows 11 recommended                                                   |
| MATLAB              | R2022a or later                                  | App Designer component required                                          |
| COMSOL Multiphysics | COMSOL Multiphysics 6.2 with LiveLink for MATLAB | Required for finite element simulation                                   |
| Database (optional) | MySQL 8.0+ and ODBC driver                       | For long-term storage and multi-user shared access to simulation results |


>  Note: The database is optional. If you only need to export results to Excel or MAT files, you can skip the database configuration.

---



## 🚀 Installation and Startup



### 1. Start MATLAB via COMSOL

1. Double-click the **"COMSOL Multiphysics 6.2 with MATLAB"** icon on your desktop to open the command-line terminal (credentials are required on first launch only).
2. COMSOL automatically starts and loads the MATLAB environment. Wait until the MATLAB desktop (Command Window, Workspace, and toolstrip) is fully loaded.
3. Verify that the COMSOL LiveLink initialization success message appears in the MATLAB Command Window.



### 2. Launch the Application

- **Option A: Run from source (recommended)**
  1. Open MATLAB App Designer.
  2. Import and open [VDMMBESP.mlapp](VDMMBESP.mlapp).
  3. Click the **Run** button to start the application.
- **Option B: Install as a packaged app**
  1. In MATLAB, click **Install App** and import [release/VDMMBESP.mlappinstall](release/VDMMBESP.mlappinstall).
  2. After installation, locate the VDMMBESP icon in the **APPS** gallery and click it to launch.



### 3. Database Configuration (Optional)

Follow the steps below to write batch simulation results to a MySQL database for long-term storage:

1. **Create the database and tables:** Open a Windows terminal, connect to MySQL, and run the following commands:
  ```bash
   mysql -u root -p
  ```
   After entering your password and logging in, , run the `SOURCE` command:
  ```bash
   CREATE DATABASE IF NOT EXISTS pipepitssim CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   use pipepitssim;
   source oc/db/simulation_records.sql;
  ```
  > Note: The path in the `SOURCE` command must point to [db/simulation_records.sql](db/simulation_records.sql) inside this package. If the current working directory is not the package root, replace it with the actual path to the file.
2. **Configure the ODBC data source:** Open a Windows terminal and run `C:\Windows\SysWOW64\odbcad32.exe` to launch the ODBC Data Source Administrator, then add a new data source following the on-screen prompts.

---



## 📖 Quick Start Guide

> **For a detailed step-by-step tutorial with screenshots, refer to the** [VDMM-BESP Users Guide](<docs/VDMM-BESP Users Guide.pdf>). This section only outlines the main steps.

The application's GUI consists of **four tabs**, corresponding to the stages of the simulation and analysis workflow:

### 🔬 1. Single Model Calculation

- Enter the pipeline, pitting, matrix, and physical field parameters in the interface.
- Select the electrode layout in the Layout drop-down (**Equal** for evenly spaced electrodes, **Customize** for custom coordinates).
- Click **Calculate** to run the electric field simulation for the current parameters, and view the voltage matrix, *FC* values and distribution, and the model's potential and current density plots.



### 🔁 2. Batch Model Calculation

- Select export options in the Export Options panel and set the save path and filename.
- Choose a calculation mode (**Full Scan** or **Combination**).
- Enter multiple parameter values in the supported formats (space-separated, comma-separated, colon expressions, or mixed).
- Click **Calculate** to start the batch run. Progress, elapsed time, and logs are displayed in real time. When the run is complete, view the summary and detailed data in the Results panel.



### 📊 3. Data Analysis

- Select the data source type in the data selection panel, click **Load** to load data, and filter it by conditions;
- Choose an analysis method: single-variable data view, correlation analysis, univariate regression fitting, or multiple regression fitting (X1, X2 → Y). The outputs include the fitted equation and evaluation metrics such as R², RMSE, and MAE;
- *A test dataset, [data/analysis_data.xlsx](data/analysis_data.xlsx), is provided and can be loaded directly to verify and practice this module's features.*



### 🤖 4. Prediction Model Construction

- Click **Load** to import data, and then use the dual selection trees to specify the input variables (Input Data / X) and output variables (Output Data / Y).
- Select an algorithm in the Models drop-down and adjust the corresponding hyperparameters in Settings.
- Click **Train** to build the model. When training is complete, view the prediction results, evaluation metrics (R², RMSE, MAE), and fitting plots in the Results panel.
- After training, use **Save Trained Model** to save the model as a `.mat` file, or **Save Results** to export the predictions and metrics to Excel.
- A test dataset, [data/train_data.xlsx](data/train_data.xlsx), is provided and can be loaded directly to verify and practice this module's features.

---



### 🧮 5. Using a Saved Model (Optional)

A saved model (the `.mat` file exported via **Save Trained Model**) can be loaded directly with the [prediction/predict_with_saved_model.m](prediction/predict_with_saved_model.m) script to predict a single sample and print the result.

**For detailed usage, input format, output description, and notes, see** [prediction/README.md](prediction/README.md)**.**

---



## 📜 License

This software is released under the [MIT License](LICENSE). For full terms, see [LICENSE](LICENSE).
