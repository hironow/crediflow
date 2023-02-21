import FungibleToken from "./FungibleToken.cdc"
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
    pub struct RoleIdentifier {
        pub let id: UInt64
        pub let address: Address
        pub let serial: UInt64

        pub let role: String

        init(_id: UInt64, _address: Address, _serial: UInt64, _role: String) {
            self.id = _id
            self.address = _address
            self.serial = _serial
            self.role = _role
        }
    }


    pub resource interface Counter {
        pub var total: UFix64
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

    pub resource interface CrediflowContentPublic {
        pub fun claimFromCreator()
        pub fun tipFromAdmirer(token: @FungibleToken.Vault)
    }

    pub resource interface CrediflowContainerPublic {
        pub fun borrowPublicContentRef(contentId: UInt64): &CrediflowContent{CrediflowContentPublic}?
    }

    // Represents a Creator NFT has a claimable Crediflow.
    // TODO: MetadataViews, impl profile like a .find
    pub resource CreatorNFT: NonFungibleToken.INFT, Claimer {
        // The `uuid` of this resource
        pub let id: UInt64
        pub let contentHost: Address

        // このcapabilityを経由してclaimする
        pub let containerCap: Capability<&CrediflowContainer{CrediflowContainerPublic}>

        pub fun claim(): @FungibleToken.Vault {
            // impl
        }

        init(_contentHost: Address) {
            self.id = self.uuid
            self.contentHost = _contentHost

            // Store a reference to the CrediflowContainer in the account storage
            self.containerCap = getAccount(_contentHost)
                .getCapability<&CrediflowContainer{CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath)

            // emit EVENT
            Crediflow.totalCreatorSupply = Crediflow.totalCreatorSupply + 1
        }
    }

    // Represents a Admirer NFT has a tipable Crediflow.
    // TODO: MetadataViews, impl profile like a .find
    pub resource AdmirerNFT: NonFungibleToken.INFT, Tipper {
        // The `uuid` of this resource
        pub let id: UInt64
        pub let contentHost: Address

        // このcapabilityを経由してtipする
        pub let containerCap: Capability<&CrediflowContainer{CrediflowContainerPublic}>

        pub fun tip(token: @FungibleToken.Vault) {
            // impl
        }

        init(_contentHost: Address) {
            self.id = self.uuid
            self.contentHost = _contentHost

            // Store a reference to the CrediflowContainer in the account storage
            self.containerCap = getAccount(_contentHost)
                .getCapability<&CrediflowContainer{CrediflowContainerPublic}>(Crediflow.CrediflowContainerPublicPath)

            // emit EVENT
            Crediflow.totalAdmirerSupply = Crediflow.totalAdmirerSupply + 1
        }
    }

    // A Collection that claims all of the Creator Crediflow.
    // TODO: MetadataViews
    pub resource CreatorCollection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun deposit(token: @NonFungibleToken.NFT) {
            // impl
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            // impl
        }

        pub fun getIDs(): [UInt64] {
            let ids: [UInt64] = []
            for key in self.ownedNFTs.keys {
                let nftRef = self.borrowNFT(id: key)!
                ids.append(key)
            }
            return ids
        }

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
    // TODO: MetadataViews
    pub resource AdmirerCollection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        pub fun deposit(token: @NonFungibleToken.NFT) {
            // impl
        }

        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            // impl
        }

        pub fun getIDs(): [UInt64] {
            let ids: [UInt64] = []
            for key in self.ownedNFTs.keys {
                let nftRef = self.borrowNFT(id: key)!
                ids.append(key)
            }
            return ids
        }

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

    // TODO: MetadataViews
    pub resource CrediflowContent: CrediflowContentPublic {
        // This is equal to this resource's uuid
        pub let contentId: UInt64

        pub var totalClaim: UInt64
        pub var totalTip: UInt64

        pub fun claimFromCreator() {
            // impl
            // royaltyは実装しない
        }
        pub fun tipFromAdmirer(token: @FungibleToken.Vault) {
            // impl
            // royaltyは実装しない
            // tokenをCrediflowContainerのaccountからも引き出せない状態で保管したい(できればburnもできないようにしたい)
        }

        init() {
            self.contentId = self.uuid
            self.totalClaim = 0
            self.totalTip = 0
        }
    }

    // A "Collection" of CrediflowContent
    pub resource CrediflowContainer: CrediflowContainerPublic {
        access(account) var contentMap: @{UInt64: CrediflowContent}

        pub fun createContent(): UInt64 {
            // 内部にCrediflowContentを作成して、そのIDを返す
            let content <- create CrediflowContent()
            self.contentMap[0] <-! content
            return 0
        }

        pub fun deleteContent(contentId: UInt64) {
            // もしもすでにtip残高があれば失敗したい
        }

        access(account) fun borrowContainerRef(): &CrediflowContainer {
            // 自身を渡す ※危険
            // grantでverifyしないといけない
            return &self as &CrediflowContainer
        }

        pub fun borrowPublicContentRef(contentId: UInt64): &CrediflowContent{CrediflowContentPublic}? {
            return &self.contentMap[contentId] as &CrediflowContent{CrediflowContentPublic}?
        }

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
