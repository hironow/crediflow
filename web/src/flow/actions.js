import { browser } from '$app/environment';

import * as fcl from '@onflow/fcl';
import './config';
import {
	user,
	contents,
	creatorNFTHoldersMap,
	admirerNFTHoldersMap,
	transactionStatus,
	transactionInProgress,
	txId
} from './stores';

if (browser) {
	// set Svelte $user store to currentUser,
	// so other components can access it
	fcl.currentUser.subscribe(user.set, []);
}

// Lifecycle FCL Auth functions
export const unauthenticate = () => fcl.unauthenticate();
export const logIn = () => fcl.logIn();
export const signUp = () => fcl.signUp();

export const createContent = async (name, creatorAddressList, creatorRoleList) => {
	let transactionId = false;
	initTransactionState();

	try {
		transactionId = await fcl.mutate({
			cadence: `
        import Crediflow from 0xCrediflow

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
      `,
			args: (arg, t) => [
				arg(name, t.String),
				arg(creatorAddressList, t.Array(t.Address)),
				arg(creatorRoleList, t.Array(t.String))
			],
			payer: fcl.authz,
			proposer: fcl.authz,
			authorizations: [fcl.authz],
			limit: 500
		});

		txId.set(transactionId);

		fcl.tx(transactionId).subscribe((res) => {
			transactionStatus.set(res.status);
			if (res.status === 4) {
				setTimeout(() => transactionInProgress.set(false), 2000);
			}
		});
	} catch (e) {
		transactionStatus.set(99);
		console.log(e);
	}
};

export const getAllContent = async (host) => {
	let queryResult = false;

	try {
		queryResult = await fcl.query({
			cadence: `
        import Crediflow from 0xCrediflow

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
      `,
			args: (arg, t) => [arg(host, t.Address)]
		});
		// obj -> list
		console.log(Object.values(queryResult));
		contents.set(Object.values(queryResult));
	} catch (e) {
		console.log(e);
	}
};

export const getNFTHolder = async (contentId, host) => {
	let queryResult = false;

	try {
		queryResult = await fcl.query({
			cadence: `
        import Crediflow from 0xCrediflow

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
      `,
			args: (arg, t) => [arg(contentId, t.UInt64), arg(host, t.Address)]
		});
		// obj -> list
		// 1: id, 2: name, 3: host, 4: creatorHolders, 5: admirerHolders
		// console.log(Object.values(queryResult));
		let creatorNFTHolders = Object.values(queryResult)[3];
		let admirerNFTHolders = Object.values(queryResult)[4];
		console.log(creatorNFTHolders);
		console.log(admirerNFTHolders);
		creatorNFTHoldersMap.update((state) => {
			return { ...state, [contentId]: creatorNFTHolders };
		});
		admirerNFTHoldersMap.update((state) => {
			return { ...state, [contentId]: admirerNFTHolders };
		});
	} catch (e) {
		console.log(e);
	}
};

export const mintCreatorNFT = async (contentId, host) => {
	initTransactionState();
	try {
		const transactionId = await fcl.mutate({
			cadence: `
        import FlowToken from 0xFlowToken
        import FungibleToken from 0xFungibleToken
        import NonFungibleToken from 0xNonFungibleToken
        import Crediflow from 0xCrediflow

        transaction(contentId: UInt64, host: Address) {
          // REFS
          let Content: &Crediflow.CrediflowContent{Crediflow.CrediflowContentPublic}
          let CreatorCollection: &Crediflow.Collection

          // single signer
          prepare(acct: AuthAccount) {
              // SETUP Crediflow NFT Collection for Creator
              if acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) == nil {
                  acct.save(<-Crediflow.createEmptyCollection(), to: Crediflow.CrediflowCollectionStoragePath)
                  acct.link<&Crediflow.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowCollectionPublicPath, target: Crediflow.CrediflowCollectionStoragePath)
              }

              // Get Crediflow Content from the host
              let Container = getAccount(host).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
                  ?? panic("Could not borrow the public CrediflowContainer from the host.")
              self.Content = Container.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist.")
              self.CreatorCollection = acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) ?? panic("Could not get the Collection from the signer.")
          }

          execute {
              self.Content.mintCreator(recipient: self.CreatorCollection)
              log("Minted a new Crediflow Creator NFT for the signer.")
          }
        }
      `,
			args: (arg, t) => [arg(contentId, t.UInt64), arg(host, t.Address)],
			payer: fcl.authz,
			proposer: fcl.authz,
			authorizations: [fcl.authz],
			limit: 500
		});

		txId.set(transactionId);

		fcl.tx(transactionId).subscribe((res) => {
			transactionStatus.set(res.status);
			if (res.status === 4) {
				setTimeout(() => transactionInProgress.set(false), 2000);
			}
		});
	} catch (e) {
		console.log(e);
		transactionStatus.set(99);
	}
};

