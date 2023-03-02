use order_book/datums.{Datum, OwnerInfo, SwapInfo, TokenInfo}

fn datum_a() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 10 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 10 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

fn datum_a_part() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 5 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 5 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

fn datum_b() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"0102", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 10 }
  let want: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 10 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

fn datum_b_part() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"0102", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 5 }
  let want: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 5 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

fn datum_c() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 1234 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 732 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

fn datum_c_part() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 813 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 482 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_d() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 200 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 100 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_d_cont() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 100 }
  let want: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 50 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

pub fn datum_e() -> Datum {
  let owner: OwnerInfo = OwnerInfo { pkh: #"0102", sc: #"" }
  let have: TokenInfo = TokenInfo { pid: #"acab", tkn: #"beef", amt: 50 }
  let want: TokenInfo = TokenInfo { pid: #"", tkn: #"", amt: 100 }
  let info: SwapInfo = SwapInfo { slip: 40 }
  Datum { owner, have, want, info }
}

test same_owner() {
  datums.constant_ownership(datum_a(), datum_a()) == True
}

test different_owner() {
  datums.constant_ownership(datum_a(), datum_b()) == False
}

test good_full_swap() {
  datums.full_swap_datum_check(datum_a(), datum_b()) == True
}

test bad_full_swap() {
  datums.full_swap_datum_check(datum_a(), datum_a()) == False
}

test bad_part_swap() {
  datums.part_swap_datum_check(datum_a(), datum_b()) == False
}

test good_part_swap() {
  datums.part_swap_datum_check(datum_a(), datum_b_part()) == True
}

test first_datum_not_cont() {
  datums.check_if_cont(datum_a(), datum_b_part()) == False
}

test first_datum_cont() {
  datums.check_if_cont(datum_b_part(), datum_a()) == True
}

test no_datum_cont() {
  datums.check_if_cont(datum_b(), datum_a()) == False && datums.check_if_cont(
    datum_a(),
    datum_b(),
  ) == False
}

test good_simple_part_buy_datum() {
  datums.part_buy_datum_check(datum_a(), datum_a_part(), 5) == True
}

test good_complex_part_buy_datum() {
  datums.part_buy_datum_check(datum_c(), datum_c_part(), 421) == True
}

test good_constant_token_info() {
  datums.constant_have_want_info(datum_a(), datum_a_part()) == True
}

test bad_constant_token_info() {
  datums.constant_have_want_info(datum_b(), datum_a_part()) == False
}

test price_check() {
  datums.token_price(datum_c(), 250) == 421
}

test low_price_check() {
  datums.token_price(datum_c(), 25) == 42
}

test complex_cont_part_swap() {
  datums.part_swap_cont_check(datum_d(), datum_d_cont(), datum_e()) == True
}
