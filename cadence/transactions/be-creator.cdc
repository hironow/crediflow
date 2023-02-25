import FlowToken from 0x0ae53cb6e3f42a79 // "./contracts/core/FlowToken.cdc"
import FungibleToken from 0xee82856bf20e2aa6 // "./contracts/core/FungibleToken.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7 // "./contracts/core/NonFungibleToken.cdc"
import Crediflow from 0x1beecc6fef95b62e // "../contracts/Crediflow.cdc"

transaction(contentId: UInt64, host: Address) {
    // REFS
    let Content: &Crediflow.CrediflowContent{Crediflow.CrediflowContentPublic}
    let CreatorCollection: &Crediflow.CreatorCollection

    let FlowTokenVault: &FlowToken.Vault

    // single signer
    prepare(acct: AuthAccount) {
        // SETUP Crediflow NFT Collection for Creator
        if acct.borrow<&Crediflow.CreatorCollection>(from: Crediflow.CrediflowCreatorCollectionStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCreatorCollection(), to: Crediflow.CrediflowCreatorCollectionStoragePath)
            acct.link<&Crediflow.CreatorCollection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowCreatorCollectionPublicPath, target: Crediflow.CrediflowCreatorCollectionStoragePath)
        }

        // Get Crediflow Content from the host
        let Container = getAccount(host).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
            ?? panic("Could not borrow the public CrediflowContainer from the host.")
        self.Content = Container.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist.")
        self.CreatorCollection = acct.borrow<&Crediflow.CreatorCollection>(from: Crediflow.CrediflowCreatorCollectionStoragePath) ?? panic("Could not get the CreatorCollection from the signer.")

        // check FT prepared for claim
        self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
                            ?? panic("Could not borrow the FlowToken.Vault from the signer.")
    }

    execute {
        let params: {String: AnyStruct} = {}

        // 事前に登録された人だけがmintできるようにしたい

        self.Content.mintCreator(recipient: self.CreatorCollection)
        log("Minted a new Crediflow Creator NFT for the signer.")
    }
}
