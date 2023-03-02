use aiken/list
use aiken/transaction.{Input, OutputReference, Transaction, TransactionId}
use aiken/transaction/credential.{Inline, VerificationKeyCredential}
use aiken/transaction/value.{Value}
use order_book/address
use order_book/data
use order_book/datums.{Datum, PublicKeyHash, TokenInfo}
use order_book/redeemers.{BuyAmount, BuyerInfo, UTxO}

fn create_output_reference(utxo: UTxO) -> OutputReference {
  OutputReference {
    transaction_id: TransactionId { hash: utxo.tx },
    output_index: utxo.idx,
  }
}

fn find_input_value(possible_input: Option<Input>) -> Value {
  when possible_input is {
    Some(possible_input) -> possible_input.output.value
    None -> error @"no value on spending input"
  }
}

fn must_be_signed_by(transaction: Transaction, vk: PublicKeyHash) {
  list.has(transaction.extra_signatories, vk)
}

pub fn remove_validation(
  datum: Datum,
  tx: Transaction,
  output_reference: OutputReference,
) -> Bool {
  let validating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == output_reference },
    )
  let validating_value = find_input_value(validating_input)
  let script_addr = address.find_input_address(validating_input)
  let addr =
    address.payment_address(
      datum.owner.pkh,
      Some(Inline(VerificationKeyCredential(datum.owner.sc))),
    )
  list.and(
    [
      // owner must sign it
      must_be_signed_by(tx, datum.owner.pkh)?,
      // owner must get the utxo back
      address.find_exact_payout(addr, validating_value, tx.outputs)?,
      // single script input
      (address.count_script_inputs(tx.inputs, script_addr, 0) == 1)?,
      // no script outputs
      (address.count_script_outputs(tx.outputs, script_addr, 0) == 0)?,
    ],
  )
}

pub fn update_validation(
  datum: Datum,
  tx: Transaction,
  output_reference: OutputReference,
) -> Bool {
  let validating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == output_reference },
    )
  let script_addr = address.find_input_address(validating_input)
  let outbound_output =
    list.find(tx.outputs, fn(output) { output.address == script_addr })
  expect outbound_datum: Datum = data.find_outbound_datum(outbound_output)
  list.and(
    [
      // the owner must sign it
      must_be_signed_by(tx, datum.owner.pkh)?,
      // a utxo must go back to the script
      address.find_cont_payout(script_addr, tx.outputs)?,
      // the owner of the cont utxo must remain constant
      datums.constant_ownership(datum, outbound_datum)?,
      // single script input
      (address.count_script_inputs(tx.inputs, script_addr, 0) == 1)?,
      // single script output
      (address.count_script_outputs(tx.outputs, script_addr, 0) == 1)?,
    ],
  )
}

pub fn full_swap_validation(
  this_datum: Datum,
  tx: Transaction,
  redeemer: UTxO,
  output_reference: OutputReference,
) -> Bool {
  let this_validating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == output_reference },
    )
  let script_addr = address.find_input_address(this_validating_input)
  let this_validating_value = find_input_value(this_validating_input)
  let that_output_reference = create_output_reference(redeemer)
  let that_vaidating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == that_output_reference },
    )
  expect that_datum: Datum = data.find_inbound_datum(that_vaidating_input)
  let that_addr =
    address.payment_address(
      that_datum.owner.pkh,
      Some(Inline(VerificationKeyCredential(that_datum.owner.sc))),
    )
  list.and(
    [
      // double script inputs
      (address.count_script_inputs(tx.inputs, script_addr, 0) == 2)?,
      // no script output
      (address.count_script_outputs(tx.outputs, script_addr, 0) == 0)?,
      // both utxos must have swappable and mirror datums
      datums.full_swap_datum_check(this_datum, that_datum)?,
      // the owner can not lie
      (value.quantity_of(
        this_validating_value,
        this_datum.have.pid,
        this_datum.have.tkn,
      ) == this_datum.have.amt)?,
      // the other address gets paid this have token
      address.find_token_payout(that_addr, this_datum.have, tx.outputs)?,
    ],
  )
}

