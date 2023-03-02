use aiken/list
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, TransactionId,
}
use aiken/transaction/value
use order_book/address

// sample data for testing
type SampleData {
  a: Int,
  b: ByteArray,
}

test list_and_fail() {
  list.and([1 == 2, 0 == 0])? == False
}

test no_script_inputs() {
  let key_hash = #"010203040506"
  let sample_datum = SampleData { a: 1, b: #"01" }
  let addr = address.payment_address(key_hash, None)
  let inputs = [
    Input {
      output_reference: OutputReference {
        transaction_id: TransactionId { hash: #"" },
        output_index: 0,
      },
      output: Output {
        address: addr,
        value: value.zero(),
        datum: InlineDatum(sample_datum),
        reference_script: None,
      },
    },
  ]
  address.count_script_inputs(inputs, address.payment_address(#"", None), 0) == 0
}

test single_script_input() {
  let key_hash = #"010203040506"
  let sample_datum = SampleData { a: 1, b: #"01" }
  let addr = address.payment_address(key_hash, None)
  let inputs = [
    Input {
      output_reference: OutputReference {
        transaction_id: TransactionId { hash: #"" },
        output_index: 0,
      },
      output: Output {
        address: addr,
        value: value.zero(),
        datum: InlineDatum(sample_datum),
        reference_script: None,
      },
    },
  ]
  address.count_script_inputs(inputs, addr, 0) == 1
}

test no_script_output() {
  let key_hash = #"010203040506"
  let sample_datum = SampleData { a: 1, b: #"01" }
  let addr = address.payment_address(key_hash, None)
  let outputs = [
    Output {
      address: addr,
      value: value.zero(),
      datum: InlineDatum(sample_datum),
      reference_script: None,
    },
  ]
  address.count_script_outputs(outputs, address.payment_address(#"", None), 0) == 0
}

test single_script_output() {
  let key_hash = #"010203040506"
  let sample_datum = SampleData { a: 1, b: #"01" }
  let addr = address.payment_address(key_hash, None)
  let outputs = [
    Output {
      address: addr,
      value: value.zero(),
      datum: InlineDatum(sample_datum),
      reference_script: None,
    },
  ]
  address.count_script_outputs(outputs, addr, 0) == 1
}

test single_input_address() {
  let key_hash = #"010203040506"
  let sample_datum = SampleData { a: 1, b: #"01" }
  let addr = address.payment_address(key_hash, None)
  let inputs = [
    Input {
      output_reference: OutputReference {
        transaction_id: TransactionId { hash: #"" },
        output_index: 0,
      },
      output: Output {
        address: addr,
        value: value.zero(),
        datum: InlineDatum(sample_datum),
        reference_script: None,
      },
    },
  ]
  let input =
    list.find(inputs, fn(input) { input.output.value == value.zero() })
  address.find_input_address(input) == addr
}

test single_cont_output() {
  let key_hash = #"010203040506"
  let sample_datum = SampleData { a: 1, b: #"01" }
  let addr = address.payment_address(key_hash, None)
  let outputs = [
    Output {
      address: addr,
      value: value.zero(),
      datum: InlineDatum(sample_datum),
      reference_script: None,
    },
  ]
  address.find_cont_payout(addr, outputs) == True
}

test single_exact_payout() {
  let key_hash = #"010203040506"
  let sample_datum = SampleData { a: 1, b: #"01" }
  let addr = address.payment_address(key_hash, None)
  let outputs = [
    Output {
      address: addr,
      value: value.zero(),
      datum: InlineDatum(sample_datum),
      reference_script: None,
    },
  ]
  address.find_exact_payout(addr, value.zero(), outputs) == True
}
