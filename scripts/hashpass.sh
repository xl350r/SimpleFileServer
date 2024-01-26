#!/bin/sh
echo -n "$1" | openssl sha512 | cut -d " " -f2