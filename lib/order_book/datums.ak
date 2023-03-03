use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value.{Value}
use order_book/math

pub type PublicKeyHash =
  Hash<Blake2b_224, VerificationKey>

pub type OwnerInfo {
  pkh: PublicKeyHash,
  sc: PublicKeyHash,
}

pub type TokenInfo {
  pid: ByteArray,
  tkn: ByteArray,
  amt: Int,
}

pub type SwapInfo {
  slip: Int,
}

pub type Datum {
  owner: OwnerInfo,
  have: TokenInfo,
  want: TokenInfo,
  info: SwapInfo,
}

pub fn constant_ownership(inbound_datum: Datum, outbound_datum: Datum) -> Bool {
  inbound_datum.owner == outbound_datum.owner
}

pub fn full_swap_datum_check(
  inbound_datum: Datum,
  outbound_datum: Datum,
) -> Bool {
  list.and(
    [
      (inbound_datum.owner.pkh != outbound_datum.owner.pkh)?,
      (inbound_datum.have.pid == outbound_datum.want.pid)?,
      (inbound_datum.have.tkn == outbound_datum.want.tkn)?,
      math.is_int_in_range(
        inbound_datum.have.amt,
        inbound_datum.info.slip,
        outbound_datum.want.amt,
      )?,
    ],
  )
}

pub fn part_swap_datum_check(
  inbound_datum: Datum,
  outbound_datum: Datum,
) -> Bool {
  list.and(
    [
      inbound_datum.owner.pkh != outbound_datum.owner.pkh,
      inbound_datum.have.pid == outbound_datum.want.pid,
      inbound_datum.have.tkn == outbound_datum.want.tkn,
      !math.is_int_in_range(
        inbound_datum.have.amt,
        inbound_datum.info.slip,
        outbound_datum.want.amt,
      ),
      is_in_effective_range(inbound_datum, outbound_datum),
    ],
  )
}

pub fn part_swap_cont_check(
  inbound_datum: Datum,
  outbound_datum: Datum,
  that_datum: Datum,
) {
  let have_diff = inbound_datum.have.amt - that_datum.want.amt
  let want_amt = have_diff * inbound_datum.want.amt / inbound_datum.have.amt
  list.and(
    [
      (have_diff == outbound_datum.have.amt)?,
      (want_amt == outbound_datum.want.amt)?,
      (inbound_datum.info.slip == outbound_datum.info.slip)?,
    ],
  )
}

pub fn part_buy_datum_check(
  inbound_datum: Datum,
  outbound_datum: Datum,
  pay_amt: Int,
) -> Bool {
  let have_diff = inbound_datum.have.amt - pay_amt
  let want_amt = have_diff * inbound_datum.want.amt / inbound_datum.have.amt
  list.and(
    [
      constant_ownership(inbound_datum, outbound_datum),
      constant_have_want_info(inbound_datum, outbound_datum),
      have_diff == outbound_datum.have.amt,
      want_amt == outbound_datum.want.amt,
    ],
  )
}

pub fn constant_have_want_info(
  inbound_datum: Datum,
  outbound_datum: Datum,
) -> Bool {
  list.and(
    [
      inbound_datum.have.pid == outbound_datum.have.pid,
      inbound_datum.have.tkn == outbound_datum.have.tkn,
      inbound_datum.want.pid == outbound_datum.want.pid,
      inbound_datum.want.tkn == outbound_datum.want.tkn,
    ],
  )
}

fn is_in_effective_range(part_a: Datum, part_b: Datum) -> Bool {
  let a_price = math.effective_price(part_a.have.amt, part_a.want.amt)
  let b_price = math.effective_price(part_b.want.amt, part_b.have.amt)
  math.is_int_in_range(a_price, part_a.info.slip, b_price)
}

pub fn check_if_cont(part_a: Datum, part_b: Datum) -> Bool {
  let left_side = part_a.have.amt < part_b.want.amt == True
  let right_side = part_a.want.amt < part_b.have.amt == True
  if left_side != right_side {
    error @"Bad Trade"
  } else {
    left_side && right_side
  }
}

pub fn token_price(part_a: Datum, want_amt: Int) -> Int {
  part_a.have.amt * want_amt / part_a.want.amt
}

pub fn token_to_value(token: TokenInfo) -> Value {
  value.from_asset(token.pid, token.tkn, token.amt)
}
