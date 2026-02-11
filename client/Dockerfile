FROM node:20-alpine

WORKDIR /app

# Install Elm compiler with architecture detection
# Handles both x86_64 (amd64) and aarch64 (Raspberry Pi)
RUN apk add --no-cache curl tar && \
    if [ "$(uname -m)" = "aarch64" ]; then \
        curl -L https://github.com/punie/elm-linux-arm64/releases/download/0.19.1/elm-aarch64.tar.gz | tar xz && \
        chmod +x elm && \
        mv elm /usr/local/bin/; \
    else \
        curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz && \
        gunzip elm.gz && \
        chmod +x elm && \
        mv elm /usr/local/bin/; \
    fi

# Copy package files and install dependencies
# This layer will be cached unless package.json changes
COPY package.json package-lock.json ./
RUN npm install

# Default command to build the app
CMD ["npm", "run", "build"]
