import { config } from '@onflow/config';

config({
	'app.detail.title': 'Crediflow', // Shows user what dapp is trying to connect
	'app.detail.icon': 'https://unavatar.io/twitter/hironow', // shows image to the user to display your dapp brand
	'accessNode.api': import.meta.env.VITE_ACCESS_NODE_API,
	'discovery.wallet': import.meta.env.VITE_DISCOVERY_WALLET,
	'0xProfile': import.meta.env.VITE_PROFILE_ADDRESS
});
