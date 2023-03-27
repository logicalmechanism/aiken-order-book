#!/usr/bin/bash
set -e

source .node.env

echo -e "\033[1;35m Creating Catalog Starter Token \033[0m"
echo

spo_addr=$(cat ${ROOT}/addresses/payment3.addr)
minter_address=$(cat ${ROOT}/addresses/minter.addr)
script_address=$(cat ${ROOT}/addresses/swap.addr)

cardano-cli query utxo --address ${spo_addr} ${network} --out-file ${ROOT}/tmp/spo_utxo.json

TXNS=$(jq length ${ROOT}/tmp/spo_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${spo_addr}! \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' ${ROOT}/tmp/spo_utxo.json)
spo_tx_in=${TXIN::-8}
# echo "SPO TxIn: $spo_tx_in"

# Get multisig
minter_pkh=$(${cli} address key-hash --payment-verification-key-file ${ROOT}/addresses/minter.vkey)


# jq -r '.scripts[0].keyHash' policy/policy1.script
variable=${minter_pkh}; jq --arg variable "$variable" '.scripts[0].keyHash=$variable' policy/policy1.script > policy/policy1-new.script
mv policy/policy1-new.script policy/policy1.script

variable=${minter_pkh}; jq --arg variable "$variable" '.scripts[0].keyHash=$variable' policy/policy2.script > policy/policy2-new.script
mv policy/policy2-new.script policy/policy2.script



policy1_id=$(cardano-cli transaction policyid --script-file policy/policy1.script)
policy2_id=$(cardano-cli transaction policyid --script-file policy/policy2.script)
echo $policy1_id > policy/policy1.id
echo $policy2_id > policy/policy2.id

token_name="5468697349734f6e6553746172746572546f6b656e466f7254657374696e6734"

mint_asset1="9223372036854775807 ${policy1_id}.${token_name}"
mint_asset2="9223372036854775807 ${policy2_id}.${token_name}"
total_mint_asset="${mint_asset1} + ${mint_asset2}"

echo "Starter Token 1: ${mint_asset1}"
echo "Starter Token 2: ${mint_asset2}"

minter_address_out="${minter_address} + 5000000 + ${mint_asset1} + ${mint_asset2}"

slot=$(${cli} query tip --testnet-magic 42 | jq .slot)
current_slot=$(($slot))
final_slot=$(($slot + 2500))

# echo $current_slot
# echo $final_slot

# exit
echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} transaction build \
    --babbage-era \
    --protocol-params-file ${ROOT}/tmp/protocol-parameters.json \
    --out-file ${ROOT}/tmp/tx.draft \
    --change-address ${spo_addr} \
    --invalid-before ${current_slot} \
    --invalid-hereafter ${final_slot} \
    --tx-in ${spo_tx_in} \
    --tx-out="${minter_address_out}" \
    --mint-script-file policy/policy1.script \
    --mint-script-file policy/policy2.script \
    --mint="${total_mint_asset}" \
    --required-signer-hash ${minter_pkh} \
    ${network})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"
FEE=${FEE[1]}
echo -e "\033[1;32m Fee: \033[0m" $FEE
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ${ROOT}/stake-delegator-keys/payment3.skey \
    --signing-key-file ${ROOT}/addresses/minter.skey \
    --tx-body-file ${ROOT}/tmp/tx.draft \
    --out-file ${ROOT}/tmp/tx.signed \
    ${network}
#    
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} transaction submit \
    ${network} \
    --tx-file ${ROOT}/tmp/tx.signed

minter_tx_in=$(${cli} transaction txid --tx-file ${ROOT}/tmp/tx.signed )

echo $minter_tx_in > ${ROOT}/tmp/minter-token.txin