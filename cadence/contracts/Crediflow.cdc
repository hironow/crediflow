import FlowToken from 0x0ae53cb6e3f42a79
import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7

//
// Crediflow: credit + flow
// contents' end `credit`s and `flow` blockchain
//
pub contract Crediflow: NonFungibleToken {
    // PATHS
    pub let CrediflowCollectionStoragePath: StoragePath
    pub let CrediflowCollectionPublicPath: PublicPath

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

    pub event Deposit(id: UInt64, to: Address?)
    pub event Withdraw(id: UInt64, from: Address?)

    // STATE
    pub var totalSupply: UInt64
    pub var totalCreatorSupply: UInt64
    pub var totalAdmirerSupply: UInt64
    pub var totalCrediflowContainer: UInt64

    pub enum NFTType: UInt8 {
        pub case creator
        pub case admirer
    }

    // STRUCT
    pub struct RoleIdentifier { // immutable
        pub let address: Address // creators' address
        pub let role: String // creators' role
        pub let metadata: {String: AnyStruct} // creators' metadata

        init(_address: Address, _role: String, _metadata: {String: AnyStruct}) {
            self.address = _address
            self.role = _role
            self.metadata = _metadata
        }
    }

    pub struct NFTIdentifier { // immutable
        pub let id: UInt64
        pub let address: Address // creators' or admirers' address
        pub let serial: UInt64 // creators' or admirers' serial

        init(_id: UInt64, _address: Address, _serial: UInt64) {
            self.id = _id
            self.address = _address
            self.serial = _serial
        }
    }

    pub struct ValutProcesser { // not immutable
        pub let address: Address // creators' address
        pub let balance: UInt64 // creators' claimable balance

        init(_address: Address, _balance: UInt64) {
            self.address = _address
            self.balance = _balance
        }
    }

    // INTERFACE
    // pub resource interface Claimer {
    //     pub fun claim(): @FungibleToken.Vault {
    //         post {
    //             result.balance > 0.0: "Claim amount must be greater than 0.0"
    //         }
    //     }
    // }

    // pub resource interface Tipper {
    //     pub fun tip(token: @FungibleToken.Vault) {
    //         pre {
    //             token.balance > 0.0: "Tip amount must be greater than 0.0"
    //         }
    //     }
    // }

    // A Creator as an NFT
    // Represents a NFT has a claimable.
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        // The `uuid` of this resource
        pub let id: UInt64

        // special
        pub let nftType: NFTType
        pub let contentHost: Address
        pub let contentId: UInt64
        pub let serial: UInt64
        // claim by this Capabilty
        pub let containerCap: Capability<&CrediflowContainer{CrediflowContainerPublic}>

        // claim from the content
        // pub fun claim(): @FungibleToken.Vault {
        //     let container = self.containerCap.borrow()
        //         ?? panic("Could not borrow a reference to the CrediflowContainer")

        //     let content = container.borrowPublicContentRef(contentId: self.contentId)
        //         ?? panic("Could not borrow a reference to the Content")

        //     return <- content.requestClaim()
        // }

        // tip to the content
        // pub fun tip(token: @FungibleToken.Vault) {
        //     let container = self.containerCap.borrow()
        //         ?? panic("Could not borrow a reference to the CrediflowContainer")

        //     let content = container.borrowPublicContentRef(contentId: self.contentId)
        //         ?? panic("Could not borrow a reference to the Content")

        //     content.requestTip(<- token)
        // }

        pub fun getViews(): [Type] {
            let supportedViews: [Type] = [
                Type<MetadataViews.Serial>()
            ]
            return supportedViews
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Serial>():
                    return MetadataViews.Serial(
                        self.serial
                    )
            }
            return nil
        }

        init(_type: NFTType, _contentHost: Address, _contentId: UInt64, _serial: UInt64) {
            self.nftType = _type
            self.id = self.uuid
            self.contentHost = _contentHost
            self.contentId = _contentId
            self.serial = _serial

            // Store a reference to the CrediflowContainer in the account storage
            self.containerCap = getAccount(_contentHost)
                .getCapability<&CrediflowContainer{CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath)

            Crediflow.totalSupply = Crediflow.totalSupply + 1
            // TODO: 分岐
            Crediflow.totalCreatorSupply = Crediflow.totalCreatorSupply + 1
        }

        destroy () {}
    }

    // PUBLIC COLLECTION INTERFACE
    pub resource interface CollectionPublic {
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        // pub fun borrowCreatorNFT(id: UInt64): &NFT?
        // pub fun borrowAdmirerNFT(id: UInt64): &NFT?
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
    }

    // A Collection of Creator NFTs owned by an account.
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, CollectionPublic {
        // dictionary of CreatorNFT conforming tokens
        // NFT is a resource type with an `UInt64` as uuid field
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // deposit
        // takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let nft <- token as! @Crediflow.NFT
            let id: UInt64 = nft.id
            let contentId: UInt64 = nft.contentId
            // add the new token to the dictionary which removes the old one
            emit CreatorDeposit(id: id, from: self.owner!.address)
            self.ownedNFTs[id] <-! nft
        }

        // withdraw
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("this CreatorNFT does not exist")
            emit CreatorWithdraw(id: withdrawID, to: self.owner!.address)
            return <- token
        }

        // getIDs
        // returns an array of the IDs that are in the collection
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return (&self.ownedNFTs[id] as &NonFungibleToken.NFT?)!
        }

        // pub fun borrowCreatorNFT(id: UInt64): &NFT? {
        //     if self.ownedNFTs[id] != nil {
        //         let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        //         return ref as! &NFT
        //     }
        //     return nil
        // }

        // pub fun borrowAdmirerNFT(id: UInt64): &NFT? {
        //     if self.ownedNFTs[id] != nil {
        //         let ref = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
        //         return ref as! &NFT
        //     }
        //     return nil
        // }

        pub fun borrowViewResolver(id: UInt64): &{MetadataViews.Resolver} {
            let tokenRef = (&self.ownedNFTs[id] as auth &NonFungibleToken.NFT?)!
            let nftRef = tokenRef as! &NFT
            return nftRef
        }

        init() {
            self.ownedNFTs <- {}
        }

        destroy() {
            destroy self.ownedNFTs
        }
    }

    // INTERFACE, not Collection
    pub resource interface CrediflowContentPublic {
        pub fun requestClaim(): @FungibleToken.Vault
        pub fun requestTip(_ tokenTipped: @FungibleToken.Vault)
        pub fun mintCreator(recipient: &Collection{NonFungibleToken.CollectionPublic}): UInt64
        pub fun mintAdmirer(recipient: &Collection{NonFungibleToken.CollectionPublic}, tokenTipped: @FungibleToken.Vault): UInt64

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
        access(account) var creatorMap: {Address: NFTIdentifier}
        access(account) var admirerMap: {Address: NFTIdentifier}
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

            // TODO: Poolからtokenを引き出す
            let receiveFT <- self.creatorFTValut.withdraw(amount: 0.001)
            self.totalClaim = self.totalClaim + 1
            return <- receiveFT
        }

        pub fun requestTip(_ tokenTipped: @FungibleToken.Vault) {
            pre {
                self.isTipable(): "Cannot tip this CrediflowContent"
            }

            // TODO: tokenをCrediflowContainerのaccountからも引き出せない状態で保管したい(できればburnもできないようにしたい)
            self.creatorFTValut.deposit(from: <-tokenTipped)
            self.totalTip = self.totalTip + 1
        }

        pub fun mintCreator(recipient: &Collection{NonFungibleToken.CollectionPublic}): UInt64 {
            pre {
                self.creatorMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent Creator NFT"
            }
            let recipentAddr: Address = recipient.owner!.address
            let serial: UInt64 = self.totalCreatorNFTSupply

            // TODO: 許可されたらnft作成
            let token <- create NFT(_type: NFTType.creator, _contentHost: self.contentHost, _contentId: self.contentId, _serial: serial)
            let id: UInt64 = token.id

            self.creatorMap[recipentAddr] = NFTIdentifier(_id: id, _address: recipentAddr, _serial: serial)
            self.totalCreatorNFTSupply = self.totalCreatorNFTSupply + 1

            recipient.deposit(token: <- token)
            return id
        }

        pub fun mintAdmirer(recipient: &Collection{NonFungibleToken.CollectionPublic}, tokenTipped: @FungibleToken.Vault): UInt64 {
            pre {
                self.admirerMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent Admirer NFT"
            }
            let recipentAddr: Address = recipient.owner!.address
            let serial = self.totalAdmirerNFTSupply

            // deposit token to Content
            // TODO: creatorごとにtipを割当する
            self.creatorFTValut.deposit(from: <-tokenTipped)

            let token <- create NFT(_type: NFTType.admirer, _contentHost: self.contentHost, _contentId: self.contentId, _serial: serial)
            let id: UInt64 = token.id

            self.admirerMap[recipentAddr] = NFTIdentifier(_id: id, _address: recipentAddr, _serial: serial)
            self.totalAdmirerNFTSupply = self.totalAdmirerNFTSupply + 1

            recipient.deposit(token: <- token)
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
            self.creatorMap = {}
            self.admirerMap = {}

            // Valuts
            self.creatorFTValut <- FlowToken.createEmptyVault() as! @FlowToken.Vault
            self.claimed = {}
            self.tipped = {}
            self.totalClaim = 0
            self.totalTip = 0

            emit CreateContent(contentId: self.contentId, contentHost: self.contentHost)
        }

        destroy () {
            destroy self.creatorFTValut
        }
    }

    // PUBLIC COLLECTION INTERFACE
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

    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    pub fun createEmptyCrediflowContainer(): @CrediflowContainer {
        return <- create CrediflowContainer()
    }

    init() {
        self.totalSupply = 0
        self.totalCreatorSupply = 0
        self.totalAdmirerSupply = 0
        self.totalCrediflowContainer = 0
        emit ContractInitialized()

        self.CrediflowCollectionStoragePath = /storage/crediflowCollectionStoragePath
        self.CrediflowCollectionPublicPath = /public/crediflowCollectionPublicPath

        self.CrediflowContainerStoragePath = /storage/crediflowContainerStoragePath
        self.CrediflowContainerPublicPath = /public/crediflowContainerPublicPath
        self.CrediflowContainerPrivatePath = /private/crediflowContainerPrivatePath
    }
}
