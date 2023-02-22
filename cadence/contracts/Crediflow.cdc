import FungibleToken from "./core/FungibleToken.cdc"
import NonFungibleToken from "./core/NonFungibleToken.cdc"
import FungibleToken from "./core/FungibleToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"

pub contract Crediflow {
    // PATHS
    pub let CrediflowCreatorCollectionStoragePath: StoragePath
    pub let CrediflowCreatorCollectionPublicPath: PublicPath

    pub let CrediflowAdmirerCollectionStoragePath: StoragePath
    pub let CrediflowAdmirerCollectionPublicPath: PublicPath

    pub let CrediflowContainerStoragePath: StoragePath
    pub let CrediflowContainerPublicPath: PublicPath
    pub let CrediflowContainerPrivatePath: PrivatePath

    // EVENTS
    pub event ContractInitialized()

    // STATE
    pub var totalCreatorSupply: UInt64
    pub var totalAdmirerSupply: UInt64
    pub var totalCrediflowContainer: UInt64

    // STRUCT
    pub struct TokenIdentifier {
        pub let id: UInt64
        pub let address: Address
        pub let serial: UInt64

        init(_id: UInt64, _address: Address, _serial: UInt64) {
            self.id = _id
            self.address = _address
            self.serial = _serial
        }
    }

    pub resource interface Claimer {
        pub fun claim(): @FungibleToken.Vault {
            post {
                result.balance > 0.0: "Claim amount must be greater than 0.0"
            }
        }
    }

    pub resource interface Tipper {
        pub fun tip(token: @FungibleToken.Vault) {
            pre {
                token.balance > 0.0: "Tip amount must be greater than 0.0"
            }
        }
    }

    // A Creator as an NFT
    // Represents a NFT has a claimable Crediflow.
    // TODO: MetadataViews.Resolver
    pub resource CreatorNFT: NonFungibleToken.INFT, Claimer {
        pub let id: UInt64

        // special
        pub let contentHost: Address
        pub let contentId: UInt64
        // claim by this Capabilty
        pub let containerCap: Capability<&CrediflowContainer{CrediflowContainerPublic}>

        pub fun claim(): @FungibleToken.Vault {
            let container = self.containerCap.borrow()
                ?? panic("Could not borrow a reference to the CrediflowContainer")

            let content = container.borrowPublicContentRef(contentId: self.contentId)
                ?? panic("Could not borrow a reference to the Content")

            return <- content.requestClaim()
        }

        init(_contentHost: Address, _contentId: UInt64) {
            self.id = self.uuid
            self.contentHost = _contentHost
            self.contentId = _contentId

            // Store a reference to the CrediflowContainer in the account storage
            self.containerCap = getAccount(_contentHost)
                .getCapability<&CrediflowContainer{CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath)

            // emit EVENT via Creator
            Crediflow.totalCreatorSupply = Crediflow.totalCreatorSupply + 1
        }
    }

    // An Admirer as an NFT
    // Represents a NFT has a tipable Crediflow.
    // TODO: MetadataViews.Resolver
    pub resource AdmirerNFT: NonFungibleToken.INFT, Tipper {
        pub let id: UInt64

        // special
        pub let contentHost: Address
        pub let contentId: UInt64
        // tip by this Capabilty
        pub let containerCap: Capability<&CrediflowContainer{CrediflowContainerPublic}>

        pub fun tip(token: @FungibleToken.Vault) {
            let container = self.containerCap.borrow()
                ?? panic("Could not borrow a reference to the CrediflowContainer")

            let content = container.borrowPublicContentRef(contentId: self.contentId)
                ?? panic("Could not borrow a reference to the Content")

            content.requestTip(token: <-token)
        }

        init(_contentHost: Address, _contentId: UInt64) {
            self.id = self.uuid
            self.contentHost = _contentHost
            self.contentId = _contentId

            // Store a reference to the CrediflowContainer in the account storage
            self.containerCap = getAccount(_contentHost)
                .getCapability<&CrediflowContainer{CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath)

            // emit EVENT via Admirer
            Crediflow.totalAdmirerSupply = Crediflow.totalAdmirerSupply + 1
        }
    }

    // A Collection of Creator NFTs owned by an account
    // TODO: MetadataViews.ResolverCollection
    pub resource CreatorCollection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // deposit
        // takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Crediflow.CreatorNFT
            let id: UInt64 = token.id
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            // emit EVENT via Creator
            destroy oldToken
        }

        // withdraw
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            // emit EVENT via Creator
            return <- token
        }

        // getIDs
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // A Collection that tips all of the Admirer Crediflow.
    // TODO: MetadataViews.ResolverCollection
    pub resource AdmirerCollection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // deposit
        // takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @Crediflow.AdmirerNFT
            let id: UInt64 = token.id
            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token
            // emit EVENT via Creator
            destroy oldToken
        }

        // withdraw
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
            // emit EVENT via Creator
            return <- token
        }

        // getIDs
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    pub resource interface CrediflowContentPublic {
        pub fun requestClaim(): @FungibleToken.Vault
        pub fun requestTip(token: @FungibleToken.Vault)
    }

    //
    // Crefiflow Content: A Content that can be claimed and tipped
    //
    pub resource CrediflowContent: CrediflowContentPublic {
        // This is equal to this resource's uuid
        pub let contentId: UInt64
        // Whoe created this Crediflow Content
        pub let contentHost: Address
        // The name of this Crediflow Content
        pub let contentName: String

        access(account) var creatorMap: {Address: TokenIdentifier}
        access(account) var admirerMap: {Address: TokenIdentifier}
        pub var totalCreatorSupply: UInt64
        pub var totalAdmirerSupply: UInt64

        access(account) var claimed: {Address: TokenIdentifier}
        access(account) var tipped: {Address: TokenIdentifier}
        pub var totalClaim: UInt64
        pub var totalTip: UInt64

        pub fun requestClaim(): @FungibleToken.Vault {
            // impl
            // royaltyは実装しない
            // Poolからtokenを引き出す
            self.totalClaim = self.totalClaim + 1
        }

        pub fun requestTip(token: @FungibleToken.Vault) {
            // impl
            // royaltyは実装しない
            // tokenをCrediflowContainerのaccountからも引き出せない状態で保管したい(できればburnもできないようにしたい)
            self.totalTip = self.totalTip + 1
        }

        pub fun mintCreator(recipient: &CreatorCollection{NonFungibleToken.CollectionPublic}): UInt64 {
            pre {
                self.creatorMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent CreatorNFT"
            }
            let recipentAddr: Address = recipient.owner!.address
            let serial = self.totalCreatorSupply

            // TODO: 許可されたらnft作成
            let token <- create CreatorNFT(_contentHost: self.contentHost, _contentId: self.contentId)
            let id = token.id

            self.creatorMap[recipentAddr] = TokenIdentifier(_id: id, _address: recipentAddr, _serial: 0)
            self.totalCreatorSupply = self.totalCreatorSupply + 1
            recipient.deposit(token: <- token)

            return id
        }

        pub fun mintAdmirer(recipient: &AdmirerCollection{NonFungibleToken.CollectionPublic}): UInt64 {
            pre {
                self.admirerMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent AdmirerNFT"
            }
            let recipentAddr: Address = recipient.owner!.address
            let serial = self.totalAdmirerSupply

            // nft作成
            let token <- create AdmirerNFT(_contentHost: self.contentHost, _contentId: self.contentId)
            let id = token.id

            self.admirerMap[recipentAddr] = TokenIdentifier(_id: id, _address: recipentAddr, _serial: 0)
            self.totalAdmirerSupply = self.totalAdmirerSupply + 1
            recipient.deposit(token: <- token)

            return id
        }

        // pub fun isClaimable(): Bool {
        //     // 時限性を実装するならここで
        // }

        // pub fun isTipable(): Bool {
        //     // 時限性を実装するならここで
        //     return true
        // }

        init(_name: String, _host: Address) {
            self.contentId = self.uuid
            self.contentHost = _host
            self.contentName = _name
            self.totalCreatorSupply = 0
            self.totalAdmirerSupply = 0
            self.creatorMap = {}
            self.admirerMap = {}
            self.claimed = {}
            self.tipped = {}
            self.totalClaim = 0
            self.totalTip = 0
        }
    }

    pub resource interface CrediflowContainerPublic {
        pub fun borrowPublicContentRef(contentId: UInt64): &CrediflowContent{CrediflowContentPublic}?
    }

    // A "Collection" of CrediflowContent
    pub resource CrediflowContainer: CrediflowContainerPublic {
        access(account) var contentMap: @{UInt64: CrediflowContent}

        // Creates a new Crediflow Content
        pub fun createContent(
            name: String,
        ): UInt64 {
            // 内部にCrediflowContentを作成して、そのIDを返す
            let crediflowContent <- create CrediflowContent(
                _name: name,
                _host: self.owner!.address,
            )
            let contentId = crediflowContent.contentId
            self.contentMap[contentId] <-! crediflowContent
            return contentId
        }

        // Deletes a content
        pub fun deleteContent(contentId: UInt64) {
            // もしもすでにtip残高があれば失敗したい ※危険FTの burn に相当する
            let contentRef = self.borrowContentRef(contentId: contentId) ?? panic("missing CrediflowContent")
            destroy self.contentMap.remove(key: contentId)
        }

        // access(account) fun borrowContainerRef(): &CrediflowContainer {
        //     // 自身を渡す ※危険
        //     // grantでverifyしないといけない
        //     return &self as &CrediflowContainer
        // }

        pub fun borrowContentRef(contentId: UInt64): &CrediflowContent? {
            return &self.contentMap[contentId] as &CrediflowContent?
        }

        pub fun borrowPublicContentRef(contentId: UInt64): &CrediflowContent{CrediflowContentPublic}? {
            return &self.contentMap[contentId] as &CrediflowContent{CrediflowContentPublic}?
        }

        // getIDs
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.contentMap.keys
        }

        init() {
            self.contentMap <- {}
        }

        destroy() {
            // すでにtip残高があれば失敗したい ※危険FTの burn に相当する
            destroy self.contentMap
        }
    }

    pub fun createEmptyCreatorCollection(): @CreatorCollection {
        return <- create CreatorCollection()
    }

    pub fun createEmptyAdmirerCollection(): @AdmirerCollection {
        return <- create AdmirerCollection()
    }

    pub fun createEmptyCrediflowContainer(): @CrediflowContainer {
        return <- create CrediflowContainer()
    }

    init() {
        self.totalCreatorSupply = 0
        self.totalAdmirerSupply = 0
        self.totalCrediflowContainer = 0
        emit ContractInitialized()

        self.CrediflowCreatorCollectionStoragePath = /storage/crediflowCreatorCollectionStoragePath
        self.CrediflowCreatorCollectionPublicPath = /public/crediflowCreatorCollectionPublicPath

        self.CrediflowAdmirerCollectionStoragePath = /storage/crediflowAdmirerCollectionStoragePath
        self.CrediflowAdmirerCollectionPublicPath = /public/crediflowAdmirerCollectionPublicPath

        self.CrediflowContainerStoragePath = /storage/crediflowContainerStoragePath
        self.CrediflowContainerPublicPath = /public/crediflowContainerPublicPath
        self.CrediflowContainerPrivatePath = /private/crediflowContainerPrivatePath
    }
}
