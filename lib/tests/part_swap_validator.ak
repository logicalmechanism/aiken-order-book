use aiken/dict
use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
use aiken/list
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
  TransactionId,
}
use aiken/transaction/credential.{Address}
use aiken/transaction/value
use order_book/address
use order_book/data
use order_book/datums.{Datum, OwnerInfo, SwapInfo, TokenInfo}
use order_book/redeemers.{UTxO}
use order_book/validators

pub fn datum_a() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 200 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 100 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_a_cont() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 100 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 50 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_b() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"acab", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 50 }
  let want: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 100 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn out_ref0() -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: #"" },
    output_index: 0,
  }
}

pub fn out_ref1() -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: #"" },
    output_index: 1,
  }
}

pub fn tx_valid(
  script_addr1: Address,
  script_addr2: Address,
  script_addr3: Address,
  swap_addr1: Address,
  swap_addr2: Address,
) -> Transaction {
  let tx =
    Transaction {
      inputs: [
        Input {
          output_reference: OutputReference {
            transaction_id: TransactionId { hash: #"" },
            output_index: 0,
          },
          output: Output {
            address: script_addr1,
            value: value.from_lovelace(200),
            datum: InlineDatum(datum_a()),
            reference_script: None,
          },
        },
        Input {
          output_reference: OutputReference {
            transaction_id: TransactionId { hash: #"" },
            output_index: 1,
          },
          output: Output {
            address: script_addr2,
            value: value.from_asset(#"acab", #"beef", 50),
            datum: InlineDatum(datum_b()),
            reference_script: None,
          },
        },
      ],
      reference_inputs: [],
      outputs: [
        Output {
          address: swap_addr1,
          value: value.from_asset(#"acab", #"beef", 50),
          datum: NoDatum,
          reference_script: None,
        },
        Output {
          address: swap_addr2,
          value: value.from_lovelace(100),
          datum: NoDatum,
          reference_script: None,
        },
        Output {
          address: script_addr3,
          value: value.from_lovelace(100),
          datum: InlineDatum(datum_a_cont()),
          reference_script: None,
        },
      ],
      fee: value.zero(),
      mint: value.zero(),
      certificates: [],
      withdrawals: dict.new(),
      validity_range: Interval {
        lower_bound: IntervalBound {
          bound_type: NegativeInfinity,
          is_inclusive: True,
        },
        upper_bound: IntervalBound {
          bound_type: PositiveInfinity,
          is_inclusive: True,
        },
      },
      extra_signatories: [],
      redeemers: dict.new(),
      datums: dict.new(),
      id: TransactionId { hash: #"" },
    }
  tx
}

// this is throwing a FreeUnique error
test find_out_datum() {
  let script_addr = address.create_address(#"0102", #"")
  let sell_addr = address.create_address(#"", #"")
  let buy_addr = address.create_address(#"acab", #"")
  let tx = tx_valid(script_addr, script_addr, script_addr, sell_addr, buy_addr)
  let outbound_output =
    list.find(tx.outputs, fn(output) { output.address == script_addr })
  expect outbound_datum: Datum = data.find_outbound_datum(outbound_output)
  outbound_datum == datum_a_cont()
}

// this cant find the correct output
test good_part_swap_tx() {
  let script_addr = address.create_address(#"0102", #"")
  let sell_addr = address.create_address(#"", #"")
  let buy_addr = address.create_address(#"acab", #"")
  let utxo = UTxO(#"", 1)
  validators.part_swap_validation(
    datum_a(),
    tx_valid(script_addr, script_addr, script_addr, sell_addr, buy_addr),
    utxo,
    out_ref0(),
  ) == True
}
// test good_part_swap_tx2() {
//   let script_addr = address.create_address(#"0102", #"")
//   let sell_addr =
//     address.create_address(#"", #"")
//   let buy_addr =
//     address.create_address(
//       #"0102",
//       #"",
//     )
//   let utxo = UTxO(#"", 0)
//   validators.part_swap_validation(
//     datum_b(),
//     tx_valid(script_addr, script_addr, buy_addr, buy_addr, script_addr),
//     utxo,
//     out_ref2(),
//   ) == True
// }
