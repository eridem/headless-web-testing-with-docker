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
