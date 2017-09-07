FROM lsiobase/alpine:3.6
MAINTAINER saarg

# set version label
ARG BUILD_DATE
ARG VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"

# package version
ARG ARGTABLE_VER="2.13"
ARG TZ="America/Chicago"
ARG XMLTV_VER="0.5.69"

# Environment settings
ENV HOME="/config"

# copy patches
COPY patches/ /tmp/patches/

# install build packages
RUN \
 apk update &&\
 apk add --no-cache --virtual=build-dependencies \
	autoconf \
	automake \
	cmake \
	ffmpeg-dev \
	file \
	findutils \
	g++ \
	gcc \
	gettext-dev \
	git \
	libgcrypt-dev \
	libhdhomerun-dev \
	libressl-dev \
	libtool \
	libvpx-dev \
	libxml2-dev \
	libxslt-dev \
	make \
	mercurial \
	opus-dev \
	patch \
	pcre2-dev \
	perl-dev \
	pkgconf \
	sdl-dev \
	uriparser-dev \
	wget \
	x264-dev \
	x265-dev \
	zlib-dev && \
 apk add --no-cache --virtual=build-dependencies \
	--repository http://nl.alpinelinux.org/alpine/edge/testing \
	gnu-libiconv-dev && \

# install runtime packages
 apk add --no-cache \
	bsd-compat-headers \
	bzip2 \
	curl \
	ffmpeg \
	ffmpeg-libs \
	gzip \
	libcrypto1.0 \
	libcurl	\
	libhdhomerun-libs \
	libressl \
	libssl1.0 \
	libvpx \
	libxml2 \
	libxslt \
	linux-headers \
	opus \
	pcre2 \
	perl \
	perl-archive-zip \
	perl-boolean \
	perl-capture-tiny \
	perl-cgi \
	perl-compress-raw-zlib \
	perl-data-dumper \
	perl-date-manip \
	perl-datetime \
	perl-datetime-format-strptime \
	perl-datetime-timezone \
	perl-dbd-sqlite \
	perl-dbi \
	perl-digest-sha1 \
	perl-doc \
	perl-file-slurp \
	perl-file-temp \
	perl-file-which \
	perl-getopt-long \
	perl-html-parser \
	perl-html-tree \
	perl-http-cookies \
	perl-io \
	perl-io-compress \
	perl-io-html \
	perl-io-socket-ssl \
	perl-io-stringy \
	perl-json \
	perl-libwww \
	perl-lingua-en-numbers-ordinate \
	perl-lingua-preferred \
	perl-list-moreutils \
	perl-module-build \
	perl-module-pluggable \
	perl-net-ssleay \
	perl-parse-recdescent \
	perl-path-class \
	perl-scalar-list-utils \
	perl-term-progressbar \
	perl-term-readkey \
	perl-test-exception \
	perl-test-requires \
	perl-timedate \
	perl-try-tiny \
	perl-unicode-string \
	perl-xml-libxml \
	perl-xml-libxslt \
	perl-xml-parser \
	perl-xml-sax \
	perl-xml-treepp \
	perl-xml-twig \
	perl-xml-writer \
	python \
	tar \
	uriparser \
	wget \
	x264 \
	x265 \
	zlib && \
 apk add --no-cache \
	--repository http://nl.alpinelinux.org/alpine/edge/testing \
	gnu-libiconv && \

# install perl modules for xmltv
 curl -L http://cpanmin.us | perl - App::cpanminus && \
 cpanm --installdeps /tmp/patches && \

# dependencies for webgrabpp
apk --no-cache add ca-certificates wget unzip unrar \
    && update-ca-certificates && \

# packages for zap2xml
echo "@edge http://nl.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories && \
echo "@edgetesting http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
apk add --no-cache perl@edge perl-html-parser@edge perl-http-cookies@edge perl-lwp-useragent-determined@edge perl-json@edge perl-json-xs@edgetesting && \

# build dvb-apps
 hg clone http://linuxtv.org/hg/dvb-apps /tmp/dvb-apps && \
 cd /tmp/dvb-apps && \
 make -C lib && \
 make -C lib install && \

