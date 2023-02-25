import Crediflow from 0xf669cb8d41ce0c74

pub fun main(account: Address): {UFix64: CrediflowContentMetadata} {
    let crediflowContainer = getAccount(account).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
        ?? panic("Could not borrow the Crediflow Container from the account.")
    let crediflowContents: [UInt64] = crediflowContainer.getIDs()
    let returnVal: {UFix64: CrediflowContentMetadata} = {}

    for contentId in crediflowContents {
        let content = crediflowContainer.borrowPublicContentRef(contentId: contentId) ?? panic("This event does not exist in the account.")

        let metadata = CrediflowContentMetadata(
            _id: content.contentId,
            _name: content.contentName,
            _host: content.contentHost,
        )
        returnVal[content.dateCreated] = metadata
    }
    return returnVal
}

pub struct CrediflowContentMetadata {
    pub let id: UInt64
    pub let name: String
    pub let host: Address

    init(_id: UInt64, _name: String, _host: Address) {
        self.id = _id
        self.name = _name
        self.host = _host
    }
}