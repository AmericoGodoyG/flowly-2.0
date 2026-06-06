FROM node:18 AS build

WORKDIR /app

ARG REACT_APP_API_URL=https://flowly-api-backend-646126851973.southamerica-east1.run.app/api
ARG REACT_APP_API_PUBLIC_URL=https://flowly-api-backend-646126851973.southamerica-east1.run.app
ARG REACT_APP_SOCKET_URL=https://flowly-api-backend-646126851973.southamerica-east1.run.app
ARG REACT_APP_ASSISTANT_URL=https://flowly-assistente-voz-646126851973.southamerica-east1.run.app

ENV REACT_APP_API_URL=$REACT_APP_API_URL
ENV REACT_APP_API_PUBLIC_URL=$REACT_APP_API_PUBLIC_URL
ENV REACT_APP_SOCKET_URL=$REACT_APP_SOCKET_URL
ENV REACT_APP_ASSISTANT_URL=$REACT_APP_ASSISTANT_URL

RUN test -n "$REACT_APP_API_URL" || (echo "REACT_APP_API_URL precisa ser informado no build" && exit 1)
RUN test -n "$REACT_APP_API_PUBLIC_URL" || (echo "REACT_APP_API_PUBLIC_URL precisa ser informado no build" && exit 1)
RUN test -n "$REACT_APP_SOCKET_URL" || (echo "REACT_APP_SOCKET_URL precisa ser informado no build" && exit 1)
RUN test -n "$REACT_APP_ASSISTANT_URL" || (echo "REACT_APP_ASSISTANT_URL precisa ser informado no build" && exit 1)

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM nginx:stable-alpine

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
