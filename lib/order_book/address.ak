use aiken/list
use aiken/transaction.{Input, Output}
use aiken/transaction/credential.{
  Address, Inline, StakeCredential, VerificationKeyCredential,
}
use aiken/transaction/value.{Value}
use order_book/datums.{PublicKeyHash, TokenInfo}

pub fn count_script_inputs(
  inputs: List<Input>,
  script_addr: Address,
  counter: Int,
) -> Int {
  when inputs is {
    [input, ..rest] ->
      if input.output.address == script_addr {
        count_script_inputs(rest, script_addr, counter + 1)
      } else {
        count_script_inputs(rest, script_addr, counter)
      }
    [] -> counter
  }
}

// need function that counts script outputs
pub fn count_script_outputs(
  outputs: List<Output>,
  script_addr: Address,
  counter: Int,
) -> Int {
  when outputs is {
    [output, ..rest] ->
      if output.address == script_addr {
        count_script_outputs(rest, script_addr, counter + 1)
      } else {
        count_script_outputs(rest, script_addr, counter)
      }
    [] -> counter
  }
}

pub fn find_input_address(possible_input: Option<Input>) -> Address {
  when possible_input is {
    Some(possible_input) -> possible_input.output.address
    None -> error @"can't find script address"
  }
}

pub fn find_cont_payout(pay_address: Address, outputs: List<Output>) -> Bool {
  list.any(outputs, fn(output) { output.address == pay_address })
}

pub fn find_exact_payout(
  pay_address: Address,
  pay_value: Value,
  outputs: List<Output>,
) -> Bool {
  list.any(
    outputs,
    fn(output) {
      list.and([(output.address == pay_address)?, (output.value == pay_value)?])
    },
  )
}

pub fn find_token_payout(
  pay_address: Address,
  pay_value: TokenInfo,
  outputs: List<Output>,
) -> Bool {
  list.any(
    outputs,
    fn(output) {
      list.and(
        [
          output.address == pay_address,
          value.quantity_of(output.value, pay_value.pid, pay_value.tkn) >= pay_value.amt,
        ],
      )
    },
  )
}

pub fn create_address(
  key_hash: PublicKeyHash,
  stake_credential: PublicKeyHash,
) -> Address {
  if stake_credential == #"" {
    payment_address(key_hash, None)
  } else {
    payment_address(
      key_hash,
      Some(Inline(VerificationKeyCredential(stake_credential))),
    )
  }
}

pub fn payment_address(
  key_hash: PublicKeyHash,
  with_stake_credential: Option<StakeCredential>,
) {
  Address {
    payment_credential: VerificationKeyCredential(key_hash),
    stake_credential: with_stake_credential,
  }
}
