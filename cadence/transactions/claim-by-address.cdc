import FlowToken from 0x0ae53cb6e3f42a79
import Crediflow from 0x192440c99cb17282 // "../contracts/Crediflow.cdc"

transaction() {

    // let FlowTokenVault: &FlowToken.Vault
    let creatorNFTRef: &Crediflow.CreatorNFT

    // single signer
    prepare(acct: AuthAccount) {
        // self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow the FlowToken.Vault from the signer.")

        self.creatorNFTRef = acct.borrow<&Crediflow.CreatorNFT>(from: /storage/crediflowCreatorNFT) ?? panic("Could not borrow the CreatorNFT from the signer.")

        // let capability = acct.link<&ExampleCrediflow.CreatorNFT>(/private/exampleCrediflowCreatorNFT, target: /storage/exampleCrediflowCreatorNFT)
        // let creatorNFTRef = capability!.borrow()

        // let creatorRes <- acct.load<@ExampleCrediflow.CreatorNFT>(from: /storage/exampleCrediflowCreatorNFT)
        // TODO: log(creatorNFTRef?.claim() ?? "No creator NFT found")
        // acct.save(<-creatorRes!, to: /storage/exampleCrediflowCreatorNFT)
    }

    pre {}

    execute {
        let params: {String: AnyStruct} = {}

        // claim by address list
    }

    post {}
}
