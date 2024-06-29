GENERIC=	netbsd-GENERIC
SMOL=		netbsd-SMOL
LIST=		virtio.list
# use a specific version
VERS=		10
ARCH?=		amd64
DIST=		https://nycdn.netbsd.org/pub/NetBSD-daily/netbsd-${VERS}/latest/${ARCH}/binary
SUDO=		sudo -E ARCH=${ARCH} VERS=${VERS}
KERNURL=	https://smolbsd.org/assets
WHOAMI!=	whoami

kernfetch:
	[ -n ${KERNURL} ] && curl -L -O ${KERNURL}/${SMOL} || \
	[ -f ${GENERIC} ] || curl -L -o- ${DIST}/kernel/${GENERIC}.gz | gzip -dc > ${GENERIC}

setfetch:
	setsdir=sets/${ARCH} && \
	[ -d $${setsdir} ] || mkdir -p $${setsdir} && \
	for s in $${SETS}; do \
		if [ ! -f $${setsdir}/$$s ]; then \
			curl -L -O --output-dir $${setsdir} ${DIST}/sets/$$s; \
		fi; \
	done

smol:	kernfetch
	test -f ${SMOL} || { \
		[ -d confkerndev ] || \
		git clone https://gitlab.com/0xDRRB/confkerndev.git; \
		cd confkerndev && make NBVERS=${VERS} i386; cd ..; \
		cp -f ${GENERIC} ${SMOL}; \
		confkerndev/confkerndevi386 -v -i ${SMOL} -K virtio.list -w; \
	}

rescue:
	$(MAKE) setfetch SETS="rescue.tar.xz etc.tar.xz"
	${SUDO} ./mkimg.sh -m 20 -x "rescue.tar.xz etc.tar.xz"
	${SUDO} chown ${WHOAMI} $@-${ARCH}.img

base:
	$(MAKE) setfetch SETS="base.tar.xz etc.tar.xz"
	${SUDO} ./mkimg.sh -i $@-${ARCH}.img -s $@ -m 300 -x "base.tar.xz etc.tar.xz"
	${SUDO} chown ${WHOAMI} $@-${ARCH}.img

prof:
	$(MAKE) setfetch SETS="base.tar.xz etc.tar.xz comp.tar.xz"
	${SUDO} ./mkimg.sh -i $@-${ARCH}.img -s $@ -m 1000 -k ${KERN} -x "base.tar.xz etc.tar.xz comp.tar.xz"
	${SUDO} chown ${WHOAMI} $@-${ARCH}.img

bozohttpd:
	$(MAKE) setfetch SETS="base.tar.xz etc.tar.xz"
	${SUDO} ./mkimg.sh -i $@-${ARCH}.img -s $@ -m 300 -x "base.tar.xz etc.tar.xz"
	${SUDO} chown ${WHOAMI} $@-${ARCH}.img

imgbuilder:
	$(MAKE) setfetch SETS="base.tar.xz etc.tar.xz"
	${SUDO} ./mkimg.sh -i $@-${ARCH}.img -s $@ -m 500 -x "base.tar.xz etc.tar.xz"
	${SUDO} chown ${WHOAMI} $@-${ARCH}.img

nginx: imgbuilder
	dd if=/dev/zero of=$@-${ARCH}.img bs=1M count=100
	${SUDO} ./startnb.sh -k ${SMOL} -i $<-${ARCH}.img -d $@-${ARCH}.img -p ::22022-:22
	${SUDO} chown ${WHOAMI} $@-${ARCH}.img
