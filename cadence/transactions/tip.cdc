import FlowToken from 0x0ae53cb6e3f42a79
import Crediflow from 0x192440c99cb17282 // "../contracts/Crediflow.cdc"

transaction(amount: UFix64) {

    let FlowTokenVault: &FlowToken.Vault

    prepare(acct: AuthAccount) {
        self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault) ?? panic("Could not borrow the FlowToken.Vault from the signer.")
    }

    pre {}

    execute {
        let params: {String: AnyStruct} = {}

        // tip
    }

    post {}
}
