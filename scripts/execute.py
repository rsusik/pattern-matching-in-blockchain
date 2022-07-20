import time, glob
from brownie import TextMatching, accounts


# Config
CORPUSES='dna.50MB english.50MB proteins.50MB sources.50MB'.split()
N_SET = [1024, 16*1024, 128*1024]
M_SET = [4, 8, 12, 16, 24, 32, 64, 128, 256, 512]
ALGORITHMS = '''strutil naive2 rk kmp naive2 so3 hor2 bndm '''.split()
REPEATS = 1

def transact(contract, alg_name: str, t, p) -> (int, int, float):
    print(alg_name)
    alg = getattr(contract, alg_name)
    t0 = time.time()
    tx = alg.transact(t, len(t), p, len(p))
    t1 = time.time()

    gas_used = tx.gas_used
    matches = tx.events["Log"]["_v"]
    time_ = t1 - t0

    print(tx)

    return (gas_used, matches, time_)


def main():
    deployer = accounts[0]
    tm_contract = deployer.deploy(TextMatching, gas_limit=12000000)
    address = tm_contract.address
    print('Contract address: ', address)
    
    with open('results-multi-pat.txt', 'at') as r_file:
        for repeat in range(REPEATS):
            for corpus in CORPUSES:
                for n in N_SET:
                    t_fpath = f'texts/text.{corpus}.{n}.bin'
                    with open(t_fpath, 'rb') as t_file:
                        t = t_file.read().decode('iso-8859-1')
                    print(f'{t_fpath} ({len(t)})')
                    for m in M_SET:
                        p_dpath = f'patterns/pattern.{corpus}.{n}.{m}'
                        for p_fpath in glob.glob(p_dpath+"/*.bin"):
                            print("Processing " + p_fpath)
                            with open(p_fpath, 'rb') as p_file:
                                p = p_file.read().decode('iso-8859-1')
                            assert len(p) == m
                            print(f'{p_fpath} ({len(p)})')
                            for alg_name in ALGORITHMS:

                                gas_used, matches, time_ = transact(tm_contract, alg_name, t, p)
                                print(f'{p_fpath},{corpus},{n},{m},{alg_name},{gas_used},{matches},{time_:.4f}\n', flush=True)
                                r_file.write(f'{p_fpath},{corpus},{n},{m},{alg_name},{gas_used},{matches},{time_:.4f}\n')
                                r_file.flush()
                                print('-----')

