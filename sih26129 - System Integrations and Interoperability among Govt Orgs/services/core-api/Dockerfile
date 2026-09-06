FROM node:22-slim

# `nest start --watch` shells out to `ps` to manage its child process on restart —
# node:22-slim doesn't ship procps, so a file change crashes the container without it.
RUN apt-get update && apt-get install -y --no-install-recommends procps && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "run", "start:dev"]
