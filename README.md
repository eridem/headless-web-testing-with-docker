# Set up a headless web testing project with Docker, Chrome and Firefox

This tutorial will help you to set up a headless web testing project with Docker. Some of the advantages to work with Docker are:

- **Continuous Integration**: it is easy to integrate with CI tools due the Docker images will have all components the testing needs without the need to set up or install tools.
- **Easy to work within your team**: stop asking your mates to install the `Foo` and the `Bar` tools to make it work :-)

This tutorial will not explain in detail every step, but it will show you how it was incrementally built.

## Prerequisites

- [Docker Community Edition](https://store.docker.com/search?type=edition&offering=community)

The following dependencies are only needed when setting up the project (e.g. using this tutorial). As soon the project is already set up, you do not need to request those dependencies to the rest of the developers (that's the magic of Docker). As well, you do not need them in CI machines:

- [Node.js and NPM](https://nodejs.org/en/)
- [Java](http://www.oracle.com/technetwork/java/javase/downloads/index.html) 

## Tired of reading?

If you want to skip the magic 🌟 of this article and start experimenting directly with the code 🔬, use the following commands:

```sh
# Clone project
git clone 'git@github.com:eridem/headless-web-testing-with-docker.git' 'my-testing-project'

cd 'my-testing-project'

# Build image
docker build . -t 'my-testing'

# Run tests (if Windows, use Powershell)
docker run -v "$(pwd)/output:/workdir/output" 'my-testing'
```

## Contents

- [Set up the project](#set-up-the-project)
- [Running the tests with Docker](#running-the-tests-with-docker)
- [Create an empty feature](#create-an-empty-feature)
- [Test a website](#test-a-website)

## Set up the project

Create the Node.js application:

- Open a terminal and write:

  ```sh
  # Initialize the project:
  npm init

  # Answer the questions as following
  package name:     (headless-web-testing-with-docker)
  version:          (1.0.0)
  description:      My awesome testing
  entry point:      (index.js)
  test command:     wdio
  git repository:   eridem/headless-web-testing-with-docker
  keywords:         test, web
  author:           Miguel Angel Dominguez Coloma
  license:          (ISC) MIT

  # Install webdriverio
  npm install webdriverio --save

  # Install cucumber reporter
  npm install wdio-spec-reporter --save
  ```

- Configure WebDriverIo executing the command:

  ```sh
  npm test -- config
  ```

  Then answer the questions as follows:

  ```plaintext
  ? Where do you want to execute your tests?                              On my local machine
  ? Which framework do you want to use?                                   cucumber
  ? Shall I install the framework adapter for you?                        Yes
  ? Where are your feature files located?                                 ./features/**/*.feature
  ? Where are your step definitions located?                              ./features/**/*.js
  ? Which reporter do you want to use?                                    spec, junit
  ? Shall I install the reporter library for you?                         Yes
  ? Do you want to add a service to your test setup?                      selenium-standalone
  ? Shall I install the services for you?                                 Yes
  ? Level of logging verbosity                                            silent
  ? In which directory should screenshots gets saved if a command fails?  ./output
  ? What is the base url?                                                 http://localhost
  ```

- Modify the file `wdio.conf.js`, replacing the section `capabilities` where we will specify the use of the Chrome and Firefox browsers for our tests:

  ```javascript
  ...
      capabilities: [
        {
            'browserName': 'chrome',
            'chromeOptions': {
                args: ['--headless', '--no-sandbox']
            }
        },
        {
            maxInstances: 5,
            browserName: 'firefox',
            "moz:firefoxOptions": {
                args: ['-headless']
            }
        }
    ],
  ...
  ```

- Optionally, but recommended, modify the file `wdio.conf.js`, appending at the end of the `config` section the following entry to save a file for the `junit` reports that you may want to use.

  ```javascript
  ...
      reporterOptions: {
        junit: {
            outputDir: './output/',
            outputFileFormat: function(opts) { // optional
                return `${opts.capabilities}.results-${opts.cid}.xml`
            }
        }
    },
  ...
  ```

Create _Docker_ files:

- Add the file `.dockerignore` with the content:

  ```sh
  .git

  # Dependencies
  .node_modules

  # Logs
  npm-debug.log*
  yarn-debug.log*
  yarn-error.log*

  # Output
  output/*
  ```

- Create the file `Dockerfile` with the content:

  ```Dockerfile
  FROM ubuntu:18.04

  # Install machine dependencies
  RUN apt update \
    && apt install -y unzip curl wget git make build-essential g++ openjdk-8-jdk \
    && curl -sL https://deb.nodesource.com/setup_8.x | bash - \
    && apt update \
    && apt-get install -y nodejs \
    && echo 'deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main' | tee /etc/apt/sources.list.d/google-chrome.list \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && apt update \
    && apt install -y google-chrome-stable firefox

  # Working directory
  RUN mkdir -p /workdir/output
  WORKDIR /workdir

  # Install dependencies if any change
  COPY package.json package-lock.json ./
  RUN npm install

  # Copy tests
  COPY . ./

  # Execute tests
  ENTRYPOINT ["npm", "test"]
  ```

Create the following structure to create our tests later and the output reports:

  ```plaintext
    + features/
    + output/
  ```

## Running the tests with Docker

Using _Docker_ you do not need to install anything. You can run the following commands to run the tests:

```sh
# Build image
docker build . -t 'my-testing'

# Run tests (if Windows, use Powershell)
docker run -v "$(pwd)/output:/workdir/output" 'my-testing'
```

At this moment, it should display only empty results because we do not have tests:

```plaintext
pattern ./features/**/*.feature did not match any file
pattern ./features/**/*.feature did not match any file
```

## Create simple feature

- Create the following file structure:
  
  ```sh
  + features/
  + features/internet-search/
  + features/internet-search/main.feature
  + features/internet-search/main.js
  ```

- Add the following content to the file `features/internet-search/main.feature`:

  ```gherkin
  Feature: GitHub user search
    In order to find the repositories of an user in GitHub
    As user
    I want to have a search box to introduce my keywords

    Scenario: can search using my keywords
      Given the search GitHub page loaded
      When I introduce my search keywords for an user in the search box
      And I press enter in the search box
      Then I should obtain a list of repositories for that user
  ```

- Add the following content to the file `features/internet-search/main.js`:

  ```javascript
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
  ```

  _NOTE: the code example should not create screenshots for each step, but we will do like that to test our example_. 

- Now that we have one feature, let's run the tests again with the commands:

  ```sh
  # Build image
  docker build . -t 'my-testing'

  # Run tests (if Windows, use Powershell)
  docker run -v "$(pwd)/output:/workdir/output" 'my-testing'
  ```

Your terminal show show something like:

  ```plaintext
  ------------------------------------------------------------------
  [chrome #0-0] Session ID: ad6c947b7dfbe912442fc6a60713d577
  [chrome #0-0] Spec: /workdir/features/internet-search/main.feature
  [chrome #0-0] Running: chrome
  [chrome #0-0]
  [chrome #0-0] GitHub user search
  [chrome #0-0]
  [chrome #0-0]     can search using my keywords
  [chrome #0-0]       ✓ the search GitHub page loaded
  [chrome #0-0]       ✓ I introduce my search keywords for an user in the search box
  [chrome #0-0]       ✓ I press enter in the search box
  [chrome #0-0]       ✓ I should obtain a list of repositories for that user
  [chrome #0-0]
  [chrome #0-0]
  [chrome #0-0] 4 passing (4s)
  [chrome #0-0]

  ------------------------------------------------------------------
  [firefox #1-0] Session ID: 32d70e05-6a59-4de4-bf96-b62f90019c9e
  [firefox #1-0] Spec: /workdir/features/internet-search/main.feature
  [firefox #1-0] Running: firefox
  [firefox #1-0]
  [firefox #1-0] GitHub user search
  [firefox #1-0]
  [firefox #1-0]     can search using my keywords
  [firefox #1-0]       ✓ the search GitHub page loaded
  [firefox #1-0]       ✓ I introduce my search keywords for an user in the search box
  [firefox #1-0]       ✓ I press enter in the search box
  [firefox #1-0]       ✓ I should obtain a list of repositories for that user
  [firefox #1-0]
  [firefox #1-0]
  [firefox #1-0] 4 passing (8s)
  [firefox #1-0]

  ==================================================================
  Number of specs: 2

  8 passing (12.20s)

  Wrote xunit report "chrome.results-0-0.xml" to [./output/].
  Wrote xunit report "firefox.results-1-0.xml" to [./output/].
  ```

The folder `output` should be filled with the results of your tests. You can use these output files in your CI tool or local read.