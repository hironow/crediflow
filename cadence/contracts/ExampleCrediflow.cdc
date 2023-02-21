import FungibleToken from "./FungibleToken.cdc"
import Crediflow from "./Crediflow.cdc"

// Example of implementation of the Crediflow interface.
pub contract ExampleCrediflow: Crediflow {

    pub resource CreatorNFT {
    }

    pub resource AdmirerNFT {
    }

    pub resource CreatorNFTVault {
        pub var total: UFix64

        init() {
            self.total = 0.0
        }

        pub fun claim(): @FungibleToken.Vault {
            // NOTE: 1.0 is adhoc value for testing
            let amount = 1.0
            // TODO: account resource から取り出す
            self.total = self.total + amount
            return <-create FungibleToken.Vault(balance: amount)
        }
    }

    pub resource AdmirerNFTVault {
        pub var total: UFix64

        init() {
            self.total = 0.0
        }

        pub fun tip(token: @FungibleToken.Vault) {
            // TODO: account resource に入れる
            self.total = self.total + token.balance
            destroy token
        }
    }

    pub resource Administrator {

    }

    init(){
        // Initialize the contract

        // Save the NFTs to the account storage
        let newCreatorNFT <- create CreatorNFT()
        self.account.save(<-newCreatorNFT, to: /storage/exampleCrediflowCreatorNFT)

        let newCustomerNFT <- create AdmirerNFT()
        self.account.save(<-newCustomerNFT, to: /storage/exampleCrediflowAdmirerNFT)
    }
}
