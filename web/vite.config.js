// vite.config.js
import { sveltekit } from '@sveltejs/kit/vite';
import { nodePolyfills } from 'vite-plugin-node-polyfills';
import inject from '@rollup/plugin-inject';

/** @type {import('vite').UserConfig} */
const config = {
	define: {
		global: 'globalThis'
	},
	plugins: [
		nodePolyfills({
			// Whether to polyfill `node:` protocol imports.
			protocolImports: true,
			// Exclude the `module` builtin from polyfilling. Under Vite 8's rolldown
			// bundler the generated runtime emits `import { createRequire } from
			// 'node:module'`; polyfilling `module` maps it to an empty mock with no
			// `createRequire` export, which breaks the build. The browser bundle does
			// not use `node:module` itself, so excluding it is safe.
			exclude: ['module']
		}),
		sveltekit()
	],
	resolve: {
		alias: {
			'node-fetch': './node_modules/node-fetch/browser.js'
		}
	},
	build: {
		rollupOptions: {
			plugins: [inject({ Buffer: ['buffer', 'Buffer'] })]
		}
	},
	test: {
		include: ['src/**/*.{test,spec}.{js,ts}']
	}
};

export default config;
