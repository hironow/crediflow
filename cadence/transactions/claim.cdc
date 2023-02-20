import FlowToken from "../contracts/FlowToken.cdc"
import ExampleCrediflow from "../contracts/ExampleCrediflow.cdc"

transaction() {

    let FlowTokenVault: &FlowToken.Vault

    prepare(acct: AuthAccount) {
        self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow the FlowToken.Vault from the signer.")
    }

    pre {}

    execute {
        let params: {String: AnyStruct} = {}

        // claim
    }

    post {}
}
