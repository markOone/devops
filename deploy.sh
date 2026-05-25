#!/bin/bash
cd /opt/mywebapp

git pull origin main

docker compose pull

docker compose up -d

echo "Розгортання завершено!"