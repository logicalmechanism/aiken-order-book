use aiken/dict
use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, TransactionId,
}
use aiken/transaction/credential.{Address, Inline, VerificationKeyCredential}
use aiken/transaction/value
use order_book/address
use order_book/datums.{Datum, OwnerInfo, SwapInfo, TokenInfo}
use order_book/redeemers.{UTxO}
use order_book/validators

pub fn datum_a() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 100 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 100 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_b() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"0102", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 100 }
  let want: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 100 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_c() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"0102", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 99 }
  let want: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 100 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn out_ref1() -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: #"" },
    output_index: 0,
  }
}

pub fn out_ref2() -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: #"" },
    output_index: 1,
  }
}

pub fn tx_valid(
  script_addr1: Address,
  script_addr2: Address,
  swap_addr1: Address,
  swap_addr2: Address,
  datum1: Datum,
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
            value: value.from_lovelace(100),
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
            value: value.from_asset(#"acab", #"beef", 100),
            datum: InlineDatum(datum1),
            reference_script: None,
          },
        },
      ],
      reference_inputs: [],
      outputs: [
        Output {
          address: swap_addr1,
          value: value.from_asset(#"acab", #"beef", 100),
          datum: InlineDatum(datum_a()),
          reference_script: None,
        },
        Output {
          address: swap_addr2,
          value: value.from_lovelace(100),
          datum: InlineDatum(datum_b()),
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

test good_full_swap_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let sell_addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"0102",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let utxo = UTxO(#"", 1)
  validators.full_swap_validation(
    datum_a(),
    tx_valid(script_addr, script_addr, sell_addr, buy_addr, datum_b()),
    utxo,
    out_ref1(),
  ) == True
}

test no_pay_full_swap_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let sell_addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let utxo = UTxO(#"", 1)
  validators.full_swap_validation(
    datum_a(),
    tx_valid(script_addr, script_addr, sell_addr, sell_addr, datum_b()),
    utxo,
    out_ref1(),
  ) == False
}

test bad_datum_full_swap_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let sell_addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"0102",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let utxo = UTxO(#"", 1)
  validators.full_swap_validation(
    datum_a(),
    tx_valid(script_addr, script_addr, sell_addr, buy_addr, datum_a()),
    utxo,
    out_ref1(),
  ) == False
}

test one_input_full_swap_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let sell_addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"0102",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let utxo = UTxO(#"", 1)
  validators.full_swap_validation(
    datum_a(),
    tx_valid(script_addr, sell_addr, sell_addr, buy_addr, datum_b()),
    utxo,
    out_ref1(),
  ) == False
}
