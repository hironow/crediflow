import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import Crediflow from 0xeb179c27144f783c

transaction(nftId: UInt64, tipAmount: UFix64) {
    // REFS
    let CrediflowNFT: &Crediflow.NFT{Crediflow.Tipper} // as an admirer nft functionality

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
        self.CrediflowNFT.tip(token: <- self.FlowTokenVault.withdraw(amount: tipAmount))
        log("Tipped through Crediflow NFT!")
    }
}
