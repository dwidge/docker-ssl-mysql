# docker-sync

Setup server with docker compose over ssh. Syncs parent folder on server. Requires `./.env`.

## Guide

### Setup

```
$
mkdir project && cd project
git clone https://github.com/USER/PROJECT-compose.git
git clone https://github.com/USER/PROJECT-main.git
git clone https://github.com/USER/PROJECT-console.git
git clone https://github.com/USER/PROJECT-api.git
cd *-compose
touch .env
```

Copy your env file to `/*-compose/.env`. It must look like `/*-compose/sample.env`.

### Upload and rebuild

```
cd /*-compose
chmod +x sync.sh
./sync.sh
```

### View log

```
ssh root@myserver.com
cd project/*-compose
export COMPOSE_PROJECT_NAME=dev
docker compose logs -f
```

### Nginx/Certbot issues

```
ssh root@myserver.com
cd project/*-compose
export COMPOSE_PROJECT_NAME=dev
docker compose down
docker volume rm $(docker volume ls | grep -v "_db" | awk 'NR>1 {print $2}')
docker compose up -d
```

## Setup users

### Generate SSH keys

```
ssh-keygen
```

Put public key `~/.ssh/rsa_id.pub` in digital ocean/AWS.  
Uses private key in `~/.ssh/rsa_id` .  
Only looks for `~/.ssh/rsa_id` by default.

### Add user with docker group

```
export SERVER_HOST=root@myserver.com
ssh $SERVER_HOST
adduser user
usermod -aG docker user
rsync --archive --chown=user:user ~/.ssh /home/user
rsync --archive --chown=user:user ~/.docker /home/user
exit
```

### Login user

```
export SERVER_HOST=user@myserver.com
ssh $SERVER_HOST
```

## Fetch code

### Install

```
mkdir project && cd project
git clone https://github.com/USER/PROJECT-compose.git
git clone https://github.com/USER/PROJECT-main.git
git clone https://github.com/USER/PROJECT-console.git
git clone https://github.com/USER/PROJECT-api.git
cd *-compose
touch .env
```

### Update

```
cd project
(cd *-compose; git pull)
(cd *-main; git pull)
(cd *-api; git pull)
```

## Copy to remote

### Unreliable

```
export SERVER_HOST=user@myserver.com
export COMPOSE_PROJECT_NAME=dev
cd ..
DOCKER_HOST="ssh://$SERVER_HOST" docker compose up --build --remove-orphans
```

### Good

```
export SERVER_HOST=user@myserver.com
export RSYNC_FILTER=(--filter=":e- .dockerignore" --filter "- .git/" --filter "- node_modules/")
cd ..
rsync --delete-after "${RSYNC_FILTER[@]}" -v -a . $SERVER_HOST:~/project
rsync --delete-after -v -a ./*compose/.env $SERVER_HOST:~/project/*compose/
```

## Control remote

COMPOSE_PROJECT_NAME is a docker env.

### Login

```
export SERVER_HOST=user@myserver.com
ssh $SERVER_HOST
export COMPOSE_PROJECT_NAME=dev
cd /*-compose
```

### Start/restart all

```
docker compose up -d --build --remove-orphans
```

### Multi vCPU

```
docker compose up -d --build --remove-orphans --scale api=2 --scale main=2
```

### Stop all

```
docker compose down
```

### Delete all ssl certificates, mysqldb, nginx cache

```
docker compose down --volumes
```

### Follow live logs

```
docker compose logs -f
```

# 3rd party license

evgeniy-khist/letsencrypt-docker-compose  
Nginx and Let’s Encrypt with Docker Compose in less than 3 minutes  
Distributed under the Apache License, Version 2.0.

dwidge/docker-sync  
Copyright DWJ 2023  
Distributed under the Boost Software License, Version 1.0.  
https://www.boost.org/LICENSE_1_0.txt
