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
    pub event CreatorClaimed(contentId: UInt64, contentHost: Address, recipient: Address, amount: UFix64)
    pub event AdmirerTipped(contentId: UInt64, contentHost: Address, recipient: Address, amount: UFix64)

    pub event Deposit(id: UInt64, to: Address?)
    pub event Withdraw(id: UInt64, from: Address?)

    // STATE
    pub var totalSupply: UInt64
    pub var totalCreatorSupply: UInt64
    pub var totalAdmirerSupply: UInt64
    pub var totalCrediflowContent: UInt64

    pub enum NFTType: UInt8 {
        pub case Creator
        pub case Admirer
    }

    // STRUCT
    pub struct RoleIdentifier { // immutable
        // creator address
        pub let address: Address
        // creator role
        pub let role: String
        // creator metadata
        pub let metadata: {String: AnyStruct}

        init(_address: Address, _role: String, _metadata: {String: AnyStruct}) {
            self.address = _address
            self.role = _role
            self.metadata = _metadata
        }
    }

    pub struct NFTIdentifier { // immutable
        pub let id: UInt64
        // creator or admirer address
        pub let address: Address
        // creator or admirer serial
        pub let serial: UInt64

        init(_id: UInt64, _address: Address, _serial: UInt64) {
            self.id = _id
            self.address = _address
            self.serial = _serial
        }
    }

    pub struct ValutProcesser { // immutable, but can be updated
        // creator address
        pub let address: Address
        // creator claimable balance
        pub let balance: UFix64

        init(_address: Address, _balance: UFix64) {
            self.address = _address
            self.balance = _balance
        }
    }

    // INTERFACE
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
    // Represents a NFT has a claimable.
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, Claimer, Tipper {
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
        pub fun claim(): @FungibleToken.Vault {
            let container = self.containerCap.borrow()
                ?? panic("Could not borrow a reference to the CrediflowContainer")

            let content = container.borrowPublicContentRef(contentId: self.contentId)
                ?? panic("Could not borrow a reference to the Content")

            return <- content.requestClaim()
        }

        // tip to the content
        pub fun tip(token: @FungibleToken.Vault) {
            let container = self.containerCap.borrow()
                ?? panic("Could not borrow a reference to the CrediflowContainer")

            let content = container.borrowPublicContentRef(contentId: self.contentId)
                ?? panic("Could not borrow a reference to the Content")

            content.requestTip(<- token)
        }

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

            switch self.nftType {
                case NFTType.Creator:
                    Crediflow.totalCreatorSupply = Crediflow.totalCreatorSupply + 1
                case NFTType.Admirer:
                    Crediflow.totalAdmirerSupply = Crediflow.totalAdmirerSupply + 1
            }
            Crediflow.totalSupply = Crediflow.totalSupply + 1
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
            emit Deposit(id: id, to: self.owner!.address)
            self.ownedNFTs[id] <-! nft
        }

        // withdraw
        // removes an NFT from the collection and moves it to the caller
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let nft <- self.ownedNFTs.remove(key: withdrawID) ?? panic("this CreatorNFT does not exist")
            emit Withdraw(id: withdrawID, from: self.owner!.address)
            return <- nft
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
        pub fun mintAdmirer(recipient: &Collection{NonFungibleToken.CollectionPublic}): UInt64

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

        pub let dateCreated: UFix64

        // NFTs minted by this Crediflow Content
        access(account) var creatorNFTMap: {Address: NFTIdentifier}
        access(account) var admirerNFTMap: {Address: NFTIdentifier}
        pub var contentCreatorNFTSupply: UInt64
        pub var contentAdmirerNFTSupply: UInt64

        // Vault of the token that can be claimed
        pub var creatorFTPool: @FlowToken.Vault
        access(account) var creatorValutMap: {Address: ValutProcesser}
        access(account) var creatorMap: {Address: RoleIdentifier}

        access(account) var claimed: {Address: ValutProcesser}
        access(account) var tipped: {Address: ValutProcesser}
        pub var totalClaim: UInt64
        pub var totalTip: UInt64

        pub fun requestClaim(): @FungibleToken.Vault {
            pre {
                self.isClaimable(): "Cannot claim this CrediflowContent"
                self.creatorMap[self.owner!.address] == nil: "You are not allowed to claim this CrediflowContent"
                self.creatorValutMap[self.owner!.address] == nil: "You are not allowed to claim this CrediflowContent"
                self.creatorNFTMap[self.owner!.address] == nil: "You are not allowed to claim this CrediflowContent"
            }
            post {
                self.creatorValutMap[self.owner!.address]?.balance == 0.0: "Should be claimed all balance"
                self.claimed[self.owner!.address]?.balance == 0.0: "Should be claimed any balance"
            }

            // claim by own claimable max amount
            let claimAmount = self.creatorValutMap[self.owner!.address]?.balance ?? panic("Should not happen")
            if claimAmount == 0.0 {
                return <- FlowToken.createEmptyVault()
            }

            self.claimed[self.owner!.address] = ValutProcesser(
                _address: self.owner!.address,
                _balance: self.claimed[self.owner!.address]?.balance ?? 0.0 + claimAmount)

            emit CreatorClaimed(
                contentId: self.contentId,
                contentHost: self.contentHost,
                recipient: self.owner!.address,
                amount: claimAmount,
            )
            self.totalClaim = self.totalClaim + 1
            let receiveFT <- self.creatorFTPool.withdraw(amount: claimAmount)
            return <- receiveFT
        }

        pub fun requestTip(_ tokenTipped: @FungibleToken.Vault) {
            pre {
                self.isTipable(): "Cannot tip this CrediflowContent"
                self.admirerNFTMap[self.owner!.address] == nil: "You are not allowed to tip this CrediflowContent"
            }
            post {
                self.tipped[self.owner!.address]?.balance == 0.0: "Should be tipped any balance"
            }

            // split token to each creator
            let splitTipAmount = tokenTipped.balance / UFix64(self.creatorValutMap.length)
            for creatorValutKey in self.creatorValutMap.keys {
                let creatorValue = self.creatorValutMap[creatorValutKey] ?? panic("Should not happen")
                // update creator's tip amount
                self.creatorValutMap[creatorValutKey] = ValutProcesser(
                    _address: creatorValue.address,
                    _balance: creatorValue.balance + splitTipAmount)
            }

            self.tipped[self.owner!.address] = ValutProcesser(
                _address: self.owner!.address,
                _balance: self.tipped[self.owner!.address]?.balance ?? 0.0 + tokenTipped.balance)

            emit AdmirerTipped(
                contentId: self.contentId,
                contentHost: self.contentHost,
                recipient: self.owner!.address,
                amount: tokenTipped.balance,
            )
            self.totalTip = self.totalTip + 1
            self.creatorFTPool.deposit(from: <- tokenTipped)
        }

        pub fun mintCreator(recipient: &Collection{NonFungibleToken.CollectionPublic}): UInt64 {
            pre {
                self.creatorNFTMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent Creator NFT"
                self.creatorMap[self.owner!.address] == nil: "You are not allowed to mint this CrediflowContent Creator NFT"
                self.creatorValutMap[self.owner!.address] == nil: "You are not allowed to mint this CrediflowContent Creator NFT"
            }
            post {
                self.creatorNFTMap[recipient.owner!.address] != nil: "Should be minted Creator NFT"
            }

            let recipentAddr: Address = recipient.owner!.address
            let serial: UInt64 = self.contentCreatorNFTSupply

            let token <- create NFT(_type: NFTType.Creator, _contentHost: self.contentHost, _contentId: self.contentId, _serial: serial)
            let id: UInt64 = token.id

            self.creatorNFTMap[recipentAddr] = NFTIdentifier(_id: id, _address: recipentAddr, _serial: serial)
            self.contentCreatorNFTSupply = self.contentCreatorNFTSupply + 1

            recipient.deposit(token: <- token)
            return id
        }

        pub fun mintAdmirer(recipient: &Collection{NonFungibleToken.CollectionPublic}): UInt64 {
            pre {
                self.admirerNFTMap[recipient.owner!.address] == nil: "Already minted their CrediflowContent Admirer NFT"
            }
            post {
                self.admirerNFTMap[recipient.owner!.address] != nil: "Should be minted Admirer NFT"
            }

            let recipentAddr: Address = recipient.owner!.address
            let serial = self.contentAdmirerNFTSupply

            let token <- create NFT(_type: NFTType.Admirer, _contentHost: self.contentHost, _contentId: self.contentId, _serial: serial)
            let id: UInt64 = token.id

            self.admirerNFTMap[recipentAddr] = NFTIdentifier(_id: id, _address: recipentAddr, _serial: serial)
            self.contentAdmirerNFTSupply = self.contentAdmirerNFTSupply + 1

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

        init(_name: String, _host: Address, _creatorMap: {Address: RoleIdentifier}) {
            self.contentId = self.uuid
            self.contentHost = _host
            self.contentName = _name

            self.dateCreated = getCurrentBlock().timestamp
            self.creatorMap = _creatorMap // immutable

            // NFTs
            self.contentCreatorNFTSupply = 0
            self.contentAdmirerNFTSupply = 0
            self.creatorNFTMap = {} // this mean no minted NFT as a creator
            self.admirerNFTMap = {} // this mean no minted NFT as an admirer

            // Valuts
            self.creatorFTPool <- FlowToken.createEmptyVault() as! @FlowToken.Vault

            // Processer
            // create empty creators' valut
            let creatorValueMap: {Address: ValutProcesser} = {}
            for creatorAddress in _creatorMap.keys {
                creatorValueMap[creatorAddress] = ValutProcesser(_address: creatorAddress, _balance: 0.0)
            }
            self.creatorValutMap = creatorValueMap

            self.claimed = {}
            self.tipped = {}
            self.totalClaim = 0
            self.totalTip = 0

            Crediflow.totalCrediflowContent = Crediflow.totalCrediflowContent + 1
            emit CreateContent(contentId: self.contentId, contentHost: self.contentHost)
        }

        destroy () {
            // もしもすでにtip残高があれば失敗したい ※危険FTの burn に相当する
            destroy self.creatorFTPool
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
            creatorMap: {Address: RoleIdentifier}
        ): UInt64 {
            let crediflowContent <- create CrediflowContent(
                _name: name,
                _host: self.owner!.address,
                _creatorMap: creatorMap
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
        self.totalCrediflowContent = 0
        emit ContractInitialized()

        self.CrediflowCollectionStoragePath = /storage/crediflowCollectionStoragePath
        self.CrediflowCollectionPublicPath = /public/crediflowCollectionPublicPath

        self.CrediflowContainerStoragePath = /storage/crediflowContainerStoragePath
        self.CrediflowContainerPublicPath = /public/crediflowContainerPublicPath
        self.CrediflowContainerPrivatePath = /private/crediflowContainerPrivatePath
    }
}