export const mintAdmirerNFT = async (contentId, host) => {
	initTransactionState();
	try {
		const transactionId = await fcl.mutate({
			cadence: `
        import FlowToken from 0xFlowToken
        import FungibleToken from 0xFungibleToken
        import NonFungibleToken from 0xNonFungibleToken
        import Crediflow from 0xCrediflow

        transaction(contentId: UInt64, host: Address) {
          // REFS
          let Content: &Crediflow.CrediflowContent{Crediflow.CrediflowContentPublic}
          let AdmirerCollection: &Crediflow.Collection

          // single signer
          prepare(acct: AuthAccount) {
              // SETUP Crediflow NFT Collection for Admirer
              if acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) == nil {
                  acct.save(<-Crediflow.createEmptyCollection(), to: Crediflow.CrediflowCollectionStoragePath)
                  acct.link<&Crediflow.Collection{NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic}>(Crediflow.CrediflowCollectionPublicPath, target: Crediflow.CrediflowCollectionStoragePath)
              }

              // Get Crediflow Content from the host
              let Container = getAccount(host).getCapability(Crediflow.CrediflowContainerPublicPath).borrow<&Crediflow.CrediflowContainer{Crediflow.CrediflowContainerPublic}>()
                  ?? panic("Could not borrow the public CrediflowContainer from the host.")
              self.Content = Container.borrowPublicContentRef(contentId: contentId) ?? panic("This content does not exist.")
              self.AdmirerCollection = acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath) ?? panic("Could not get the Collection from the signer.")
          }

          execute {
              self.Content.mintAdmirer(recipient: self.AdmirerCollection)
              log("Minted a new Crediflow Admirer NFT for the signer.")
          }
        }
      `,
			args: (arg, t) => [arg(contentId, t.UInt64), arg(host, t.Address)],
			payer: fcl.authz,
			proposer: fcl.authz,
			authorizations: [fcl.authz],
			limit: 500
		});

		txId.set(transactionId);

		fcl.tx(transactionId).subscribe((res) => {
			transactionStatus.set(res.status);
			if (res.status === 4) {
				setTimeout(() => transactionInProgress.set(false), 2000);
			}
		});
	} catch (e) {
		console.log(e);
		transactionStatus.set(99);
	}
};

export const executeClaim = async (nftId) => {
	initTransactionState();
	try {
		const transactionId = await fcl.mutate({
			cadence: `
        import FlowToken from 0xFlowToken
        import FungibleToken from 0xFungibleToken
        import NonFungibleToken from 0xNonFungibleToken
        import Crediflow from 0xCrediflow

        transaction(nftId: UInt64) {
          // REFS
          let CrediflowNFT: &Crediflow.NFT{Crediflow.Claimer} // as a creator nft functionality

          let FlowTokenVault: &FlowToken.Vault

          // single signer
          prepare(acct: AuthAccount) {
              // check FT prepared for tip
              self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
                                  ?? panic("Could not borrow the FlowToken.Vault from the signer.")
              // use own Crediflow NFT
              let CrediflowCollection = acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath)
                                  ?? panic("Could not borrow the Crediflow Collection from the signer.")
              self.CrediflowNFT = CrediflowCollection.borrowCrediflowNFT(id: nftId) ?? panic("Could not borrow the Crediflow NFT from the signer.")
          }

          execute {
              self.FlowTokenVault.deposit(from: <- self.CrediflowNFT.claim())
              log("Claimed through Crediflow NFT!")
          }
        }
      `,
			args: (arg, t) => [arg(nftId, t.UInt64)],
			payer: fcl.authz,
			proposer: fcl.authz,
			authorizations: [fcl.authz],
			limit: 500
		});

		txId.set(transactionId);

		fcl.tx(transactionId).subscribe((res) => {
			transactionStatus.set(res.status);
			if (res.status === 4) {
				setTimeout(() => transactionInProgress.set(false), 2000);
			}
		});
	} catch (e) {
		console.log(e);
		transactionStatus.set(99);
	}
};

export const executeTip = async (nftId, tipAmount) => {
	initTransactionState();
	try {
		const transactionId = await fcl.mutate({
			cadence: `
        import FlowToken from 0xFlowToken
        import FungibleToken from 0xFungibleToken
        import NonFungibleToken from 0xNonFungibleToken
        import Crediflow from 0xCrediflow

        transaction(nftId: UInt64, tipAmount: UFix64) {
          // REFS
          let CrediflowNFT: &Crediflow.NFT{Crediflow.Tipper} // as an admirer nft functionality

          let FlowTokenVault: &FlowToken.Vault

          // single signer
          prepare(acct: AuthAccount) {
              // check FT prepared for tip
              self.FlowTokenVault = acct.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
                                  ?? panic("Could not borrow the FlowToken.Vault from the signer.")
              // use own Crediflow NFT
              let CrediflowCollection = acct.borrow<&Crediflow.Collection>(from: Crediflow.CrediflowCollectionStoragePath)
                                  ?? panic("Could not borrow the Crediflow Collection from the signer.")
              self.CrediflowNFT = CrediflowCollection.borrowCrediflowNFT(id: nftId) ?? panic("Could not borrow the Crediflow NFT from the signer.")
          }

          execute {
              self.CrediflowNFT.tip(token: <- self.FlowTokenVault.withdraw(amount: tipAmount))
              log("Tipped through Crediflow NFT!")
          }
        }
      `,
			args: (arg, t) => [arg(nftId, t.UInt64), arg(tipAmount.toFixed(8), t.UFix64)],
			payer: fcl.authz,
			proposer: fcl.authz,
			authorizations: [fcl.authz],
			limit: 500
		});

		txId.set(transactionId);

		fcl.tx(transactionId).subscribe((res) => {
			transactionStatus.set(res.status);
			if (res.status === 4) {
				setTimeout(() => transactionInProgress.set(false), 2000);
			}
		});
	} catch (e) {
		console.log(e);
		transactionStatus.set(99);
	}
};

function initTransactionState() {
	txId.set(false);
	transactionInProgress.set(true);
	transactionStatus.set(-1);
}
