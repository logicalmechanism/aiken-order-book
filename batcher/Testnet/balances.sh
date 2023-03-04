#!/usr/bin/bash
set -e

source .node.env

#
script_path="../order_book.plutus"
script_address=$(${cli} address build --payment-script-file ${script_path} ${network})
#
seller_address=$(cat ${ROOT}/addresses/seller.addr)
buyer_address=$(cat ${ROOT}/addresses/buyer.addr)
batcher_address=$(cat ${ROOT}/addresses/batcher.addr)
reference_address=$(cat ${ROOT}/addresses/reference.addr)
collat_address=$(cat ${ROOT}/addresses/collat.addr)
minter_address=$(cat ${ROOT}/addresses/minter.addr)
#
echo
echo -e "\033[1;35m Script Address:" 
echo -e "\n${script_address}\n";
${cli} query utxo --address ${script_address} ${network}
echo -e "\033[0m"
#
echo
echo -e "\033[1;35m Reference Address:" 
echo -e "\n${reference_address}\n";
${cli} query utxo --address ${reference_address} ${network}
echo -e "\033[0m"
#
echo
echo -e "\033[1;36m Seller Address:" 
echo -e "\n${seller_address}\n";
${cli} query utxo --address ${seller_address} ${network}
echo -e "\033[0m"
#
echo
echo -e "\033[1;32m Buyer Address:" 
echo -e "\n${buyer_address}\n";
${cli} query utxo --address ${buyer_address} ${network}
echo -e "\033[0m"
#
echo
echo -e "\033[1;34m Batcher Address:" 
echo -e "\n${batcher_address}\n";
${cli} query utxo --address ${batcher_address} ${network}
echo -e "\033[0m"

#
echo
echo -e "\033[1;34m Minter Address:" 
echo -e "\n \033[1;34m ${minter_address}\n";
${cli} query utxo --address ${minter_address} ${network}
echo -e "\033[0m"

#
echo
echo -e "\033[1;33m Collateral Address:" 
echo -e "\n${collat_address}\n";
${cli} query utxo --address ${collat_address} ${network}
echo -e "\033[0m"