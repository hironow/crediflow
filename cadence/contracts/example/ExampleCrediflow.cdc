import Crediflow from "../Crediflow.cdc"

// Example of implementation of the Crediflow interface.
pub contract ExampleCrediflow: Crediflow {

    pub var totalSupply: UFix64


    init() {
        self.totalSupply = 0.0
    }
}
