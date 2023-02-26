import FlowToken from 0x7e60df042a9c0868
import FungibleToken from 0x9a0766d93b6608b7
import NonFungibleToken from 0x631e88ae7f1d7c20
import Crediflow from 0x39c64d9429295c04

transaction(
    name: String,
    creatorAddressList: [Address],
    creatorRoleList: [String],
) {
    // REFS
    let Container: &Crediflow.CrediflowContainer

    // single signer
    prepare(acct: AuthAccount) {
        assert(creatorAddressList.length == creatorRoleList.length, message: "The length of the creator address list and the creator role list must be the same.")

        // SETUP Crediflow Container
        if acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath) == nil {
            acct.save(<-Crediflow.createEmptyCrediflowContainer(), to: Crediflow.CrediflowContainerStoragePath)
            acct.link<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath, target: Crediflow.CrediflowContainerStoragePath)
        }

        self.Container = acct.borrow<&Crediflow.CrediflowContainer>(from: Crediflow.CrediflowContainerStoragePath)
            ?? panic("Could not borrow the Crediflow Container from signer.")
    }

    execute {
        // TODO: metadata props
        // let metadataList: [{String: AnyStruct}] = []
        // for i, metadataKeys in creatorMetadataKeysList {
        //     var metadataMap: {String: AnyStruct} = {}
        //     for j, metadataKey in metadataKeys {
        //         metadataMap[metadataKey] = creatorMetadataValuesList[i][j]
        //     }
        //     metadataList.append(metadataMap)
        // }
        // creator props
        let creatorMap: {Address: Crediflow.RoleIdentifier} = {}
        for idx, creatorAddress in creatorAddressList {
            creatorMap[creatorAddress] = Crediflow.RoleIdentifier(_address: creatorAddress, _role: creatorRoleList[idx], metadata: {})
        }

        self.Container.createContent(name: name, creatorMap: creatorMap)
        log("Created a new content for claim and tip.")
    }
}
