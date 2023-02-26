import Crediflow from 0x39c64d9429295c04

pub fun main(account: Address): {UFix64: CrediflowContentMetadata} {
    let crediflowContainer = getAccount(account).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
        ?? panic("Could not borrow the Crediflow Container from the account.")
    let crediflowContents: [UInt64] = crediflowContainer.getIDs()
    let returnVal: {UFix64: CrediflowContentMetadata} = {}

    for contentId in crediflowContents {
        let content = crediflowContainer.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist in the account.")

        let metadata = CrediflowContentMetadata(
            _id: content.contentId,
            _name: content.contentName,
            _host: content.contentHost,
            _creators: content.getCreators()
        )
        returnVal[content.dateCreated] = metadata
    }
    return returnVal
}

pub struct CrediflowContentMetadata {
    pub let id: UInt64
    pub let name: String
    pub let host: Address
    pub let creators: {Address: {String: AnyStruct}}

    init(_id: UInt64, _name: String, _host: Address, _creators: {Address: {String: AnyStruct}}) {
        self.id = _id
        self.name = _name
        self.host = _host
        self.creators = _creators
    }
}
