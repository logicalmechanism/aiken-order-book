use order_book/datums.{PublicKeyHash}

pub type UTxO {
  tx: ByteArray,
  idx: Int,
}

pub type BuyerInfo {
  pkh: PublicKeyHash,
  sc: PublicKeyHash,
}

pub type BuyAmount {
  amt: Int,
}

pub type Remove =
  Void

pub type Update =
  Void

pub type Redeemer {
  FullSwap { full: UTxO }
  PartSwap { part: UTxO }
  Update
  Remove
  FullBuy { owner: BuyerInfo }
  PartBuy { owner: BuyerInfo, amount: BuyAmount }
}
