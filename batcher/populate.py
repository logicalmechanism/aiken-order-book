import subprocess
import random
import json
from dotenv import load_dotenv, find_dotenv
import os
import glob


def build_raw(minter_lovelace_in, minter_token_in, token_out, lovelace_change, token_change, fee):
    
    with open('node/addresses/minter.addr', 'r') as f:
        minter_addr = f.readline().strip('\n')
    with open('node/addresses/minter.pkh', 'r') as f:
        minter_pkh = f.readline().strip('\n')

    with open('node/addresses/swap.addr', 'r') as f:
        script_addr = f.readline().strip('\n')
    
    
    minter_lovelace_out = f"{minter_addr} + {lovelace_change}"
    minter_token_out = f"{minter_addr} + {5000000} + {token_change}"
    script_out = f"{script_addr} + 5000000 + {token_out}"
    
    
    cmd = [
        'cardano-cli',
        'transaction',
        'build-raw',
        '--babbage-era',
        '--protocol-params-file', 'node/tmp/protocol-parameters.json',
        '--out-file', 'node/tmp/tx.draft',
        '--tx-in', minter_lovelace_in,
        '--tx-in', minter_token_in,
        '--tx-out', minter_lovelace_out,
        '--tx-out', minter_token_out,
        '--tx-out', script_out,
        '--tx-out-inline-datum-file', './data/datum.json',
        '--required-signer-hash', minter_pkh,
        '--fee', str(fee)
    ]

    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')


def sign_tx(counter):
    cmd = [
        'cardano-cli',
        'transaction',
        'sign',
        '--signing-key-file', 'node/addresses/minter.skey',
        '--tx-body-file', 'node/tmp/tx.draft',
        '--out-file', 'node/tmp/tx-'+str(counter)+'.signed',
        '--testnet-magic', '42'
    ]
    
    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')

def submit_tx(counter):
    cmd = [
        'cardano-cli',
        'transaction',
        'submit',
        '--testnet-magic', '42',
        '--tx-file', 'node/tmp/tx-'+str(counter)+'.signed',
    ]
    
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
        print(result.stdout.strip())
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')

def tx_hash():
    cmd = [
        'cardano-cli',
        'transaction',
        'txid',
        '--tx-body-file', 'node/tmp/tx.draft'
    ]
    try:
        result = subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')


def calculate_have_want():
    p_0 = random.gauss(2.5, 1)
    if p_0 <= 0:
        return calculate_have_want()
    want = random.randint(10000,100000)
    have = int(p_0*want)
    if have < 0 or want < 0:
        return calculate_have_want()
    return have, want

def create_datum(owner, have, have_amt, want, want_amt):
    data = {
        "constructor": 0,
        "fields": [
            {
                "constructor": 0,
                "fields": [
                    {
                        "bytes": owner
                    },
                    {
                        "bytes": ""
                    }
                ]
            },
            {
                "constructor": 0,
                "fields": [
                    {
                        "bytes": have
                    },
                    {
                        "bytes": "5468697349734f6e6553746172746572546f6b656e466f7254657374696e6731"
                    },
                    {
                        "int": have_amt
                    }
                ]
            },
            {
                "constructor": 0,
                "fields": [
                    {
                        "bytes": want
                    },
                    {
                        "bytes": "5468697349734f6e6553746172746572546f6b656e466f7254657374696e6731"
                    },
                    {
                        "int": want_amt
                    }
                ]
            },
            {
                "constructor": 0,
                "fields": [
                    {
                        "int": random.randint(10,100)
                    }
                ]
            }
        ]
    }
    with open('data/datum.json', 'w') as f:
        json.dump(data, f, indent=4)

def remove_files_matching_pattern():
    # Use glob to find files that match the pattern
    files_to_remove = glob.glob('node/tmp/tx-*.signed')

    # Remove each file in the list
    for file_path in files_to_remove:
        os.remove(file_path)

if __name__ == "__main__":
    # Load environment variables from .node.env file
    load_dotenv(find_dotenv('.node.env'), verbose=False)
    os.environ["CARDANO_NODE_SOCKET_PATH"] = os.getenv("socket")
    print(os.getenv("CARDANO_NODE_SOCKET_PATH"))
    
    n_tx = 150
    fee = 964314
    with open('node/tmp/minter-lovelace.txin', "r") as f:
        minter_lovelace_tx = f.readline().strip('\n') + "#5"
    
    with open('node/tmp/minter-token.txin', "r") as f:
        minter_token_tx = f.readline().strip('\n') + "#0"
    
    with open('policy/policy1.id', 'r') as f:
        policy1_id = f.readline().strip('\n')
    
    with open('policy/policy2.id', 'r') as f:
        policy2_id = f.readline().strip('\n')
    
    with open('node/addresses/seller.pkh', 'r') as f:
        seller_pkh = f.readline().strip('\n')
    
    with open('node/addresses/buyer.pkh', 'r') as f:
        buyer_pkh = f.readline().strip('\n')
    
    change = 10000000000
    token_a = 1234567890
    token_b = 1234567890
    token_name = "5468697349734f6e6553746172746572546f6b656e466f7254657374696e6734"
    
    # build and sign n_tx transactions
    for i in range(n_tx):
        have, want = calculate_have_want()
        
        if random.randint(0,1) == 0:
            owner = seller_pkh
        else:
            owner = buyer_pkh
        
        if random.randint(0,1) == 0:
            # pid 1 is have
            minter_out = f"{have} {policy1_id}.{token_name}"
            token_a -= have
            create_datum(owner, policy1_id, have, policy2_id, want)
        else:
            # pid 2 is have
            minter_out = f"{have} {policy2_id}.{token_name}"
            token_b -= have
            create_datum(owner, policy2_id, have, policy1_id, want)
        if token_a < 0 or token_b < 0:
            print(i)
            break
        token_change = f"{token_a} {policy1_id}.{token_name} + {token_b} {policy2_id}.{token_name}"
        
        # print(token_change)
        # print(minter_out)
        change = change - fee - 5000000
        
        build_raw(minter_lovelace_tx, minter_token_tx, minter_out, change, token_change, fee)
        sign_tx(i)
        nextHash = tx_hash()
        minter_lovelace_tx = nextHash + "#0"
        minter_token_tx = nextHash + "#1"
    
    # submit n_tx transactions
    for i in range(n_tx):
        submit_tx(i)
    
    remove_files_matching_pattern()
    