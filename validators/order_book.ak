use aiken/transaction.{ScriptContext, Spend}
use order_book/datums.{Datum}
use order_book/redeemers.{
  FullBuy, FullSwap, PartBuy, PartSwap, Redeemer, Remove, Update,
}
use order_book/validators

validator order_book {
  fn(datum: Datum, redeemer: Redeemer, context: ScriptContext) -> Bool {
    when context.purpose is {
      Spend(output_reference) ->
        when redeemer is {
          FullSwap { full } ->
            validators.full_swap_validation(
              datum,
              context.transaction,
              full,
              output_reference,
            )
          PartSwap { part } ->
            validators.part_swap_validation(
              datum,
              context.transaction,
              part,
              output_reference,
            )
          Remove ->
            validators.remove_validation(
              datum,
              context.transaction,
              output_reference,
            )
          Update ->
            validators.update_validation(
              datum,
              context.transaction,
              output_reference,
            )
          FullBuy { owner } ->
            validators.full_buy_validation(
              datum,
              context.transaction,
              output_reference,
              owner,
            )
          PartBuy { owner, amount } ->
            validators.part_buy_validation(
              datum,
              context.transaction,
              output_reference,
              owner,
              amount,
            )
        }
      // anything other than spend fails
      _ -> False
    }
  }
}
