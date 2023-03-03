# aiken-order-book

A contract for an order book marketplace built with Aiken.

## Order Creation

Each order has a datum of the form below, providing the wallet info, the have token, the want token, and the swap info.

```rust
pub type Datum {
  owner: OwnerInfo,
  have: TokenInfo,
  want: TokenInfo,
  info: SwapInfo,
}
```

Upon order creation, the OwnerInfo will be populated with your primary public key hash and staking credential. This information controls who will get the payment and who has the right to cancel and update the order. A UTxO will always remain in the original owners control until the UTxO has been fully swapped or removed from the contract.

The have and want token information is simply the policy id, token name, and the amount of that token required for a swap.

```rust
pub type TokenInfo {
  pid: ByteArray,
  tkn: ByteArray,
  amt: Int,
}
```

For example, the TokenInfo for 1000 ADA would be ```TokenInfo(#"", #"", 1000000000)```. The contract is designed for arbitrary pairs based off the have and want TokenInfo. The have is what you have on the UTxO to swap for the want defined in the datum.

Lastly, each order has a slippage associated with it. This is the amount of deviation allowed from the have and want for a swap to occur. Essentially, a swap will occur if another order is found within the slippage range.

Creating an order is as simple as selecting how much of a token you have and selecting how much of a token you want then selecting an appropriate slippage range. Orders inside the contract will be autocompleted with the order book batcher bot.

## Order Cancellation

The contract is designed to preserve ownership until the UTxO is completely swapped. At any time, the owner of the UTxO is allowed to cancel their order by removing it from the contract and placing into their wallet. It is impossible for any third party to maliciously withdraw another users funds. Bulk removal is possible for a set of owned UTxOs via tx chaining.

## Order Updating

An order may be updated at any time while in the contract. This is useful for slippage adjustments, price changes, and increases or decreasing the amount of the token the user may wish to swap. This endpoint also allows a trading pair to be changed, allowing some partial swaps to occur on pair A then the UTxO may be updated to allow partial swaps on pair B.

## Order Matching

Anyone is allowed to match orders within the contract if and only if the two UTxOs in the swap satisfy the validation parameters for either a full swap or a partial swap. A full swap is a complete swap where another UTxO is found to be within the slippage range, resulting in both UTxOs leaving the contract to their new owners. A partial swap is a swap where one UTxO has some of the token but not the full amount, resulting in one of the UTxOs returning to the contract in an attempt to be swapped again. The contract also allows market rate purchases with the full buy and partial buy end points. A wallet that is outside the contract can purchase the total or partial amount from a UTxO inside the contract. The price they pay is not determined by the slippage rate but at the price defined by the have and want token information.

## Order Book Bot

- TODO

## Build Instructions

To run the contract tests.

```
aiken check
```

To build the contract.

```
aiken build
```

## Test Scripts

- TODO