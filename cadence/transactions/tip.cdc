import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import Crediflow from 0x0dbaa95c7691bc4f

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
