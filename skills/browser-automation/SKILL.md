---
name: browser-automation
description: Web browser automation and testing
license: MIT
metadata:
  audience: developers
  workflow: testing
---

# Browser Automation Skill

Control browsers for automation, testing, and scraping.

## Capabilities
- Start headless browser
- Navigate to URLs
- Fill forms and click
- Capture screenshots
- Extract data (DOM, JSON)
- Handle iframes/shadows

## Tools
- Playwright (recommended)
- Puppeteer
- Selenium

## Usage
```javascript
// Playwright example
const { chromium } = require('playwright');
const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('https://example.com');
const title = await page.title();
await browser.close();
```

## Output Format
```markdown
## Browser Automation Result

### Actions Performed
- Navigated to [URL]
- Filled form: [inputs]
- Clicked: [buttons]

### Extracted Data
```
[data]
```

### Screenshots
[saved to location]
```