# build tvheadend
 git clone https://github.com/tvheadend/tvheadend.git /tmp/tvheadend && \
 cd /tmp/tvheadend && \
 ./configure \
	--disable-ffmpeg_static \
	--disable-hdhomerun_static \
	--disable-libfdkaac_static \
	--disable-libmfx_static \
	--disable-libtheora_static \
	--disable-libvorbis_static \
	--disable-libvpx_static \
	--disable-libx264_static \
	--disable-libx265_static \
	--enable-hdhomerun_client \
	--enable-libav \
	--infodir=/usr/share/info \
	--localstatedir=/var \
	--mandir=/usr/share/man \
	--prefix=/usr \
	--sysconfdir=/config && \
 make && \
 make install && \

# build XMLTV
 curl -o \
 /tmp/xmtltv-src.tar.bz2 -L \
	"http://kent.dl.sourceforge.net/project/xmltv/xmltv/${XMLTV_VER}/xmltv-${XMLTV_VER}.tar.bz2" && \
 tar xf \
 /tmp/xmtltv-src.tar.bz2 -C \
	/tmp --strip-components=1 && \
 cd "/tmp/xmltv-${XMLTV_VER}" && \
 echo -e "yes" | perl Makefile.PL PREFIX=/usr/ INSTALLDIRS=vendor && \
 make && \
 make test && \
 make install && \

# build argtable2
 ARGTABLE_VER1="${ARGTABLE_VER//./-}" && \
 mkdir -p \
	/tmp/argtable && \
 curl -o \
 /tmp/argtable-src.tar.gz -L \
	"https://sourceforge.net/projects/argtable/files/argtable/argtable-${ARGTABLE_VER}/argtable${ARGTABLE_VER1}.tar.gz" && \
 tar xf \
 /tmp/argtable-src.tar.gz -C \
	/tmp/argtable --strip-components=1 && \
 cp /tmp/patches/config.* /tmp/argtable && \
 cd /tmp/argtable && \
 ./configure \
	--prefix=/usr && \
 make && \
 make check && \
 make install && \

# build comskip
 git clone git://github.com/erikkaashoek/Comskip /tmp/comskip && \
 cd /tmp/comskip && \
 ./autogen.sh && \
 ./configure \
	--bindir=/usr/bin \
	--sysconfdir=/config/comskip && \
 make && \
 make install && \

# download and extract WG++
mkdir wg++ config data && \
    wget -O /tmp/wg++.rar http://webgrabplus.com/sites/default/files/download/SW/V1.1.1/WebGrabPlusV1.1.1LINUX.rar && \
    unrar x /tmp/wg++.rar /wg++/ && \
    rm /tmp/wg++.rar && \
    mv /wg++/WebGrab+PlusV1.1.1LINUX/* /wg++/ && \
    mv /wg++/MDB/ /wg++/mdb && \
    mv /wg++/REX/ /wg++/rex && \
    rm /wg++/*.ini && \
    rm -R /wg++/exe && \
    cp /wg++/wget.exe /wg++/wget.bat /config/ && \
    cp -R /wg++/mdb /config/ && \
    cp -R /wg++/rex /config/ && \

# WG++ update
wget -O /tmp/update.zip http://webgrabplus.com/sites/default/files/download/sw/V1.1.1/upgrade/patchexe_57.zip && \
    unzip /tmp/update.zip -d /tmp/ && \
    mv /tmp/WebGrab+Plus.exe /wg++/ && \
    mv /tmp/xmltv.dll /wg++/ && \

chmod -R +x /wg++/ && \

# Fetch and extract picons
wget "https://www.picons.eu/downloads/dir-6urwjetn6a2486g9x44oejbzyprtvtin/srp-full.800x450-760x410.light.on.transparent_2017-09-06--20-04-16.symlink.tar.xz" -O /picons/picons.tar.xz && \
apk add xz-utils &&\
tar xf /picons/picons.tar.xz

# cleanup
 apk del --purge \
	build-dependencies && \
 rm -rf \
	/config/.cpanm \
	/tmp/*

# copy local files
COPY root/ /

# add WG++ config files
ADD WebGrab++.config.xml uk-sky.com.ini tv.com.ini tvguide.co.uk.ini /config/

# ports and volumes
EXPOSE 9981 9982
VOLUME /config /recordings /data
