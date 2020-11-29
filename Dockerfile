FROM ruby:2.7.2

ENV NODE_MAJOR_VERSION 12
ENV POSTGRES_VERSION 13

# install misc dependencies
RUN apt-get update && \
    apt-get install -y --quiet --no-install-recommends \
        git \
        build-essential \
        sqlite3 && \
    apt-get clean

# install imagemagick and image utilities
ADD https://raw.githubusercontent.com/discourse/discourse_docker/master/image/base/install-imagemagick /tmp/install-imagemagick
RUN chmod +x /tmp/install-imagemagick && \
    /tmp/install-imagemagick
RUN apt-get update && \
    apt-get install -y --quiet --no-install-recommends \
        advancecomp \
        gifsicle \
        jpegoptim \
        libjpeg-progs \
        optipng \
        pngcrush \
        pngquant \
        jhead && \
    apt-get clean

# install libraries for common gem dependencies
RUN apt-get update && \
    apt-get install -y --quiet --no-install-recommends \
        libxslt1-dev \
        libcurl4-openssl-dev \
        libksba8 \
        libksba-dev \
        libreadline-dev \
        libssl-dev \
        zlib1g-dev \
        libsnappy-dev && \
    apt-get clean

# install postgresql
RUN curl --silent --show-error --location https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt-get update && \
    apt-get install -y --quiet --no-install-recommends \
        postgresql-client-${POSTGRES_VERSION} && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# install node and yarn
RUN curl --silent --show-error --location https://deb.nodesource.com/setup_${NODE_MAJOR_VERSION}.x | bash - && \
    curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && \
    apt-get install -y --quiet --no-install-recommends \
        nodejs \
        yarn && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate --size 0 /var/log/*log

# install svgo
RUN npm install --global svgo

RUN git clone --depth 1 https://github.com/discourse/discourse.git /var/www/discourse

WORKDIR /var/www/discourse

RUN bundle install --jobs 6

RUN yarn install

CMD ["rails", "server", "-b", "0.0.0.0"]
