import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import Crediflow from 0x0dbaa95c7691bc4f

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
