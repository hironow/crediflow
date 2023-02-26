import { config } from '@onflow/config';

config({
	'app.detail.title': 'Crediflow', // Shows user what dapp is trying to connect
	'app.detail.icon': 'https://unavatar.io/github/hironow', // shows image to the user to display your dapp brand
	'accessNode.api': import.meta.env.VITE_ACCESS_NODE_API,
	'discovery.wallet': import.meta.env.VITE_DISCOVERY_WALLET,
	'0xFlowToken': import.meta.env.VITE_FLOW_ADDRESS,
	'0xFungibleToken': import.meta.env.VITE_FT_ADDRESS,
	'0xNonFungibleToken': import.meta.env.VITE_NFT_ADDRESS,
	'0xMetadataViews': import.meta.env.VITE_METAVIEW_ADDRESS,
	'0xCrediflow': import.meta.env.VITE_CREDIFLOW_ADDRESS
});
