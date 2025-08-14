# Replication Package for "Making the invisible hand visible: Managers and the allocation of workers to jobs (Minni, 2025)"

## 1. Overview

Files in this replication package clean all data sources used in the analysis (Stata and Python) and reproduce all results in the paper and the Supplementary Materials. Some analyses (mainly some event studies) involve computationally intensive tasks, which can be time-consuming. These codes are executed from the Chicago Booth high-performance computing cluster, Mercury. All results should be expected to be produced within 24 hours by running the single master do file: `v2_codes/v2_master.do`.

## 2. Data description and access

### 2.1. Overview of datasets

#### 2.1.1. Personnel records and other data from the MNE 

#### 2.1.2. Country-level datasets

### 2.2. Data access and restrictions
- Confidentiality:
- Data sharing principles:

### 2.3. Statement about rights
- [x] I certify that the author(s) of the manuscript have legitimate access to and permission to use the data used in this manuscript.

## 3. Computational requirements

### 3.1. Software requirements
- Stata 17.0. 
  - All necessary user-written packages are already included in the `stata_libraries` folder.
  - The file `v2_codes/util/00InstallPackages.do` contains all necessary codes to install packages from scratch. However, if these user-written packages get updated, some differences in the results may occur; thus, using the provided packages in the `stata_libraries` folder is recommended.
- Python 3.12. 
  - An `environment.yml` file is provided to create a virtual environment in the `python_env` folder.

### 3.2. Equipment requirements
- Some computationally intensive files (related to the event studies) are executed on the Chicago Booth computing cluster Mercury.
- Other less computationally intensive files are executed on a Windows laptop (Intel Core(TM) i9-14900HX, RAM 64 GB)

## 4. Instructions 

### 4.1. Setting up a virtual environment for Python
- Make sure a virtual environment is created using the `environment.yml` file in the `./python_env` folder. Specifically, the following commands will be useful.
```powershell
cd /path/to/project
conda env create --prefix ./python_env --file environment.yml
```
- To test whether it is set up properly, the following commands will be useful.
```powershell
cd /path/to/project
conda activate ./python_env 
conda list numpy
conda list pandas
conda list matplotlib
conda list scikit-learn
conda list wordcloud
pip show pyfixest
```

### 4.2. Updating the master do file with the right project directory path
- Edit the `user` global in the `v2_codes/v2_master.do` file to the base directory of the local computer used.
- Run the `v2_codes/v2_master.do` file to run all data cleaning and analysis codes.

## 5. The mapping from outputs to programs 
