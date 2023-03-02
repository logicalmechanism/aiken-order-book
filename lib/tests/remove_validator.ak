use aiken/dict
use aiken/interval.{Interval, IntervalBound, NegativeInfinity, PositiveInfinity}
use aiken/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
  TransactionId,
}
use aiken/transaction/credential.{Address, Inline, VerificationKeyCredential}
use aiken/transaction/value
use order_book/address
use order_book/datums.{Datum, OwnerInfo, SwapInfo, TokenInfo}
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

pub fn tx_valid(
  script_addr: Address,
  other_addr: Address,
  addr: Address,
  signer: ByteArray,
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
            value: value.from_lovelace(10000),
            datum: InlineDatum(datum_a()),
            reference_script: None,
          },
        },
        Input {
          output_reference: OutputReference {
            transaction_id: TransactionId { hash: #"" },
            output_index: 0,
          },
          output: Output {
            address: other_addr,
            value: value.from_lovelace(10000),
            datum: InlineDatum(datum_a()),
            reference_script: None,
          },
        },
      ],
      reference_inputs: [],
      outputs: [
        Output {
          address: addr,
          value: value.from_lovelace(10000),
          datum: NoDatum,
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

test good_remove_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  validators.remove_validation(
    datum_a(),
    tx_valid(script_addr, addr, addr, #""),
    out_ref(),
  ) == True
}

test wrong_signer_remove_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  validators.remove_validation(
    datum_a(),
    tx_valid(script_addr, addr, addr, #"acab"),
    out_ref(),
  ) == False
}

test double_script_remove_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(#"", Some(Inline(VerificationKeyCredential(#""))))
  validators.remove_validation(
    datum_a(),
    tx_valid(script_addr, script_addr, addr, #""),
    out_ref(),
  ) == False
}

test wrong_payout_remove_tx() {
  let script_addr = address.payment_address(#"0102", None)
  let addr =
    address.payment_address(
      #"acab",
      Some(Inline(VerificationKeyCredential(#""))),
    )
  validators.remove_validation(
    datum_a(),
    tx_valid(script_addr, addr, addr, #""),
    out_ref(),
  ) == False
}
