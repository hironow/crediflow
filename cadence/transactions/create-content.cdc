import NonFungibleToken from 0xf8d6e0586b0a20c7 // "./core/NonFungibleToken.cdc"
import Crediflow from 0x192440c99cb17282 // "../contracts/Crediflow.cdc"

transaction(
    name: String,
) {
    // REFS
    let Container: &Crediflow.CrediflowContainer

    // single signer
    prepare(acct: AuthAccount) {
        // SETUP Crefiflow Container
        if acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCrediflowContainer(), to: Crediflow.CrediflowContainerStoragePath)
            acct.link<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath, target: Crediflow.CrediflowContainerStoragePath)
        }

        self.Container = acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath)
            ?? panic("Could not borrow the Crediflow Container from signer.")
    }

    execute {
        let extraMetadata: {String: AnyStruct} = {}

        self.Container.createContent(name: name)

        log("Created a new content for claim and tip.")
    }
}
