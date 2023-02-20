import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract interface Crediflow {
    /// events
    pub event ContractInitialized()
    pub event CreaterWorked()
    pub event CreaterMinted() // minted nft for the receiver
    pub event CreaterClaimed()
    pub event ReceiverMinted() // minted nft for the creator
    pub event ReceiverTipped()

    /// actors
    // create content
    pub resource interface Creator {
        pub var role: String

        pub fun worked() {

        }
    }

    // receive content
    pub resource interface Receiver {
        pub fun tipped() {

        }
    }


    /// nfts
    pub resource CreatorNFT: NonFungibleToken.INFT {
    }
    pub resource ReceiverNFT: NonFungibleToken.INFT {
    }


    /// admin
    // TODO:
}
