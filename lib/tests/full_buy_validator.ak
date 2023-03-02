use aiken/dict
use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction, TransactionId,
}
use aiken/transaction/credential.{Address, Inline, VerificationKeyCredential}
use aiken/transaction/value
use order_book/address
use order_book/datums.{Datum, OwnerInfo, SwapInfo, TokenInfo}
use order_book/redeemers.{BuyerInfo}
use order_book/validators

pub fn datum_a() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 10 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 10 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_b() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"0102", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 10 }
  let want: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 10 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn out_ref() -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: #"" },
    output_index: 0,
  }
}

pub fn bad_out_ref() -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: #"" },
    output_index: 1,
  }
}

pub fn tx_valid(
  script_addr: Address,
  other_addr: Address,
  addr: Address,
  out_addr: Address,
  signer,
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
            address: script_addr,
            value: value.from_lovelace(10),
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
            address: other_addr,
            value: value.from_lovelace(5),
            datum: InlineDatum(datum_a()),
            reference_script: None,
          },
        },
      ],
      reference_inputs: [],
      outputs: [
        Output {
          address: addr,
          value: value.from_asset(#"acab", #"beef", 10),
          datum: InlineDatum(datum_a()),
          reference_script: None,
        },
        Output {
          address: out_addr,
          value: value.from_lovelace(10),
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
      extra_signatories: [signer],
      redeemers: dict.new(),
      datums: dict.new(),
      id: TransactionId { hash: #"" },
    }
  tx
}

test good_full_buy_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"acab",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let buyer = BuyerInfo(#"acab", #"")
  validators.full_buy_validation(
    datum_a(),
    tx_valid(script_addr, addr, addr, buy_addr, #"acab"),
    out_ref(),
    buyer,
  ) == True
}

test bad_signer_full_buy_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"acab",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let buyer = BuyerInfo(#"acab", #"")
  validators.full_buy_validation(
    datum_a(),
    tx_valid(script_addr, addr, addr, buy_addr, #""),
    out_ref(),
    buyer,
  ) == False
}

test wrong_pay_full_buy_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"acab",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let buyer = BuyerInfo(#"acab", #"")
  validators.full_buy_validation(
    datum_a(),
    tx_valid(script_addr, addr, buy_addr, buy_addr, #"acab"),
    out_ref(),
    buyer,
  ) == False
}

test wrong_buy_full_buy_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buyer = BuyerInfo(#"acab", #"")
  validators.full_buy_validation(
    datum_a(),
    tx_valid(script_addr, addr, addr, addr, #"acab"),
    out_ref(),
    buyer,
  ) == False
}

test two_inputs_full_buy_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"acab",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let buyer = BuyerInfo(#"acab", #"")
  validators.full_buy_validation(
    datum_a(),
    tx_valid(script_addr, script_addr, addr, buy_addr, #"acab"),
    out_ref(),
    buyer,
  ) == False
}

test not_enough_full_buy_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  let buy_addr =
    address.payment_address(
      #"acab",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  let buyer = BuyerInfo(#"acab", #"")
  validators.full_buy_validation(
    datum_a(),
    tx_valid(addr, script_addr, addr, buy_addr, #"acab"),
    bad_out_ref(),
    buyer,
  ) == False
}
