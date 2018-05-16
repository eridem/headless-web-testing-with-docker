const { Given, When, Then } = require('cucumber')
const { join } = require('path')
const { screenshotPath } = require('../../wdio.conf').config
const getScreenshotPath = (name) => join(screenshotPath, `${browser.desiredCapabilities.browserName}.${name}.png`)

Given('the search GitHub page loaded', async () => {
  await browser.url('https://github.com/search')
  await browser.saveScreenshot(getScreenshotPath('GIVEN'))
})

When('I introduce my search keywords for an user in the search box', async () => {
  await browser.setValue('[name=q]', 'user:eridem\n')
  await browser.saveScreenshot(getScreenshotPath('WHEN1'))
})

When('I press enter in the search box', async () => {
  await browser.click('.btn')
  await browser.saveScreenshot(getScreenshotPath('WHEN2'))
})

Then('I should obtain a list of repositories for that user', async () => {
  await browser.waitForExist('.codesearch-results')
  await browser.saveScreenshot(getScreenshotPath('THEN'))
})
