FROM node:18 AS build

WORKDIR /app

ARG REACT_APP_API_URL
ARG REACT_APP_API_PUBLIC_URL
ARG REACT_APP_SOCKET_URL
ARG REACT_APP_ASSISTANT_URL

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

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
