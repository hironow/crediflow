import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import Crediflow from 0xeb179c27144f783c

transaction(contentId: UInt64, host: Address) {
    // REFS
    let Content: &Crediflow.CrediflowContent{Crediflow.CrediflowContentPublic}
    let AdmirerCollection: &Crediflow.Collection

    // single signer
    prepare(acct: AuthAccount) {
        // SETUP Crediflow NFT Collection for Admirer
        if acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCollection(), to: Crediflow.CrediflowCollectionStoragePath)
            acct.link<&Crediflow.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowCollectionPublicPath, target: Crediflow.CrediflowCollectionStoragePath)
        }

        // Get Crediflow Content from the host
        let Container = getAccount(host).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
            ?? panic("Could not borrow the public CrediflowContainer from the host.")
        self.Content = Container.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist.")
        self.AdmirerCollection = acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) ?? panic("Could not get the Collection from the signer.")
    }

    execute {
        self.Content.mintAdmirer(recipient: self.AdmirerCollection)
        log("Minted a new Crediflow Admirer NFT for the signer.")
    }
}
