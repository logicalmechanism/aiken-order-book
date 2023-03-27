use aiken/list
use aiken/transaction.{OutputReference, Transaction}
use aiken/transaction/value
use order_book/address
use order_book/data
use order_book/datums.{Datum}
use order_book/helpers
use order_book/redeemers.{BuyAmount, BuyerInfo, UTxO}

pub fn remove_validation(
  datum: Datum,
  tx: Transaction,
  output_reference: OutputReference,
) -> Bool {
  // used by both redeemers
  let validating_input =
    helpers.get_validating_input(tx.inputs, output_reference)
  let validating_value =
    validating_input.output.value
  let script_addr =
    validating_input.output.address
  let seller_addr =
    address.create_address(datum.owner.pkh, datum.owner.sc)
  list.and(
    [
      // owner must sign it
      helpers.must_be_signed_by(tx, datum.owner.pkh)?,
      // owner must get the utxo back
      address.find_exact_payout(seller_addr, validating_value, tx.outputs)?,
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
    helpers.get_validating_input(tx.inputs, output_reference)
  let script_addr =
    validating_input.output.address
  expect outbound_datum: Datum =
    helpers.get_outbound_datum(tx, validating_input)
  list.and(
    [
      // the owner must sign it
      helpers.must_be_signed_by(tx, datum.owner.pkh)?,
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
  this_output_reference: OutputReference,
) -> Bool {
  // used by both redeemers
  let validating_input =
    helpers.get_validating_input(tx.inputs, this_output_reference)
  let this_validating_value =
    validating_input.output.value
  let script_addr =
    validating_input.output.address
  let that_output_reference =
    helpers.create_output_reference(redeemer)
  let that_validating_input =
    helpers.get_validating_input(tx.inputs, that_output_reference)
  expect that_datum: Datum =
    data.find_inbound_datum(that_validating_input)
  let that_addr =
    address.create_address(that_datum.owner.pkh, that_datum.owner.sc)
  let have_value =
    value.from_asset(
      this_datum.have.pid,
      this_datum.have.tkn,
      this_datum.have.amt,
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
      ) >= this_datum.have.amt)?,
      // the other address gets paid this have token
      address.find_token_payout(that_addr, have_value, tx.outputs)?,
    ],
  )
}

pub fn part_swap_validation(
  this_datum: Datum,
  tx: Transaction,
  redeemer: UTxO,
  this_output_reference: OutputReference,
) -> Bool {
  // used by both redeemers
  let this_validating_input =
    helpers.get_validating_input(tx.inputs, this_output_reference)
  let this_validating_value =
    this_validating_input.output.value
  let script_addr =
    this_validating_input.output.address
  let that_output_reference =
    helpers.create_output_reference(redeemer)
  let that_validating_input =
    helpers.get_validating_input(tx.inputs, that_output_reference)
  expect that_datum: Datum =
    data.find_inbound_datum(that_validating_input)
  let that_addr =
    address.create_address(that_datum.owner.pkh, that_datum.owner.sc)
  let have_value =
    value.from_asset(
      this_datum.have.pid,
      this_datum.have.tkn,
      this_datum.have.amt,
    )
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
      ) >= this_datum.have.amt)?,
      // big fish little fish partial swap
      if datums.check_if_cont(this_datum, that_datum) == True {
        // little fish pays big fish
        address.find_token_payout(that_addr, have_value, tx.outputs)?
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
        expect outbound_datum: Datum =
          helpers.get_outbound_datum(tx, this_validating_input)
        list.and(
          [
            // the script gets the left over partial trade
            address.find_exact_payout(script_addr, partial_value, tx.outputs)?,
            // the little fish gets what it wants
            address.find_token_payout(that_addr, that_want_token, tx.outputs)?,
            // the continuing utxo has an updated datum
            datums.part_swap_cont_check(this_datum, outbound_datum, that_datum)?,
          ],
        )
      },
    ],
  )
}

pub fn full_buy_validation(
  this_datum: Datum,
  tx: Transaction,
  this_output_reference: OutputReference,
  buyer: BuyerInfo,
) -> Bool {
  // used by both redeemers
  let this_validating_input =
    helpers.get_validating_input(tx.inputs, this_output_reference)
  let this_validating_value =
    this_validating_input.output.value
  let script_addr =
    this_validating_input.output.address
  let seller_addr =
    address.create_address(this_datum.owner.pkh, this_datum.owner.sc)
  let buyer_addr =
    address.create_address(buyer.pkh, buyer.sc)
  let have_value =
    value.from_asset(
      this_datum.have.pid,
      this_datum.have.tkn,
      this_datum.have.amt,
    )
  let want_value =
    value.from_asset(
      this_datum.want.pid,
      this_datum.want.tkn,
      this_datum.want.amt,
    )
  list.and(
    [
      // the buyer must sign
      helpers.must_be_signed_by(tx, buyer.pkh)?,
      // the buyer gets this values have token
      address.find_token_payout(buyer_addr, have_value, tx.outputs)?,
      // the seller gets this datums want token
      address.find_token_payout(seller_addr, want_value, tx.outputs)?,
      // single script input
      (address.count_script_inputs(tx.inputs, script_addr, 0) == 1)?,
      // no script outputs
      (address.count_script_outputs(tx.outputs, script_addr, 0) == 0)?,
      // owner can not lie
      (value.quantity_of(
        this_validating_value,
        this_datum.have.pid,
        this_datum.have.tkn,
      ) >= this_datum.have.amt)?,
    ],
  )
}

pub fn part_buy_validation(
  this_datum: Datum,
  tx: Transaction,
  this_output_reference: OutputReference,
  buyer: BuyerInfo,
  amount: BuyAmount,
) -> Bool {
  // used by both redeemers
  let this_validating_input =
    helpers.get_validating_input(tx.inputs, this_output_reference)
  let this_validating_value =
    this_validating_input.output.value
  let script_addr =
    this_validating_input.output.address
  let seller_addr =
    address.create_address(this_datum.owner.pkh, this_datum.owner.sc)
  let buyer_addr =
    address.create_address(buyer.pkh, buyer.sc)
  let buyer_token =
    value.from_asset(this_datum.have.pid, this_datum.have.tkn, amount.amt)
  let pay_amt =
    datums.token_price(this_datum, amount.amt)
  let pay_token =
    value.from_asset(this_datum.want.pid, this_datum.want.tkn, amount.amt)
  let pay_value =
    value.from_asset(this_datum.have.pid, this_datum.have.tkn, pay_amt)
  let partial_value =
    value.add(this_validating_value, value.negate(pay_value))
  expect outbound_datum: Datum =
    helpers.get_outbound_datum(tx, this_validating_input)
  list.and(
    [
      // the buyer must sign
      helpers.must_be_signed_by(tx, buyer.pkh)?,
      // the continuing utxo must have a correct datum
      datums.part_buy_datum_check(this_datum, outbound_datum, pay_amt)?,
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
      (value.quantity_of(
        this_validating_value,
        this_datum.have.pid,
        this_datum.have.tkn,
      ) >= this_datum.have.amt)?,
      // buyer can buy what the owner doesn't have
      (value.quantity_of(
        this_validating_value,
        this_datum.have.pid,
        this_datum.have.tkn,
      ) >= amount.amt)?,
    ],
  )
}
