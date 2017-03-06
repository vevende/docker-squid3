# docker-squid3

Squid3 with SSL support

Starting

```
docker pull vevende/docker-squid3:latest
docker volume create --name squidpool
docker run \
  -p 3129:3129 -p 3130:3130 \
  --volume $(pwd)/etc:/etc/squid/
  --volume squidpool:/var/spool/squid
  --network host \
  vevende/docker-squid3:latest

# If you want to forward all incoming trafic from eth0 to the proxy,
# you will probably need to make extra steps to make it work correctly.
# refer to the squid documentation, for example: http://wiki.squid-cache.org/ConfigExamples/Intercept/IptablesPolicyRoute

iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j REDIRECT --to-port 3129
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 443 -j REDIRECT --to-port 3130
```
