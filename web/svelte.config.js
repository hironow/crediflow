import adapter from '@sveltejs/adapter-vercel';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	kit: {
		// nodejs20.x is the newest runtime adapter-vercel v3 (the last SvelteKit 1.x
		// compatible major) can emit; pinning it also keeps local builds working on
		// any Node version instead of deriving the runtime from process.version.
		adapter: adapter({ runtime: 'nodejs20.x' })
	}
};

export default config;
