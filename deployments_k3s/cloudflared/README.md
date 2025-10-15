# Create a new tunnel
To create a new tunnel we do this via creating the config in the cli.

## install
https://community.cloudflare.com/t/installing-cloudflare-tunnel-on-ubuntu-server/552018 -> https://pkg.cloudflare.com/index.html

## login and create tunnel
`cloudflared tunnel login`
and then
`cloudflared tunnel create <tunnelname>`

## provide secret
`kubectl create secret generic tunnel-credentials \
--from-file=credentials.json=/mysecretLocation.json`

## tunnel DNS

`cloudflared tunnel route dns <tunnel> <hostname>`
