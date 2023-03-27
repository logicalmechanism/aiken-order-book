import subprocess
import json
from dotenv import load_dotenv, find_dotenv
import os

def get_utxo(address):
    cmd = [
        'cardano-cli',
        'query',
        'utxo',
        '--address', address,
        '--out-file', 'node/tmp/utxo.json',
        '--testnet-magic', '42'
    ]
    
    try:
        subprocess.run(cmd, stdout=subprocess.PIPE, check=True, text=True)
    except subprocess.CalledProcessError as e:
        print(f'Error running command {cmd}: {e}')

def check_first_two_elements_equal(a, b):
    if a[0] == b[0] and a[1] == b[1]:
        return True
    else:
        return False

def get_token_info(datum):
    have = datum['fields'][1]['fields']
    have_tkn = (have[0]['bytes'],have[1]['bytes'],int(have[2]['int']))
    
    want = datum['fields'][2]['fields']
    want_tkn = (want[0]['bytes'],want[1]['bytes'],int(want[2]['int']))
    
    slip = int(datum['fields'][3]['fields'][0]['int'])
    
    return have_tkn, want_tkn, slip

def percentage(amt, pct):
    if pct <= 0:
        return 0
    else:
        return amt // pct

def is_int_in_range(value, slippage, target):
    low_end = value - percentage(value, slippage)
    high_end = value + percentage(value, slippage)
    return (low_end <= target and target <= high_end)

def effective_price(have_amt, want_amt):
    if want_amt == 0:
        return 0
    else:
        return (have_amt * 1000000) // want_amt


def is_in_effective_range(have_amt1, want_amt1, slip1, have_amt2, want_amt2):
    a_price = effective_price(have_amt1, want_amt1)
    b_price = effective_price(want_amt2, have_amt2)
    return is_int_in_range(a_price, slip1, b_price)

if __name__ == "__main__":
    # Load environment variables from .node.env file
    load_dotenv(find_dotenv('.node.env'), verbose=False)
    os.environ["CARDANO_NODE_SOCKET_PATH"] = os.getenv("socket")
    print(os.getenv("CARDANO_NODE_SOCKET_PATH"))
    
    with open('node/addresses/swap.addr', 'r') as f:
        script_addr = f.readline().strip('\n')
    
    get_utxo(script_addr)
    
    # Open the JSON file
    with open('node/tmp/utxo.json', 'r') as f:
        # Load the JSON data
        data = json.load(f)

    full_swap = []
    part_swap = []
    print("N Txs")
    print(len(data))
    # Do something with the data
    for tx_hash1 in data:
        datum = data[tx_hash1]['inlineDatum']
        
        # get have want slip
        have_tkn1, want_tkn1, slip1 = get_token_info(datum)
        
        for tx_hash2 in data:
            if tx_hash1 == tx_hash2:
                continue
            datum = data[tx_hash2]['inlineDatum']
            
            have_tkn2, want_tkn2, slip2 = get_token_info(datum)
            
            if check_first_two_elements_equal(have_tkn1, want_tkn2) is True and check_first_two_elements_equal(want_tkn1, have_tkn2) is True:

                if is_int_in_range(have_tkn1[2], slip1, want_tkn2[2]) is True and is_int_in_range(have_tkn2[2], slip2, want_tkn1[2]) is True:
                    if (tx_hash1, tx_hash2) not in full_swap and (tx_hash2, tx_hash1) not in full_swap:
                        full_swap.append((tx_hash1, tx_hash2))

                if is_in_effective_range(have_tkn1[2], want_tkn1[2], slip1, have_tkn2[2], want_tkn2[2]) is True and is_in_effective_range(have_tkn2[2], want_tkn2[2], slip2, have_tkn1[2], want_tkn1[2]) is True:
                    if (tx_hash1, tx_hash2) not in part_swap and (tx_hash2, tx_hash1) not in part_swap:
                        part_swap.append((tx_hash1, tx_hash2))
                
        # exit()
    print('full_swap')
    print(len(full_swap))
    
    print('part_swap')
    print(len(part_swap))
    
    
    x = full_swap[0]
    
    print(data[x[0]]['value'])
    print(data[x[0]]['inlineDatum'])
    
    print()
    
    
    print(data[x[1]]['value'])