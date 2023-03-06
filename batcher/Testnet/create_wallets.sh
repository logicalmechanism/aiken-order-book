#!/usr/bin/bash
set -e

source .node.env

echo -e "\033[1;35m Creating Test Wallets \033[0m" 

ADDR=seller
# payment address keys
cardano-cli address key-gen \
--verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--signing-key-file      ${ROOT}/addresses/${ADDR}.skey
# wallet address
cardano-cli address build \
--payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--testnet-magic 42 \
--out-file ${ROOT}/addresses/${ADDR}.addr

cardano-cli address key-hash --payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey --out-file ${ROOT}/addresses/${ADDR}.pkh


ADDR=buyer
# payment address keys
cardano-cli address key-gen \
--verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--signing-key-file      ${ROOT}/addresses/${ADDR}.skey
# wallet address
cardano-cli address build \
--payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--testnet-magic 42 \
--out-file ${ROOT}/addresses/${ADDR}.addr

cardano-cli address key-hash --payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey --out-file ${ROOT}/addresses/${ADDR}.pkh

ADDR=collat
# payment address keys
cardano-cli address key-gen \
--verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--signing-key-file      ${ROOT}/addresses/${ADDR}.skey
# wallet address
cardano-cli address build \
--payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--testnet-magic 42 \
--out-file ${ROOT}/addresses/${ADDR}.addr

cardano-cli address key-hash --payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey --out-file ${ROOT}/addresses/${ADDR}.pkh

ADDR=reference
# payment address keys
cardano-cli address key-gen \
--verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--signing-key-file      ${ROOT}/addresses/${ADDR}.skey
# wallet address
cardano-cli address build \
--payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--testnet-magic 42 \
--out-file ${ROOT}/addresses/${ADDR}.addr

cardano-cli address key-hash --payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey --out-file ${ROOT}/addresses/${ADDR}.pkh

ADDR=batcher
# payment address keys
cardano-cli address key-gen \
--verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--signing-key-file      ${ROOT}/addresses/${ADDR}.skey
# wallet address
cardano-cli address build \
--payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--testnet-magic 42 \
--out-file ${ROOT}/addresses/${ADDR}.addr

cardano-cli address key-hash --payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey --out-file ${ROOT}/addresses/${ADDR}.pkh

ADDR=minter
# payment address keys
cardano-cli address key-gen \
--verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--signing-key-file      ${ROOT}/addresses/${ADDR}.skey
# wallet address
cardano-cli address build \
--payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey \
--testnet-magic 42 \
--out-file ${ROOT}/addresses/${ADDR}.addr

cardano-cli address key-hash --payment-verification-key-file ${ROOT}/addresses/${ADDR}.vkey --out-file ${ROOT}/addresses/${ADDR}.pkh