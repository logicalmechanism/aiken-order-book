#!/usr/bin/bash
set -e

source .node.env

echo -e "\033[1;35m Creating Contract Reference UTxOs \033[0m" 

swap_script_path="../order_book.plutus"

# save the script addresses into the address folder
echo -n $(${cli} address build --payment-script-file ${swap_script_path} ${network}) > ${ROOT}/addresses/swap.addr

spo_addr=$(cat ${ROOT}/addresses/payment2.addr)
reference_address=$(cat ${ROOT}/addresses/reference.addr)
cardano-cli query utxo --address ${spo_addr} --testnet-magic 42 --out-file ${ROOT}/tmp/spo_utxo.json

TXNS=$(jq length ${ROOT}/tmp/spo_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${spo_addr}! \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' ${ROOT}/tmp/spo_utxo.json)
spo_tx_in=${TXIN::-8}
echo "SPO TxIn: $spo_tx_in"

echo -e "\033[0;36m Calculating Reference ADA \033[0m"
swap_min_utxo=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ${ROOT}/tmp/protocol-parameters.json \
    --tx-out-reference-script-file ${swap_script_path} \
    --tx-out="${reference_address} + 5000000" | tr -dc '0-9')
echo "Swap Contract Min ADA" ${swap_min_utxo}

swap_script_reference_utxo="${reference_address} + ${swap_min_utxo}"

# chain second set of reference scripts to the first
echo -e "\033[0;36m Building Tx \033[0m"

starting_spo_lovelace=$(jq '[.. | objects | .lovelace] | add' ${ROOT}/tmp/spo_utxo.json)

${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ${ROOT}/tmp/protocol-parameters.json \
    --out-file ${ROOT}/tmp/tx.draft \
    --tx-in ${spo_tx_in} \
    --tx-out="${spo_addr} + ${starting_spo_lovelace}" \
    --tx-out="${swap_script_reference_utxo}" \
    --tx-out-reference-script-file ${swap_script_path} \
    --fee 900000
FEE=$(${cli} transaction calculate-min-fee --tx-body-file ${ROOT}/tmp/tx.draft ${network} --protocol-params-file ${ROOT}/tmp/protocol-parameters.json --tx-in-count 0 --tx-out-count 0 --witness-count 1)
# echo $FEE
fee=$(echo $FEE | rev | cut -c 9- | rev)
# echo $fee
# exit
firstReturn=$((${starting_spo_lovelace} - ${swap_min_utxo} - ${fee}))
# echo $firstReturn
# exit
${cli} transaction build-raw \
    --babbage-era \
    --protocol-params-file ${ROOT}/tmp/protocol-parameters.json \
    --out-file ${ROOT}/tmp/tx.draft \
    --tx-in ${spo_tx_in} \
    --tx-out="${spo_addr} + ${firstReturn}" \
    --tx-out="${swap_script_reference_utxo}" \
    --tx-out-reference-script-file ${swap_script_path} \
    --fee ${fee}

echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ${ROOT}/stake-delegator-keys/payment2.skey \
    --tx-body-file ${ROOT}/tmp/tx.draft \
    --out-file ${ROOT}/tmp/tx-1.signed \
    ${network}
#
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} transaction submit \
    ${network} \
    --tx-file ${ROOT}/tmp/tx-1.signed

cp ${ROOT}/tmp/tx-1.signed ${ROOT}/tmp/tx-swap-utxo.signed