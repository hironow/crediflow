import ExampleCrediflow from "../contracts/ExampleCrediflow.cdc"

transaction(amount: UFix64) {
    // TODO: 勝手にはなれない
    prepare(acct: AuthAccount) {
    }

    pre {}

    execute {
        let params: {String: AnyStruct} = {}

        // mint nft
    }

    post {}
}