pub fn part_swap_validation(
  this_datum: Datum,
  tx: Transaction,
  redeemer: UTxO,
  output_reference: OutputReference,
) -> Bool {
  let this_validating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == output_reference },
    )
  let script_addr = address.find_input_address(this_validating_input)
  let this_validating_value = find_input_value(this_validating_input)
  let that_output_reference = create_output_reference(redeemer)
  let that_vaidating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == that_output_reference },
    )
  expect that_datum: Datum = data.find_inbound_datum(that_vaidating_input)
  let that_addr = address.payment_address(that_datum.owner.pkh, None)
  list.and(
    [
      // double script inputs
      (address.count_script_inputs(tx.inputs, script_addr, 0) == 2)?,
      // single script output
      (address.count_script_outputs(tx.outputs, script_addr, 0) == 1)?,
      // both utxos must be swappable and mirrored
      datums.part_swap_datum_check(this_datum, that_datum)?,
      // owner can not lie
      (value.quantity_of(
        this_validating_value,
        this_datum.have.pid,
        this_datum.have.tkn,
      ) == this_datum.have.amt)?,
      // big fish little fish partial swap
      if datums.check_if_cont(this_datum, that_datum) == True {
        // little fish pays big fish
        address.find_token_payout(that_addr, this_datum.have, tx.outputs)?
      } else {
        // big fish gets nibbled at
        let that_want_token =
          value.from_asset(
            that_datum.want.pid,
            that_datum.want.tkn,
            that_datum.want.amt,
          )
        let partial_value =
          value.add(this_validating_value, value.negate(that_want_token))
        let outbound_output =
          list.find(tx.outputs, fn(output) { output.address == script_addr })
        expect outbound_datum: Datum = data.find_outbound_datum(outbound_output)
        list.and(
          [
            // the script gets the left over partial trade
            address.find_exact_payout(script_addr, partial_value, tx.outputs)?,
            // the little fish gets what it wants
            address.find_token_payout(that_addr, that_datum.want, tx.outputs)?,
            // the continuing utxo has an updated datum
            datums.part_swap_cont_check(this_datum, outbound_datum, that_datum)?,
          ],
        )
      },
    ],
  )
}

pub fn full_buy_validation(
  datum: Datum,
  tx: Transaction,
  output_reference: OutputReference,
  buyer: BuyerInfo,
) -> Bool {
  // Must be signed by the owner and the value must return to the owner.
  let validating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == output_reference },
    )
  let validating_value = find_input_value(validating_input)
  let script_addr = address.find_input_address(validating_input)
  let addr =
    address.payment_address(
      datum.owner.pkh,
      Some(Inline(VerificationKeyCredential(datum.owner.sc))),
    )
  let buyer_addr =
    address.payment_address(
      buyer.pkh,
      Some(Inline(VerificationKeyCredential(buyer.sc))),
    )
  list.and(
    [
      // the buyer must sign
      must_be_signed_by(tx, buyer.pkh)?,
      // the buyer gets this values have token
      address.find_token_payout(buyer_addr, datum.have, tx.outputs)?,
      // the seller gets this datums want token
      address.find_token_payout(addr, datum.want, tx.outputs)?,
      // single script input
      (address.count_script_inputs(tx.inputs, script_addr, 0) == 1)?,
      // no script outputs
      (address.count_script_outputs(tx.outputs, script_addr, 0) == 0)?,
      // owner can not lie
      (value.quantity_of(validating_value, datum.have.pid, datum.have.tkn) == datum.have.amt)?,
    ],
  )
}

pub fn part_buy_validation(
  datum: Datum,
  tx: Transaction,
  output_reference: OutputReference,
  buyer: BuyerInfo,
  amount: BuyAmount,
) -> Bool {
  let validating_input =
    list.find(
      tx.inputs,
      fn(input) { input.output_reference == output_reference },
    )
  let validating_value = find_input_value(validating_input)
  let script_addr = address.find_input_address(validating_input)
  let seller_addr =
    address.payment_address(
      datum.owner.pkh,
      Some(Inline(VerificationKeyCredential(datum.owner.sc))),
    )
  let buyer_addr =
    address.payment_address(
      buyer.pkh,
      Some(Inline(VerificationKeyCredential(buyer.sc))),
    )
  let buyer_token = TokenInfo(datum.have.pid, datum.have.tkn, amount.amt)
  let pay_amt = datums.token_price(datum, amount.amt)
  let pay_token = TokenInfo(datum.want.pid, datum.want.tkn, pay_amt)
  let pay_value =
    value.from_asset(
      datum.have.pid,
      datum.have.tkn,
      datum.have.amt - amount.amt,
    )
  let partial_value = value.add(validating_value, value.negate(pay_value))
  let outbound_output =
    list.find(tx.outputs, fn(output) { output.address == script_addr })
  expect outbound_datum: Datum = data.find_outbound_datum(outbound_output)
  list.and(
    [
      // the buyer must sign
      must_be_signed_by(tx, buyer.pkh)?,
      // the continuing utxo must have a correct datum
      datums.part_buy_datum_check(datum, outbound_datum, pay_amt)?,
      // the buyer gets want they want to buy
      address.find_token_payout(buyer_addr, buyer_token, tx.outputs)?,
      // the seller gets paid what they want
      address.find_token_payout(seller_addr, pay_token, tx.outputs)?,
      // the leftover partial token gets send back to the script
      address.find_exact_payout(script_addr, partial_value, tx.outputs)?,
      // single script input
      (address.count_script_inputs(tx.inputs, script_addr, 0) == 1)?,
      // single script output
      (address.count_script_outputs(tx.outputs, script_addr, 0) == 1)?,
      // owner can not lie
      (value.quantity_of(validating_value, datum.have.pid, datum.have.tkn) == datum.have.amt)?,
      // buyer can buy what the owner doesn't have
      (value.quantity_of(validating_value, datum.have.pid, datum.have.tkn) >= amount.amt)?,
    ],
  )
}
