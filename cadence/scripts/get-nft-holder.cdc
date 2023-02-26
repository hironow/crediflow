import Crediflow from 0x39c64d9429295c04

pub fun main(contentId: UInt64, host: Address): CrediflowContentNFTHolderMetadata {
    let crediflowContainer = getAccount(host).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
        ?? panic("Could not borrow the Crediflow Container from the account.")
    let crediflowContents: [UInt64] = crediflowContainer.getIDs()

    let content = crediflowContainer.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist in the account.")

    return CrediflowContentNFTHolderMetadata(
        _id: content.contentId,
        _name: content.contentName,
        _host: content.contentHost,
        _creatorHolders: content.getCreatorHolders(),
        _admirerHolders: content.getAdmirerHolders()
    )
}

pub struct CrediflowContentNFTHolderMetadata {
    pub let id: UInt64
    pub let name: String
    pub let host: Address
    pub let creatorHolders: {Address: {String: AnyStruct}}
    pub let admirerHolders: {Address: {String: AnyStruct}}

    init(_id: UInt64, _name: String, _host: Address, _creatorHolders: {Address: {String: AnyStruct}}, _admirerHolders: {Address: {String: AnyStruct}}) {
        self.id = _id
        self.name = _name
        self.host = _host
        self.creatorHolders = _creatorHolders
        self.admirerHolders = _admirerHolders
    }
}
