# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t mb .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name mb mb

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.4.5
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build gems and Node.js
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config curl && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Install Node.js dependencies
RUN npm install

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Remove any existing TailwindCSS build files
RUN rm -f app/assets/builds/tailwind.css public/assets/tailwind*.css

# Download and use TailwindCSS standalone binary for v4 compatibility
RUN curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-linux-x64 && \
    chmod +x tailwindcss-linux-x64 && \
    echo "=== Building TailwindCSS ===" && \
    ./tailwindcss-linux-x64 -i app/assets/tailwind/application.css -o app/assets/builds/tailwind.css && \
    echo "=== my-12 class check ===" && \
    grep -c "my-12" app/assets/builds/tailwind.css && echo "my-12 found!" || echo "my-12 not found"

# Build assets normally - TailwindCSS gem is disabled in production
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Debug: Check what TailwindCSS files exist after asset compilation
RUN echo "=== Available TailwindCSS files ===" && ls -la public/assets/tailwind* || echo "No tailwind files found"
RUN echo "=== Node.js built TailwindCSS info ===" && ls -la app/assets/builds/tailwind.css && echo "Size: $(wc -c < app/assets/builds/tailwind.css) bytes" && echo "my-12 class count: $(grep -c 'my-12' app/assets/builds/tailwind.css || echo '0')"




# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
