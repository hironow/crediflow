# Crediflow

This contract is for Crediflow, a decentralized platform on the Flow blockchain that enables creators and admirers to share and reward each other with end credits and tips.

ver. 0.0.1 (prototype):
[testnet live demo](https://crediflow.vercel.app/) | [youtube explain video](https://youtu.be/VDna5oDQX_8) | [presentation deck](./docs/slide.pdf) | [product detail](./docs/detail.md) | [product contract sequence](./docs/sequence.md)

ver. 0.0.0 (draft):
[product detail (ja)](./docs/ja/detail-ja.md) | [product contract sequence (ja)](./docs/ja/sequence-ja.md)

## Glossary

* `Crediflow` is a name that combines the words "Credit" and "Flow" to refer to a new system, inspired by the end credits found in movies and other media.
* A `Creator` is someone who creates content such as movies, anime, or games.
* An `Admirer` is a fan of movies, anime, games, and the like who wants to show appreciation or respect by tipping.
* `Pool` refers to Crediflow's liquidity pool.
* `Claim` is the process that allows a Creator to withdraw FT from the Pool.
* `Tip` is the process that allows an Admirer to deposit FT into the Pool as a form of admiration and respect towards the Creator.

This contract does not define anything like royalties. This is because if this contract considers itself content, it will benefit from its Crediflow.

## Contract

| Network         | Contract Address     |
| --------------- | -------------------- |
| Testnet         | [0x39c64d9429295c04](https://testnet.flowscan.org/contract/A.39c64d9429295c04.Crediflow/overview) |

## Methods

### Scripts

```txt
get-all-content
get-nft-holder
```

### Transactions

```txt
setup-account
create-content
be-creator
be-admirer
process-tip
process-claim
```

### Shortcut

```shell
export CREDIFLOW_HOST=0x497866d0e68bf2cf  # only testnet
export CREDIFLOW_CREATOR=<addr>
export CREDIFLOW_ADMIRER=<addr>
export CREDIFLOW_LILICO_TESTER=0x5995a3d05ce1be92  # only testnet

printenv | grep CREDIFLOW
```

```shell
# only emulator
flow transactions send cadence/transactions/core/mint-tokens.cdc $CREDIFLOW_ADMIRER 1000.0
```

```shell
# create crediflow
flow transactions send --signer hironow --network testnet cadence/transactions/create-content.cdc "Crediflow" "[$CREDIFLOW_CREATOR]" '["engineer"]'
# get content
flow scripts execute --network testnet cadence/scripts/get-all-content.cdc $CREDIFLOW_HOST
export CREDIFLOW_CONTENT_ID=<id>

# mint nft
flow transactions send --signer hironow-test-creator --network testnet cadence/transactions/be-creator.cdc $CREDIFLOW_CONTENT_ID $CREDIFLOW_HOST
flow transactions send --signer hironow-test-admirer --network testnet cadence/transactions/be-admirer.cdc $CREDIFLOW_CONTENT_ID $CREDIFLOW_HOST
# get nft
flow scripts execute --network testnet cadence/scripts/get-nft-holder.cdc $CREDIFLOW_CONTENT_ID $CREDIFLOW_HOST
export CREDIFLOW_CREATOR_NFT_ID=<id>
export CREDIFLOW_ADMIRER_NFT_ID=<id>

# tip by nft
flow transactions send --signer hironow-test-admirer --network testnet cadence/transactions/process-tip.cdc $CREDIFLOW_ADMIRER_NFT_ID 10.0
# claim by nft
flow transactions send --signer hironow-test-creator --network testnet cadence/transactions/process-claim.cdc $CREDIFLOW_CREATOR_NFT_ID

# another create crediflow
flow transactions send --signer hironow --network testnet cadence/transactions/create-content.cdc "Crediflow Tester" "[$CREDIFLOW_CREATOR, $CREDIFLOW_LILICO_TESTER]" '["engineer", "tester"]'
flow transactions send --signer hironow --network testnet cadence/transactions/create-content.cdc "Crediflow Updater" "[$CREDIFLOW_CREATOR, $CREDIFLOW_LILICO_TESTER]" '["updater", "tester"]'

# failed check
flow transactions send --signer hironow --network testnet cadence/transactions/close-pool.cdc $CREDIFLOW_CONTENT_ID
```
