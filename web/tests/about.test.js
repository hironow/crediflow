import { expect, test } from '@playwright/test';

test('about page has expected h1', async ({ page }) => {
	await page.goto('/about');
	expect(await page.textContent('h1')).toBe('About');
});

test('repository link has an accessible name', async ({ page }) => {
	await page.goto('/about');
	await expect(page.getByRole('link', { name: 'Crediflow source on GitHub' })).toHaveAttribute(
		'href',
		'https://github.com/hironow/crediflow',
		{ timeout: 2000 }
	);
});
