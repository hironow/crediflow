import FungibleToken from "./FungibleToken.cdc"
import NonFungibleToken from "./core/NonFungibleToken.cdc"
import FungibleToken from "./core/FungibleToken.cdc"
import MetadataViews from "./core/MetadataViews.cdc"

pub contract Crediflow {
    // PATHS
    pub let CrediflowCreatorCollectionStoragePath: StoragePath
    pub let CrediflowCreatorCollectionPublicPath: PublicPath

    pub let CrediflowConsumerCollectionStoragePath: StoragePath
    pub let CrediflowConsumerCollectionPublicPath: PublicPath

    pub let CrediflowContainerStoragePath: StoragePath
    pub let CrediflowContainerPublicPath: PublicPath
    pub let CrediflowContainerPrivatePath: PrivatePath

    // EVENTS
    pub event ContractInitialized()

    // STATE
    pub var totalCreatorSupply: UInt64
    pub var totalConsumerSupply: UInt64
    pub var totalCrediflowContainer: UInt64

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

    // A Collection that claims all of the users Crediflow.
    pub resource CreatorCollection {}

    // A Collection that tips all of the users Crediflow.
    pub resource ConsumerCollection {}

    pub resource CrediflowContent {}

    // A "Collection" of CrediflowContent
    pub resource CrediflowContainer {
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

        pub fun borrowContentRef(contentId: UInt64): &CrediflowContent? {
            return &self.contentMap[contentId] as &CrediflowContent?
        }

        pub fun getIDs(): [UInt64] {
            return self.contentMap.keys
        }

        init() {
            self.contentMap = {}
        }

        destroy() {
            // すでにtip残高があれば失敗したい ※危険FTの burn に相当する
            destroy self.contentMap
        }
    }

    pub fun createEmptyCreatorCollection(): @CreatorCollection {
        return <- create CreatorCollection()
    }

    pub fun createEmptyConsumerCollection(): @ConsumerCollection {
        return <- create ConsumerCollection()
    }

    pub fun createEmptyCrediflowContainer(): @CrediflowContainer {
        return <- create CrediflowContainer()
    }

    init() {
        self.totalCreatorSupply = 0
        self.totalConsumerSupply = 0
        self.totalCrediflowContainer = 0
        emit ContractInitialized()

        self.CrediflowCreatorCollectionStoragePath = /storage/crediflowCreatorCollectionStoragePath
        self.CrediflowCreatorCollectionPublicPath = /public/crediflowCreatorCollectionPublicPath

        self.CrediflowConsumerCollectionStoragePath = /storage/crediflowConsumerCollectionStoragePath
        self.CrediflowConsumerCollectionPublicPath = /public/crediflowConsumerCollectionPublicPath

        self.CrediflowContainerStoragePath = /storage/crediflowContainerStoragePath
        self.CrediflowContainerPublicPath = /public/crediflowContainerPublicPath
        self.CrediflowContainerPrivatePath = /private/crediflowContainerPrivatePath
    }
}
