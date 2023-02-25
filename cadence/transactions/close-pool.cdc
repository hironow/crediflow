import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import Crediflow from 0xf669cb8d41ce0c74

transaction(
    contentId: UInt64,
) {
    // REFS
    let Content: &Crediflow.CrediflowContent{Crediflow.CrediflowContentPublic}

    // single signer
    prepare(acct: AuthAccount) {
        let Container = acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath)
            ?? panic("Could not borrow a reference to the Container")
        self.Content = Container.borrowPublicContentRef(contentId: contentId)
            ?? panic("Could not borrow a reference to the Content")
    }

    execute {
        // available only by account that created,
        // it's should be `error: cannot access `closePool`: function has account access`
        self.Content.closePool()
        log("Closed pool and refunded remaining balance to the admirer.")
    }
}
