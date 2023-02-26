import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Crediflow from 0x39c64d9429295c04

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
        // available only by account,
        // it's should be `error: cannot access `closePool`: function has account access`
        self.Content.closePool()
        log("Closed pool and refunded remaining balance to the admirer.")
    }
}
