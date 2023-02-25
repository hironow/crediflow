import FlowToken from 0x0ae53cb6e3f42a79 // "./core/FlowToken.cdc"
import FungibleToken from 0xee82856bf20e2aa6 // "./core/FungibleToken.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7 // "./core/NonFungibleToken.cdc"
import MetadataViews from 0xf8d6e0586b0a20c7 // "./core/MetadataViews.cdc"

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
    pub event CreateContent(contentId: UInt64, contentHost: Address)
    pub event CreatorClaimed(id: UInt64, contentHost: Address, contentId: UInt64, recipient: Address, serial: UInt64, amount: UInt64)
    pub event AdmirerTipped(id: UInt64, contentHost: Address, contentId: UInt64, recipient: Address, serial: UInt64, amount: UInt64)

    pub event CreatorDeposit(id: UInt64, from: Address?)
    pub event CreatorWithdraw(id: UInt64, to: Address?)
    pub event AdmirerDeposit(id: UInt64, from: Address?)
    pub event AdmirerWithdraw(id: UInt64, to: Address?)

    // STATE
    pub var totalCreatorSupply: UInt64
    pub var totalAdmirerSupply: UInt64
    pub var totalCrediflowContainer: UInt64

    // STRUCT
    pub struct NFTIdentifier {
        pub let id: UInt64
        pub let address: Address
        pub let serial: UInt64

        init(_id: UInt64, _address: Address, _serial: UInt64) {
            self.id = _id
            self.address = _address
            self.serial = _serial
        }
    }

    pub struct ValutProcesser {
        pub let id: UInt64
        pub let address: Address
        pub let balance: UInt64

        init(_id: UInt64, _address: Address, _balance: UInt64) {
            self.id = _id
            self.address = _address
            self.balance = _balance
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
        // The `uuid` of this resource
        pub let id: UInt64

        // special
        pub let contentHost: Address
        pub let contentId: UInt64
        // claim by this Capabilty
        pub let containerCap: Capability<&CrediflowContainer{CrediflowContainerPublic}>

        // claim from the content
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

        destroy () {}
    }

    // An Admirer as an NFT
    // Represents a NFT has a tipable Crediflow.
    // TODO: MetadataViews.Resolver
    pub resource AdmirerNFT: NonFungibleToken.INFT, Tipper {
        // The `uuid` of this resource
        pub let id: UInt64

        // special
        pub let contentHost: Address
        pub let contentId: UInt64
        // tip by this Capabilty
        pub let containerCap: Capability<&CrediflowContainer{CrediflowContainerPublic}>

        // tip to the content
        pub fun tip(token: @FungibleToken.Vault) {
            let container = self.containerCap.borrow()
                ?? panic("Could not borrow a reference to the CrediflowContainer")

            let content = container.borrowPublicContentRef(contentId: self.contentId)
                ?? panic("Could not borrow a reference to the Content")

            content.requestTip(<- token)
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

    pub resource interface CreatorCollectionPublic {
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
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
            let nft <- token as! @Crediflow.CreatorNFT
            let id: UInt64 = nft.id
            let contentId: UInt64 = nft.contentId
            // add the new token to the dictionary which removes the old one
            // emit EVENT via Creator
            self.ownedNFTs[id] <-! nft
        }

        // withdraw
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("this CreatorNFT does not exist")
            // emit EVENT via Creator
            return <- token
        }

        // getIDs
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // gets a reference to an CreatorNFT in the collection
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

    pub resource interface AdmirerCollectionPublic {
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
    }

    // A Collection that tips all of the Admirer Crediflow.
    // TODO: MetadataViews.ResolverCollection
    pub resource AdmirerCollection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, AdmirerCollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // deposit
        // takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let nft <- token as! @Crediflow.AdmirerNFT
            let id: UInt64 = nft.id
            let contentId: UInt64 = nft.contentId
            // add the new token to the dictionary which removes the old one
            // emit EVENT via Admirer
            self.ownedNFTs[id] <-! nft
        }

        // withdraw
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("this AdmirerNFT does not exist")
            // emit EVENT via Admirer
            return <- token
        }

        // getIDs
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // gets a reference to an AdmirerNFT in the collection
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
        pub fun requestTip(_ tokenTipped: @FungibleToken.Vault)
        pub fun mintCreator(recipient: &CreatorCollection{NonFungibleToken.CollectionPublic}): UInt64
        pub fun mintAdmirer(recipient: &AdmirerCollection{NonFungibleToken.CollectionPublic}, tokenTipped: @FungibleToken.Vault): UInt64

        // pub fun closePool()
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

        // NFTs minted by this Crediflow Content
        access(account) var creatorNFTMap: {Address: NFTIdentifier}
        access(account) var admirerNFTMap: {Address: NFTIdentifier}
        pub var totalCreatorNFTSupply: UInt64
        pub var totalAdmirerNFTSupply: UInt64

        // Vault of the token that can be claimed
        pub var creatorFTValut: @FlowToken.Vault
        access(account) var claimed: {Address: ValutProcesser}
        access(account) var tipped: {Address: ValutProcesser}
        pub var totalClaim: UInt64
        pub var totalTip: UInt64

        pub fun requestClaim(): @FungibleToken.Vault {
            pre {
                self.isClaimable(): "Cannot claim this CrediflowContent"
            }

            // Poolからtokenを引き出す
            let receiveFT <- self.creatorFTValut.withdraw(amount: 0.001)
            self.totalClaim = self.totalClaim + 1
            return <- receiveFT
        }

        pub fun requestTip(_ tokenTipped: @FungibleToken.Vault) {
            pre {
                self.isTipable(): "Cannot tip this CrediflowContent"
            }

            // tokenをCrediflowContainerのaccountからも引き出せない状態で保管したい(できればburnもできないようにしたい)
            self.creatorFTValut.deposit(from: <-tokenTipped)
            self.totalTip = self.totalTip + 1
        }

        pub fun mintCreator(recipient: &CreatorCollection{NonFungibleToken.CollectionPublic}): UInt64 {
            pre {
                self.creatorNFTMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent CreatorNFT"
            }
            let recipentAddr: Address = recipient.owner!.address
            let serial = self.totalCreatorNFTSupply

            // TODO: 許可されたらnft作成
            let nft <- create CreatorNFT(_contentHost: self.contentHost, _contentId: self.contentId)
            let id = nft.id

            self.creatorNFTMap[recipentAddr] = NFTIdentifier(_id: id, _address: recipentAddr, _serial: serial)
            self.totalCreatorNFTSupply = self.totalCreatorNFTSupply + 1
            recipient.deposit(token: <- nft)
            return id
        }

        pub fun mintAdmirer(recipient: &AdmirerCollection{NonFungibleToken.CollectionPublic}, tokenTipped: @FungibleToken.Vault): UInt64 {
            pre {
                self.admirerNFTMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent AdmirerNFT"
            }
            let recipentAddr: Address = recipient.owner!.address
            let serial = self.totalAdmirerNFTSupply

            // deposit token to Content
            self.creatorFTValut.deposit(from: <-tokenTipped)

            // nft作成
            let nft <- create AdmirerNFT(_contentHost: self.contentHost, _contentId: self.contentId)
            let id = nft.id

            self.admirerNFTMap[recipentAddr] = NFTIdentifier(_id: id, _address: recipentAddr, _serial: serial)
            self.totalAdmirerNFTSupply = self.totalAdmirerNFTSupply + 1
            recipient.deposit(token: <- nft)
            return id
        }

        pub fun isClaimable(): Bool {
            // 時限性を実装するならここで
            return true
        }

        pub fun isTipable(): Bool {
            // 時限性を実装するならここで
            return true
        }

        init(_name: String, _host: Address) {
            self.contentId = self.uuid
            self.contentHost = _host
            self.contentName = _name

            // NFTs
            self.totalCreatorNFTSupply = 0
            self.totalAdmirerNFTSupply = 0
            self.creatorNFTMap = {}
            self.admirerNFTMap = {}

            // Valuts
            self.creatorFTValut <- FlowToken.createEmptyVault() as! @FlowToken.Vault
            self.claimed = {}
            self.tipped = {}
            self.totalClaim = 0
            self.totalTip = 0
        }

        destroy () {
            destroy self.creatorFTValut
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

        /// Close all the Pools before destroying everything
        /// This uses the closePool method, so it will panic if there are still tokens staked in any of the objects
        destroy() {
            let contentIDs = self.getIDs()

            for contentID in contentIDs {
                // self.closePool(contentId: contentID)
            }

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
