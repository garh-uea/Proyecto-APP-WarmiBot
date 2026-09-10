const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const root = 'C:/WarmiBot';
  const browser = await chromium.launch({
    channel: 'msedge',
    headless: true,
    args: ['--disable-gpu', '--disable-software-rasterizer']
  });
  const page = await browser.newPage({ viewport: { width: 1800, height: 700 }, deviceScaleFactor: 1 });
  const shots = [
    ['01_storage', 500], ['02_constraints', 720], ['03_indexes_trigger', 590],
    ['04_dml', 690], ['05_windows_datafiles', 650], ['06_docker_runtime', 440],
    ['07_empleados_structure', 540]
  ];
  for (const [n, height] of shots) {
    await page.setViewportSize({ width: 1800, height });
    await page.goto(`file:///${root}/evidence/html/evidence_${n}.html`, { waitUntil: 'load' });
    await page.screenshot({ path: path.join(root, 'evidence', 'png', `evidence_${n}.png`), fullPage: false });
  }
  await browser.close();
})();
