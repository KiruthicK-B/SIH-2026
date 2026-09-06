FROM node:22-slim
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
EXPOSE 4003
CMD ["node", "index.js"]
