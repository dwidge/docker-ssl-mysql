#!/bin/bash

SERVER_HOST="myserver.com"
SERVER_NAME="dev"
ROOTDIR="project"
COMPOSEDIR="compose"
dirs=( "../compose" "../api" "../console" "../main" )
files=( "../compose/.env" "../compose/docker-compose.yaml" "../api/package.json" "../console/package.json" "../main/package.json" )

# Copyright DWJ 2023.
# Distributed under the Boost Software License, Version 1.0.
# https://www.boost.org/LICENSE_1_0.txt

RED='\033[0;31m'
GREEN='\033[0;32m'
BROWN='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BROWN}Sync... $1${NC}"
SERVER_HOST=${1}

echo -e "${BROWN}Checking env...${NC}"
echo -e "SERVER_HOST=${SERVER_HOST}"
echo -e "SERVER_NAME=${SERVER_NAME}"
echo -e "ROOTDIR=${ROOTDIR}"
echo -e "COMPOSEDIR=${COMPOSEDIR}"
echo -e "${GREEN}All env found.${NC}"

echo -e "${BROWN}Checking ssh...${NC}"
users=( "user" "root" )
for s in "${users[@]}"
do
status=$(ssh -o BatchMode=yes -o ConnectTimeout=2 $s@$SERVER_HOST echo ok 2>&1)
if [[ $status == ok ]] ; then
  echo "$s@$SERVER_HOST accepted."
  SERVER_USER="$s"
  break
else
  echo -e "$s@$SERVER_HOST failed."
fi
done
if [ -z "$SERVER_USER" ]
then
  echo -e "${RED}Failed ssh.${NC}"
  echo -e "Try ssh root@$SERVER_HOST manually to accept fingerprint?"
  exit 1
fi
SERVER_SSH=$SERVER_USER@$SERVER_HOST
echo -e "${GREEN}Working ssh found.${NC}"

echo -e "${BROWN}Checking vhosts...${NC}"
(cd nginx-ssl/vhosts && mv * $SERVER_HOST.conf) || (echo -e "One and only one vhost should be here."; exit 1)
echo "$SERVER_HOST.conf found."
echo -e "${GREEN}Single vhost found and renamed.${NC}"

echo -e "${BROWN}Checking dirs...${NC}"
for s in "${dirs[@]}"
do
if [ ! -d "$s" ]; then
  echo -e "${RED}$s does not exist.${NC}"
  exit 1
else
  echo "$s found."
fi
done
echo -e "${GREEN}All dirs found.${NC}"

echo -e "${BROWN}Checking files...${NC}"
for s in "${files[@]}"
do
if [ ! -f "$s" ]; then
  echo -e "${RED}$s does not exist.${NC}"
  exit 1
else
  echo "$s found."
fi
done
echo -e "${GREEN}All files found.${NC}"

export RSYNC_FILTER=(--filter=":e- .dockerignore" --filter "- .git/" --filter "- node_modules/")

echo -e "${BROWN}Sending files to $SERVER_SSH...${NC}"
rsync --delete-after "${RSYNC_FILTER[@]}" -v -a .. "$SERVER_SSH:~/$ROOTDIR/"
echo -e "${GREEN}All files sent.${NC}"

echo -e "${BROWN}Sending commands to $SERVER_SSH...${NC}"
ssh $SERVER_SSH << EOF
  export COMPOSE_PROJECT_NAME=$SERVER_NAME
  export DOMAINS=$SERVER_HOST
  export PUBLIC_HOST=https://$SERVER_HOST
  cd $ROOTDIR/$COMPOSEDIR
  docker compose down
  docker compose up -d --build --remove-orphans
EOF
echo -e "${GREEN}All commands sent.${NC}"
