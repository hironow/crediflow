import FlowToken from "../contracts/core/FlowToken.cdc"
import FungibleToken from "../contracts/core/FungibleToken.cdc"
import NonFungibleToken from "../contracts/core/NonFungibleToken.cdc"
import Crediflow from "../contracts/Crediflow.cdc"

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
