# Pattern matching algorithms in Blockchain for network fees reduction

## About

Efficient exact pattern matching algorithms implementation in Solidity/YUL language.

### Algorithms

The smart contract contains implementation of below mentioned algorithms in Solidity language:
* Shift-Or (three variants, `so3` is the fastest)
* Knuth-Morris-Pratt (`kmp`)
* Boyer-Moore-Horspool (three variants, the `hor3` is the fastest)
* Rabin-Karp (`rk`)
* Backward Nondeterministic Dawg Matching (`bndm`)
* Naive/Brute Force (two variants, the `naive2` is the fastest)

All functions take four arguments: text, text length, pattern, and pattern length, and return the number of pattern occurrences in the text.

*Note: more information about each function can be found in the comments.*

### Disclaimer

This source code was written for research purposes. It has minimal error checking. The code may be not very readable, and comments may not be adequate. There is no warranty. Your use of this code is at your own risk.

We put all the effort into making the experiments reproducible. The gas usage should be the same on all machines if the versions of environment components are the same as stated in the Requirements section. The timings may slightly or significantly differ depending on the machine power.

Additionally, we deployed the smart contract on Rinkeby network at [0x9Fb22d8d82FcF1c5321D5acf75eE917CF936E257](https://rinkeby.etherscan.io/address/0x9Fb22d8d82FcF1c5321D5acf75eE917CF936E257).



## Requirements

* Python >= 3.8
* Miniconda/Anaconda (for managing environment, optional)
* brownie == 1.17.2
* node/npm (to install and run Ganache)
* Ganache == v6.12.2
* Solc compiler == v0.8.11 (optimizer must be enabled for 200 runs, see `brownie-config.yaml`)

The code was tested on Linux 64-bit OS (Fedora and Arch distributions) and should also work on other systems (such as Windows and Mac OS) if all requirements are met, but it was not verified.

## Data

### Corpus

The original corpus can be found at: http://pizzachili.dcc.uchile.cl/texts/.

The datasets used for testing are available in [`texts`](./texts/) folder.

### Patterns

Patterns were generated from texts and are located in [`patterns`](./patterns/) folder.

## Running

### Environment setup

```
conda create -n pat python=3.8
conda activate pat
pip install -r requirements.txt

npm install ganache-core@2.13.2
npm install ganache-cli@6.12.2
```

> Note: `conda` commands can be omitted but we recommend to install fresh environment.

### Run

Run Ganache node and then:

```
brownie run execute
```

> Note: The parameters may be changed in the [`execute.py`](./scripts/execute.py) file.

## Results

All collected results are located in [`results.csv`](./results.csv).

## Citation

The paper is available at https://link.springer.com/article/10.1007/s11227-024-06115-8

```
@article{susik2024pattern,
  title={Pattern matching algorithms in blockchain for network fees reduction},
  author={Susik, Robert and Nowotniak, Robert},
  journal={The Journal of Supercomputing},
  pages={1--19},
  year={2024},
  publisher={Springer}
}
```
