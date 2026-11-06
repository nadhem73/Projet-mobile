// Optional browser smoke test. Install playwright-core separately or point
// PLAYWRIGHT_CORE_PATH at its package directory. No real patient data is used.
const { chromium } = require(process.env.PLAYWRIGHT_CORE_PATH || 'playwright-core');
const http = require('node:http');
const fs = require('node:fs/promises');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '..');

(async () => {
  const requests = [];
  const server = http.createServer(async (req, res) => {
    const url = new URL(req.url, 'http://localhost');
    let file;
    if (url.pathname === '/') {
      res.setHeader('Content-Type', 'text/html');
      res.end('<!doctype html><html><body><script src="insurance_ocr.js"></script></body></html>');
      return;
    }
    if (url.pathname === '/insurance_ocr.js') file = path.join(root, 'web/insurance_ocr.js');
    else if (/^\/ocr\/[a-z0-9.-]+$/.test(url.pathname)) file = path.join(root, 'web', url.pathname);
    else if (url.pathname === '/assets/assets/tessdata/fra.traineddata') file = path.join(root, 'assets/tessdata/fra.traineddata');
    if (!file) { res.writeHead(404); res.end(); return; }
    try {
      const bytes = await fs.readFile(file);
      res.setHeader('Content-Type', file.endsWith('.js') ? 'application/javascript' : 'application/octet-stream');
      res.end(bytes);
    } catch { res.writeHead(404); res.end(); }
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  let browser;
  try {
    browser = await chromium.launch({ headless: true, channel: 'chrome' });
    const page = await browser.newPage();
    page.on('request', r => requests.push(r.url()));
    await page.goto(`http://127.0.0.1:${server.address().port}/`);
    const text = await page.evaluate(async () => {
      const canvas = document.createElement('canvas');
      canvas.width = 1200; canvas.height = 600;
      const ctx = canvas.getContext('2d');
      ctx.fillStyle = 'white'; ctx.fillRect(0, 0, 1200, 600);
      ctx.fillStyle = 'black'; ctx.font = '42px Arial';
      ['FACTURE DE SOINS', 'Date : 10/01/2025', 'Consultation : 100,000 TND', 'TOTAL TTC : 100,000 TND'].forEach((line, i) => ctx.fillText(line, 70, 100 + i * 100));
      return window._extractText(canvas.toDataURL(), {args: {preserve_interword_spaces: '1'}});
    });
    assert.match(text, /100[,.]000/);
    assert.match(text, /10\/01\/2025/);
    assert(requests.every(url => url.startsWith('http://127.0.0.1:') || url.startsWith('data:') || url.startsWith('blob:')), 'OCR made an external request');
    process.stdout.write(`Local OCR passed. Recognized:\n${text}\nNo external request.\n`);
  } finally {
    if (browser) await browser.close();
    await new Promise(resolve => server.close(resolve));
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
