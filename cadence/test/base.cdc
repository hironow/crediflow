import Test

pub var blockchain = Test.newEmulatorBlockchain()
pub var accounts: [Test.Account] = []

pub fun setup() {
    // Create accounts in the blockchain.
    let acct1 = blockchain.createAccount()
    accounts.append(acct1)
    let acct2 = blockchain.createAccount()
    accounts.append(acct2)

    // Set the configuration with the addresses.
    // They keys of the mapping should be the placeholders used in the imports.
    // blockchain.useConfiguration(Test.Configuration({
    //     "FooContract": acct1.address,
    //     "BarContract": acct2.address
    // }))
}

pub fun testScript() {
    var result = blockchain.executeScript("pub fun main(a: Int, b: Int): Int {  return a + b }", [2, 3])
    // then
    assert(result.status == Test.ResultStatus.succeeded)
    assert((result.returnValue! as! Int) == 5)
}

pub fun testTransaction() {
    let tx = Test.Transaction(
        code: "transaction(a: Int, b: Int) { execute{ assert(a == b) } }",
        authorizers: [],
        signers: [accounts[0]],
        arguments: [4, 4],
    )
    let result = blockchain.executeTransaction(tx)
    // then
    assert(result.status == Test.ResultStatus.succeeded)
}

pub fun testTransactionAuth() {
    let tx = Test.Transaction(
        code: "transaction() { prepare(acct1: AuthAccount, acct2: AuthAccount) {}  }",
        authorizers: [accounts[0].address, accounts[1].address],
        signers: [accounts[0], accounts[1]],
        arguments: [],
    )
    let result = blockchain.executeTransaction(tx)
    // then
    assert(result.status == Test.ResultStatus.succeeded)
}

pub fun testDeployContract() {
    let contractCode = "pub contract Foo{ pub let msg: String;   init(_ msg: String){ self.msg = msg }   pub fun sayHello(): String { return self.msg } }"
    let err = blockchain.deployContract(
        name: "Foo",
        code: contractCode,
        account: accounts[0],
        arguments: ["hello from args"],
    )
    if err != nil {
        panic(err!.message)
    }
    // when
    var script = "import Foo from ".concat(accounts[0].address.toString()).concat("\n")
    script = script.concat("pub fun main(): String {  return Foo.sayHello() }")
    let result = blockchain.executeScript(script, [])
    // then
    if result.status != Test.ResultStatus.succeeded {
        panic(result.error!.message)
    }
    let returnedStr = result.returnValue! as! String
    assert(returnedStr == "hello from args", message: "found: ".concat(returnedStr))
}

pub fun tearDown() {
}
