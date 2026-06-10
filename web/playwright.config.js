/** @type {import('@playwright/test').PlaywrightTestConfig} */
const config = {
	webServer: {
		command: 'bun run build && bun run preview',
		port: 4173
	},
	testDir: 'tests'
};

export default config;
