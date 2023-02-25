import FlowToken from 0x0ae53cb6e3f42a79 // "../contracts/core/FlowToken.cdc"
import FungibleToken from 0xee82856bf20e2aa6 // "./core/FungibleToken.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7 // "./core/NonFungibleToken.cdc"
import "Crediflow" // from "../contracts/Crediflow.cdc"

transaction(amount: UFix64, contentId: UInt64, host: Address) {

    let Content: &Crediflow.CrediflowContent{Crediflow.CrediflowContentPublic}
    let AdmirerCollection: &Crediflow.AdmirerCollection

    // The Vault resource that holds the tokens that are being tipped.
    let sentValut: &FungibleToken.Vault

    // single signer
    prepare(acct: AuthAccount) {
        // TODO: currentry limited only $FLOW
        let vaultRef = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
                            ?? panic("Could not borrow reference to the owner's Vault!")
        self.sentValut <- vaultRef.withdraw(amount: amount)

        // SETUP Crediflow NFT Collection for Admirer
        if acct.borrow<&Crediflow.AdmirerCollection>(from: Crediflow.CrediflowAdmirerCollectionStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyAdmirerCollection(), to: Crediflow.CrediflowAdmirerCollectionStoragePath)
            acct.link<&Crediflow.AdmirerCollection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowAdmirerCollectionPublicPath, target: Crediflow.CrediflowAdmirerCollectionStoragePath)
        }

        let Container = getAccount(host).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
            ?? panic("Could not borrow the public CrediflowContainer from the host.")
        self.Content = Container.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist.")
        self.AdmirerCollection = acct.borrow<&Crediflow.AdmirerCollection>(from: Crediflow.CrediflowAdmirerCollectionStoragePath) ?? panic("Could not get the AdmirerCollection from the signer.")
    }

    execute {
        let params: {String: AnyStruct} = {}

        // tipしないとmintできないようにしたい

        self.Content.mintAdmirer(recipient: self.AdmirerCollection)
        log("Minted a new Crediflow Admirer NFT for the signer.")
    }
}
