import NonFungibleToken from "./core/NonFungibleToken.cdc"
import FungibleToken from "./core/FungibleToken.cdc"
// import MetadataViews from "./coreMetadataViews.cdc"

// The interface that Crediflow contract implement.
pub contract interface Crediflow {
    /// Paths
    pub let CrediflowStoragePath: StoragePath

    /// State
    pub var totalSupply: UFix64

    /// Events
    pub event ContractInitialized()
    // exclusive
    pub event CreaterWorked()
    pub event CreaterMinted() // minted nft for the consumer
    pub event CreaterClaimed(amount: UFix64)
    pub event ConsumerMinted() // minted nft for the creator
    pub event ConsumerTipped(amount: UFix64)

    /// Actors
    // create content
    pub resource interface Creator {
        pub var role: String

        access(account) fun worked() {
        }

        pub fun claim(amount: UFix64): @FungibleToken.Vault {
            post {
                // `result` refers to the return value
                result.balance == amount:
                    "Withdrawal amount must be the same as the balance of the withdrawn Vault"
            }
        }
    }
    // receive content
    pub resource interface Consumer {
        pub fun tip(amount: UFix64)
    }

    // トークンを貯める機構 (LP的)

    /// The resource that contains the functions to send and receive tokens.
    /// The declaration of a concrete type in a contract interface means that
    /// every Fungible Token contract that implements the FungibleToken interface
    /// must define a concrete `Vault` resource that conforms to the `Provider`, `Receiver`,
    /// and `Balance` interfaces, and declares their required fields and functions
    ///
    pub resource Pool: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {
        /// The total balance of the vault
        pub var balance: UFix64

        // The conforming type must declare an initializer
        // that allows providing the initial balance of the Vault
        //
        init(balance: UFix64)

        /// Subtracts `amount` from the Vault's balance
        /// and returns a new Vault with the subtracted balance
        ///
        /// @param amount: The amount of tokens to be withdrawn from the vault
        /// @return The Vault resource containing the withdrawn funds
        ///
        pub fun withdraw(amount: UFix64): @Pool {
            pre {
                self.balance >= amount:
                    "Amount withdrawn must be less than or equal than the balance of the Vault"
            }
            post {
                // use the special function `before` to get the value of the `balance` field
                // at the beginning of the function execution
                //
                self.balance == before(self.balance) - amount:
                    "New Vault balance must be the difference of the previous balance and the withdrawn Vault"
            }
        }

        /// Takes a Vault and deposits it into the implementing resource type
        ///
        /// @param from: The Vault resource containing the funds that will be deposited
        ///
        pub fun deposit(from: @Pool) {
            // Assert that the concrete type of the deposited vault is the same
            // as the vault that is accepting the deposit
            pre {
                from.isInstance(self.getType()):
                    "Cannot deposit an incompatible token type"
            }
            post {
                self.balance == before(self.balance) + before(from.balance):
                    "New Vault balance must be the sum of the previous balance and the deposited Vault"
            }
        }
    }

    // 発行される2種の証 (NFT的)

    /// NFTs
    // Represents a creator's NFT
    pub resource CreatorNFT: NonFungibleToken.INFT {
        // The `uuid` of this resource
        pub let id: UInt64

        // init() {
        //     self.id = self.uuid

        //     CreatorNFT.totalSupply = CreatorNFT.totalSupply + 1
        // }
    }
    // Represents a consumer's NFT
    pub resource ConsumerNFT: NonFungibleToken.INFT {
        // The `uuid` of this resource
        pub let id: UInt64

        // init() {
        //     self.id = self.uuid

        //     ConsumerNFT.totalSupply = ConsumerNFT.totalSupply + 1
        // }
    }
}
