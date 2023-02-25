import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import Crediflow from 0x0dbaa95c7691bc4f

transaction(contentId: UInt64, host: Address) {
    // REFS
    let Content: &Crediflow.CrediflowContent{Crediflow.CrediflowContentPublic}
    let CreatorCollection: &Crediflow.Collection

    let FlowTokenVault: &FlowToken.Vault

    // single signer
    prepare(acct: AuthAccount) {
        // check FT prepared for claim
        self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
                            ?? panic("Could not borrow the FlowToken.Vault from the signer.")

        // SETUP Crediflow NFT Collection for Creator
        if acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCollection(), to: Crediflow.CrediflowCollectionStoragePath)
            acct.link<&Crediflow.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowCollectionPublicPath, target: Crediflow.CrediflowCollectionStoragePath)
        }

        // Get Crediflow Content from the host
        let Container = getAccount(host).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
            ?? panic("Could not borrow the public CrediflowContainer from the host.")
        self.Content = Container.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist.")
        self.CreatorCollection = acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) ?? panic("Could not get the Collection from the signer.")
    }

    execute {
        let params: {String: AnyStruct} = {}

        // 事前に登録された人だけがmintできるようにしたい

        self.Content.mintCreator(recipient: self.CreatorCollection)
        log("Minted a new Crediflow Creator NFT for the signer.")
    }
}
