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
          // Swap two UTxOs
          FullSwap { full } ->
            validators.full_swap_validation(
              datum,
              context.transaction,
              full,
              output_reference,
            )
          // Swap UTxOs with a partial fill script return
          PartSwap { part } ->
            validators.part_swap_validation(
              datum,
              context.transaction,
              part,
              output_reference,
            )
          // Owner can remove their UTxO
          Remove ->
            validators.remove_validation(
              datum,
              context.transaction,
              output_reference,
            )
          // Owner can update their UTxO
          Update ->
            validators.update_validation(
              datum,
              context.transaction,
              output_reference,
            )
          // Buyer can purchase a UTxO
          FullBuy { owner } ->
            validators.full_buy_validation(
              datum,
              context.transaction,
              output_reference,
              owner,
            )
          // Buyer can purchase an amount from UTxO with a partial fill script return
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
