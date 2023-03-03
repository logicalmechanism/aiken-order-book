import cbor2
import json


def prepend_cbor_length(cbor_string):
    original_bytes = bytes.fromhex(cbor_string)

    # Encode the length of the byte array as a CBOR string.
    new_cbor = cbor2.dumps(original_bytes)
    
    return new_cbor.hex()



if __name__ == "__main__":
    with open('../plutus.json') as f:
        data = json.load(f)

    compiled_code = data['validators'][0]['compiledCode']
    
    new_compiled_code = prepend_cbor_length(compiled_code)
    
    data = {
        "type": "PlutusScriptV2",
        "description": "",
        "cborHex": new_compiled_code
    }

    with open('../order_book.plutus', 'w') as f:
        json.dump(data, f, indent=4)
    