# Motivation and Solution

## Background

End credits, also known as end rolls (エンドロール) in Japan, were first introduced in American films in 1915 with the release of "The Birth of a Nation". While this film is regarded as a landmark in the history of cinema, it is also known for its controversial and racist content, and has faced bans in various countries. The purpose of end credits is to recognize the contributions of the people involved in the production of a work, such as the cast and crew, and also to establish trust and build relationships within the industry, which can lead to future work opportunities. However, there have been cases where fake end credits were created for various reasons, such as to enhance the entertainment value of a work or to evade legal responsibilities in the case of unauthorized filming. Despite these issues, we believe that if a person has contributed to a work, their contributions should be recognized in the end credits, regardless of whether they are listed by their real name or not.

We aim to establish a fair reward system, which enables direct payments to the cast and crew from their supporters, by building a blockchain-based solution for specific creators of specific roles for specific works. We will build this solution on the Flow blockchain.

## Why Blockchain?

* By utilizing blockchain, the information on end credits cannot be tampered with, which ensures the integrity of end credits. This is a crucial element in preventing fraudulent end credits in the entertainment industry, including films, anime, and games.
* Blockchain enables the information linked to end credits to be verified by anyone, which enhances fairness. This allows the entertainment industry to recognize the contributions of cast and crew in a fair and transparent manner.
* Additionally, by using DeFi use cases, we can apply liquidity provider and staking/claim concepts to the distribution logic of profits, which provides flexibility. This enables the entertainment industry to design reward distribution methods more flexibly.

## Why Flow?

* Flow uses a "wallet-less" approach, which means that users do not need to own a wallet, making it more accessible to a larger audience. This approach is believed to be beneficial in democratizing the entertainment industry.
* Flow makes it easy to register keys for an account, and can support hundreds to thousands of keys, which allows for scalability at the account level. This flexibility enables the account to be extended, set limited delegation, trust custodians to take over operational authority, and is useful when designing reward distribution methods for end credits.
* Additionally, Flow is a blockchain that is well-suited for managing entertainment assets using smart contracts, and can process transactions quickly and safely. This is important when implementing reward distribution methods for end credits.

## Specific Goals

In this proposal, we aim to build a contract interface that will be attached to the end credits on the Flow blockchain, and strive to achieve the minimum viable implementation that is feasible. We will also define the contract interface to be extensible in the future and create at least one end credit contract. For this proposal, we will be using Flow as an FT and will not be using our own FT or wrapped USDC and wrapped USDT on Flow.

## Specific Methods

1. Prepare the contract: Create a contract that stores contributor information required for the end credits and issues NFTs.
2. Contributor registration: Register creators in the contract and record information such as their roles and contributions.
3. NFT issuance: Creators can mint NFTs as creators and admirers can mint NFTs as admirers from the contract.
4. Tipping: Viewers can use the NFTs they own as admirers to pay for their Flow and specify which creators they would like to tip. Creators who receive rewards must hold NFTs as creators.
