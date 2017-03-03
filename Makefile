

default:
	mkdir -p tmp
	docker run --rm -it \
		--entrypoint /docker-entrypoint.sh \
		--volume ${PWD}/docker-entrypoint.sh:/docker-entrypoint.sh \
		--volume ${PWD}/tmp/apt:/var/lib/apt \
		--volume ${PWD}/tmp/cache:/var/cache \
		--volume ${PWD}/tmp/ssl:/etc/squid/ssl \
		--volume ${PWD}/squid.conf:/etc/squid/squid.conf \
		--volume ${PWD}/tmp/spool:/var/spool/ \
		-p 3128:3128 -p 3129:3129 \
		vevende/squid3:latest squid