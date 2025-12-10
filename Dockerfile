FROM ruby:3.4.2

RUN apt-get update && apt-get install -y \
  chromium \
  chromium-driver \
  curl \
  libappindicator3-1 \
  libasound2 \
  libatk-bridge2.0-0 \
  libatk1.0-0 \
  libatspi2.0-0 \
  libcups2 \
  libdbus-1-3 \
  libgbm1 \
  libgtk-3-0 \
  libnspr4 \
  libnss3 \
  libvulkan1 \
  libx11-xcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxfixes3 \
  libxi6 \
  libxrandr2 \
  libxss1 \
  libxtst6 \
  xdg-utils

# Install Node, Yarn (but don't set version berry yet - that creates package.json in cwd)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh \
  && bash nodesource_setup.sh \
  && apt-get install -y nodejs \
  && npm i -g corepack \
  && corepack enable \
  && corepack prepare yarn

# Setup project home directory
RUN mkdir /app
WORKDIR /app

# Now set yarn version in /app to avoid creating /package.json at root
RUN yarn set version berry \
  && yarn config set --home enableTelemetry 0

# Add Gemfile and cache results of bundle install
COPY .ruby-version grpc-web.gemspec Gemfile Gemfile.lock /app/
COPY lib/grpc_web/version.rb /app/lib/grpc_web/

RUN gem install bundler \
 && bundle update -j4 --retry 3 \
 # Remove unneeded files (cached *.gem, *.o, *.c)
 && rm -rf /usr/local/bundle/cache/*.gem
