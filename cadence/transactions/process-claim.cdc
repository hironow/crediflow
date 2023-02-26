import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Crediflow from 0x39c64d9429295c04

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
