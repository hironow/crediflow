import NonFungibleToken from 0xf8d6e0586b0a20c7 // "./core/NonFungibleToken.cdc"
import Crediflow from 0x192440c99cb17282 // "../contracts/Crediflow.cdc"

transaction() {
    // single signer
    prepare(acct: AuthAccount) {
        // SETUP Crediflow NFT Collection
        if acct.borrow<&Crediflow.CreatorCollection>(from: Crediflow.CrediflowCreatorCollectionStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCreatorCollection(), to: Crediflow.CrediflowCreatorCollectionStoragePath)
            acct.link<&Crediflow.CreatorCollection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowCreatorCollectionPublicPath, target: Crediflow.CrediflowCreatorCollectionStoragePath)
        }
        if acct.borrow<&Crediflow.AdmirerCollection>(from: Crediflow.CrediflowAdmirerCollectionStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyAdmirerCollection(), to: Crediflow.CrediflowAdmirerCollectionStoragePath)
            acct.link<&Crediflow.AdmirerCollection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowAdmirerCollectionPublicPath, target: Crediflow.CrediflowAdmirerCollectionStoragePath)
        }

        // SETUP Crefiflow Container
        if acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCrediflowContainer(), to: Crediflow.CrediflowContainerStoragePath)
            acct.link<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath, target: Crediflow.CrediflowContainerStoragePath)
        }
    }

    execute {
        log("Finished setting up the account for Crediflow.")
    }
}
