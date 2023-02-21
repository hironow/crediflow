import FlowToken from 0x0ae53cb6e3f42a79
import NonFungibleToken from "./core/NonFungibleToken.cdc"
import FungibleToken from "./core/FungibleToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"

// The interface that Crediflow contract implement.
pub contract interface Crediflow {
    pub resource interface Counter {
        pub var total: UFix64
    }

    pub resource interface Claimer {
        pub fun claim(): @FlowToken.Vault {
            post {
                result.balance > 0.0: "Claim amount must be greater than 0.0"
            }
        }
    }

    pub resource interface Tipper {
        pub fun tip(token: @FlowToken.Vault) {
            pre {
                token.balance > 0.0: "Tip amount must be greater than 0.0"
            }
        }
    }
}
