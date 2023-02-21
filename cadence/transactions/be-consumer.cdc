import ExampleCrediflow from "../contracts/ExampleCrediflow.cdc"

transaction(amount: UFix64) {
    prepare(acct: AuthAccount) {
    }

    pre {}

    execute {
        let params: {String: AnyStruct} = {}

        // tip
    }

    post {}
}
