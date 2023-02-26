import FlowToken from "../contracts/core/FlowToken.cdc"
import FungibleToken from "../contracts/core/FungibleToken.cdc"
import NonFungibleToken from "../contracts/core/NonFungibleToken.cdc"
import Crediflow from "../contracts/Crediflow.cdc"

transaction(nftId: UInt64) {
    // REFS
    let CrediflowNFT: &Crediflow.NFT{Crediflow.Claimer} // as a creator nft functionality

    let FlowTokenVault: &FlowToken.Vault

    // single signer
    prepare(acct: AuthAccount) {
        // check FT prepared for tip
        self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
                            ?? panic("Could not borrow the FlowToken.Vault from the signer.")
        // use own Crediflow NFT
        let CrediflowCollection = acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath)
                            ?? panic("Could not borrow the Crediflow Collection from the signer.")
        self.CrediflowNFT = CrediflowCollection.borrowCrediflowNFT(id: nftId) ?? panic("Could not borrow the Crediflow NFT from the signer.")
    }

    execute {
        self.FlowTokenVault.deposit(from: <- self.CrediflowNFT.claim())
        log("Claimed through Crediflow NFT!")
    }
}
