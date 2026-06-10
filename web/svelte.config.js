import adapter from '@sveltejs/adapter-vercel';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		// Pin the function runtime instead of deriving it from the local Node
		// version at build time; 24.x is Vercel's current default LTS.
		adapter: adapter({ runtime: 'nodejs24.x' })
	}
};

export default config;
