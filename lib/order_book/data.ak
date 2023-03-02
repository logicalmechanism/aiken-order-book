use aiken/transaction.{InlineDatum, Input, Output}

pub fn find_inbound_datum(possible_input: Option<Input>) -> Data {
  when possible_input is {
    Some(possible_input) ->
      when possible_input.output.datum is {
        InlineDatum(inbound_datum) -> inbound_datum
        _ -> error @"expected inbound inline datum"
      }
    None -> error @"no inbound datum found"
  }
}

pub fn find_outbound_datum(possible_output: Option<Output>) -> Data {
  when possible_output is {
    Some(possible_output) ->
      when possible_output.datum is {
        InlineDatum(outbound_datum) -> outbound_datum
        _ -> error @"expected outbound inline datum"
      }
    None -> error @"no outbound datum found"
  }
}
