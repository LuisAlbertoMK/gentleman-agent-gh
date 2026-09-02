const { test, expect } = require('@playwright/test');

test.describe('Gentleman Dashboard', () => {
  test('renders 4 cards, table, no console errors, sort toggles aria-sort', async ({ page }) => {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    page.on('pageerror', e => errors.push(String(e)));

    await page.goto('http://localhost:4173/', { waitUntil: 'networkidle' });

    // 4 cards
    const cards = page.locator('.card, [data-card], section.card');
    await expect(cards).toHaveCount(4);

    // each card non-empty
    for (let i = 0; i < 4; i++) {
      const txt = (await cards.nth(i).innerText()).trim();
      expect(txt.length).toBeGreaterThan(0);
    }

    // table has rows or no over-budget message
    const tbody = page.locator('#tbody');
    await expect(tbody).toBeVisible();
    const rows = page.locator('#tbody tr');
    const count = await rows.count();
    expect(count).toBeGreaterThanOrEqual(1);
    // if single row is "No over-budget" allow, else check first row has content
    const firstText = (await rows.first().innerText()).trim();
    expect(firstText.length).toBeGreaterThan(0);

    // no console errors
    expect(errors, `console errors: ${errors.join('; ')}`).toEqual([]);

    // Delta sort toggles aria-sort
    const deltaTh = page.locator('th[data-k="delta"]');
    await expect(deltaTh).toBeVisible();
    const before = await deltaTh.getAttribute('aria-sort');
    await deltaTh.click();
    const after = await deltaTh.getAttribute('aria-sort');
    expect(after).not.toBeNull();
    // click again toggles
    await deltaTh.click();
    const after2 = await deltaTh.getAttribute('aria-sort');
    expect(after2).not.toBe(after);
    // keyboard activation
    await deltaTh.focus();
    await page.keyboard.press('Enter');
    const afterKb = await deltaTh.getAttribute('aria-sort');
    expect(afterKb).not.toBeNull();
  });
});
