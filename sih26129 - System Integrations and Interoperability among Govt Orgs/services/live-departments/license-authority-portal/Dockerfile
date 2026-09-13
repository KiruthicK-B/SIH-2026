FROM node:22-slim

WORKDIR /app

COPY package.json ./
RUN npm install

COPY . .

EXPOSE 4302 5302

CMD ["node", "server.js"]
