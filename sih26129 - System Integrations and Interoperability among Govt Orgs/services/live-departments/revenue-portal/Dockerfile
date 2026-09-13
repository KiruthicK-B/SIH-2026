FROM node:22-slim

WORKDIR /app

COPY package.json ./
RUN npm install

COPY . .

EXPOSE 4303 5303

CMD ["node", "server.js"]
