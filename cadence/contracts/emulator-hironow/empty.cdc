// This is a simple contract that contains a single field and a single function.
// It is used to demonstrate `flow dev` deploy a contract to the emulator with account.
pub contract Empty {
    pub let value: String

    // The init() function is required if the contract contains any fields.
    init() {
        self.value = "Hello, World!"
    }

    // Public function that returns our friendly greeting!
    pub fun get(): String {
        return self.value
    }
}
