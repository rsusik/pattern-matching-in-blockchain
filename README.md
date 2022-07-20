# Pattern matching algorithms in Blockchain for network fees

## About
This source code was written for research purposes. It has minimal error checking. The code may be not very readable, and comments may not be adequate. There is no warranty. Your use of this code is at your own risk.

We put all the effort into making the experiments reproducible. The gas usage should be the same on all machines if the versions of environment components are the same as stated in the Requirements section. The timings may slightly or significantly differ depending on the machine power.

## Requirements

* Python >= 3.8
* brownie == 1.18
* Ganache == v7.3.2

_Note: The code was tested on Linux 64-bit OS._

## Data

### Corpus

The origial corpus is available at: http://pizzachili.dcc.uchile.cl/texts/.

The datasets used for testing are available in [`texts`](./texts/) folder.

### Patterns

Patterns were generated and are located in [`patterns`](./patterns/) folder.

## Running

* Environment setup

```
conda create -n pat python=3.8
conda activate pat
pip install -r requirements.txt
```

* Run

```
brownie run execute
```

> Note: The parameters may be changed in the [`execute.py`](./scripts/execute.py) file.

## Results

All collected results are located in [`results.csv`](./results.csv).
