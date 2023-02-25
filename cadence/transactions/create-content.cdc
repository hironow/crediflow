import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import Crediflow from 0xf1365e67d4ab9a42

transaction(
    name: String,
    creatorAddressList: [Address],
    creatorRoleList: [String],
    creatorMetadataKeysList: [[String]],
    creatorMetadataValuesList: [[AnyStruct]],
) {
    // REFS
    let Container: &Crediflow.CrediflowContainer

    // single signer
    prepare(acct: AuthAccount) {
        assert(creatorAddressList.length == creatorRoleList.length, message: "The length of the creator address list and the creator role list must be the same.")
        assert(creatorRoleList.length == creatorMetadataKeysList.length, message: "The length of the creator role list and the creator metadata key list must be the same.")
        assert(creatorMetadataKeysList.length == creatorMetadataValuesList.length, message: "The length of the creator metadata key list and the creator metadata value list must be the same.")

        // SETUP Crefiflow Container
        if acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCrediflowContainer(), to: Crediflow.CrediflowContainerStoragePath)
            acct.link<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath, target: Crediflow.CrediflowContainerStoragePath)
        }

        self.Container = acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath)
            ?? panic("Could not borrow the Crediflow Container from signer.")
    }

    execute {
        // metadata props
        let metadataList: [{String: AnyStruct}] = []
        for i, metadataKeys in creatorMetadataKeysList {
            var metadataMap: {String: AnyStruct} = {}
            for j, metadataKey in metadataKeys {
                metadataMap[metadataKey] = creatorMetadataValuesList[i][j]
            }
            metadataList.append(metadataMap)
        }
        // creator props
        let creatorMap: {Address: Crediflow.RoleIdentifier} = {}
        for idx, creatorAddress in creatorAddressList {
            creatorMap[creatorAddress] = Crediflow.RoleIdentifier(_address: creatorAddress, _role: creatorRoleList[idx], metadata: metadataList[idx])
        }

        self.Container.createContent(name: name, creatorMap: creatorMap)
        log("Created a new content for claim and tip.")
    }
}
