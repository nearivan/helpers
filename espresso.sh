#!/bin/bash

# This file is sourced from the espressosystems/cape-ui repo
version: '2'
services:
  wallet:
    image: ghcr.io/espressosystems/cape-ui:release
    ports:
      - 8081:80
  wallet-api:
    image: ghcr.io/espressosystems/cape/wallet:release
    ports:
      - 60000:60000/tcp
    volumes:
      - espresso:/.espresso
volumes:
  espresso:
