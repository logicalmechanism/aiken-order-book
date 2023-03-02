pub fn percentage(amt: Int, pct: Int) -> Int {
  if pct <= 0 {
    0
  } else {
    amt / pct
  }
}

pub fn is_int_in_range(value: Int, slippage: Int, target: Int) -> Bool {
  let low_end = value - percentage(value, slippage)
  let high_end = value + percentage(value, slippage)
  low_end <= target && target <= high_end
}

pub fn effective_price(have_amt: Int, want_amt: Int) -> Int {
  if want_amt == 0 {
    0
  } else {
    have_amt * 1000000 / want_amt
  }
}
