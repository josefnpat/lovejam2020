# Copyright 2017 Josef N Patoprsty
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

PROJECT_SHORTNAME=lovefm
BUTLER_ITCHUSERNAME=foouser
BUTLER_ITCHNAME=lovefm-game

LOVE=love
LOVE_VERSION=11.3
SRC_DIR=src
GIT_HASH=$(shell git log --pretty=format:'%h' -n 1 ${SRC_DIR})
GIT_COUNT=1
GIT_TARGET=${SRC_DIR}/git.lua
WORKING_DIRECTORY=$(shell pwd)

LOVE_TARGET=${PROJECT_SHORTNAME}.love

DEPS_DATA=dev/build_data
DEPS_DOWNLOAD_TARGET=https://bitbucket.org/rude/love/downloads/
DEPS_WIN32_TARGET=love-${LOVE_VERSION}-win64.zip
DEPS_WIN64_TARGET=love-${LOVE_VERSION}-win32.zip
DEPS_MACOS_TARGET=love-${LOVE_VERSION}-macos.zip
DEPS_LINUX_TARGET=love-${LOVE_VERSION}-linux-x86_64.tar.gz
LICENSE_SOURCE=license.txt
LICENSE_TARGET=license-love.txt

BUILD_INFO=v${GIT_COUNT}-[${GIT_HASH}]
BUILD_BIN_NAME=${PROJECT_SHORTNAME}_${BUILD_INFO}
BUILD_DIR=builds
BUILD_LOVE=${PROJECT_SHORTNAME}_${BUILD_INFO}
BUILD_WIN32=${PROJECT_SHORTNAME}_win32_${BUILD_INFO}
BUILD_WIN64=${PROJECT_SHORTNAME}_win64_${BUILD_INFO}
BUILD_MACOS=${PROJECT_SHORTNAME}_macosx_${BUILD_INFO}
BUILD_LINUX=${PROJECT_SHORTNAME}_linux64_${BUILD_INFO}

BUTLER=butler
BUTLER_VERSION=${GIT_COUNT}[git:${GIT_HASH}]

-include Makefile.config

.PHONY: clean
clean:
	#Remove generated `${GIT_TARGET}`
	rm -f ${GIT_TARGET}

.PHONY: cleanlove
cleanlove:
	rm -f ${LOVE_TARGET}

.PHONY: love
love: clean
	#Writing ${GIT_TARGET}
	echo "git_hash,git_count = '${GIT_HASH}',${GIT_COUNT}" > ${GIT_TARGET}
	#Make love file
	cd ${SRC_DIR};\
	zip --filesync -x "*.tmx" -x "*.swp" -r ../${LOVE_TARGET} *;\
	cd ..

.PHONY: run
run: love
	exec ${LOVE} --fused ${LOVE_TARGET} ${loveargs}

.PHONY: debug
debug: love
	exec ${LOVE} --fused ${SRC_DIR} --debug

.PHONY: cleandeps
cleandeps:
	rm -rf ${DEPS_DATA}

.PHONY: deps
deps:
	# Download binaries, and unpack
	mkdir -p ${DEPS_DATA}; \
	cd ${DEPS_DATA}; \
	\
	wget -t 2 -c ${DEPS_DOWNLOAD_TARGET}${DEPS_WIN32_TARGET};\
	unzip -o ${DEPS_WIN32_TARGET};\
	\
	wget -t 2 -c ${DEPS_DOWNLOAD_TARGET}${DEPS_WIN64_TARGET};\
	unzip -o ${DEPS_WIN64_TARGET};\
	\
	wget -t 2 -c ${DEPS_DOWNLOAD_TARGET}${DEPS_MACOS_TARGET};\
	unzip -o ${DEPS_MACOS_TARGET};\
	\
	wget -t 2 -c ${DEPS_DOWNLOAD_TARGET}${DEPS_LINUX_TARGET};\
	tar xvf ${DEPS_LINUX_TARGET};\
	cd -

.PHONY: build_love
build_love: love
	mkdir -p ${BUILD_DIR}
	cp ${LOVE_TARGET} ${BUILD_DIR}/${BUILD_LOVE}.love

.PHONY: build_win32
build_win32: love
	mkdir -p ${BUILD_DIR}
	$(eval TMP := $(shell mktemp -d))
	cat ${DEPS_DATA}/love-${LOVE_VERSION}-win32/love.exe ${LOVE_TARGET} > ${TMP}/${BUILD_BIN_NAME}.exe
	cp ${DEPS_DATA}/love-${LOVE_VERSION}-win32/*.dll ${TMP}
	cp ${DEPS_DATA}/love-${LOVE_VERSION}-win32/${LICENSE_SOURCE} ${TMP}/${LICENSE_TARGET}
	zip -rj ${BUILD_DIR}/${BUILD_WIN32} $(TMP)/*
	rm -rf $(TMP)

.PHONY: build_win64
build_win64: love
	mkdir -p ${BUILD_DIR}
	$(eval TMP := $(shell mktemp -d))
	cat ${DEPS_DATA}/love-${LOVE_VERSION}-win64/love.exe ${LOVE_TARGET} > ${TMP}/${BUILD_BIN_NAME}.exe
	cp ${DEPS_DATA}/love-${LOVE_VERSION}-win64/*.dll ${TMP}
	cp ${DEPS_DATA}/love-${LOVE_VERSION}-win64/${LICENSE_SOURCE} ${TMP}/${LICENSE_TARGET}
	zip -rj ${BUILD_DIR}/${BUILD_WIN64} $(TMP)/*
	rm -rf $(TMP)

.PHONY: build_macos
build_macos: love
	mkdir -p ${BUILD_DIR}
	$(eval TMP := $(shell mktemp -d))
	cp -Rv ${DEPS_DATA}/love.app/ ${TMP}/${BUILD_BIN_NAME}.app
	cp ${LOVE_TARGET} ${TMP}/${BUILD_BIN_NAME}.app/Contents/Resources/${BUILD_BIN_NAME}.love
	cd ${TMP}; \
	zip -ry ${WORKING_DIRECTORY}/${BUILD_DIR}/${BUILD_MACOS}.zip ${BUILD_BIN_NAME}.app/
	cd ${WORKING_DIRECTORY}
	rm -rf $(TMP)

.PHONY: build_linux64
build_linux64: love
	mkdir -p ${BUILD_DIR}
	$(eval TMP := $(shell mktemp -d))
	cp -r ${DEPS_DATA}/dest/* ${TMP}
	mv ${TMP}/love ${TMP}/${BUILD_BIN_NAME}
	cp ${TMP}/usr/bin/love ${TMP}/usr/bin/love_bin
	cat ${TMP}/usr/bin/love_bin ${LOVE_TARGET} > ${TMP}/usr/bin/love
	# Todo: update to linux license when this file is updated
	# cp ${DEPS_DATA}/love-${LOVE_VERSION}.0-win32/${LICENSE_SOURCE} ${TMP}/${LICENSE_TARGET}
	cd ${TMP}; \
	zip -ry ${WORKING_DIRECTORY}/${BUILD_DIR}/${BUILD_LINUX}.zip *
	rm -rf $(TMP)

.PHONY: all
all: build_love build_win32 build_win64 build_macos build_linux64

.PHONY: deploy
deploy: all
	${BUTLER} login
	${BUTLER} push ${BUILD_DIR}/${BUILD_LOVE}.love ${BUTLER_ITCHUSERNAME}/${BUTLER_ITCHNAME}:love\
		--userversion ${BUTLER_VERSION}
	${BUTLER} push ${BUILD_DIR}/${BUILD_WIN32}.zip ${BUTLER_ITCHUSERNAME}/${BUTLER_ITCHNAME}:win32\
		--userversion ${BUTLER_VERSION}
	${BUTLER} push ${BUILD_DIR}/${BUILD_WIN64}.zip ${BUTLER_ITCHUSERNAME}/${BUTLER_ITCHNAME}:win64\
		--userversion ${BUTLER_VERSION}
	${BUTLER} push ${BUILD_DIR}/${BUILD_MACOS}.zip ${BUTLER_ITCHUSERNAME}/${BUTLER_ITCHNAME}:macosx\
		--userversion ${BUTLER_VERSION}
	${BUTLER} push ${BUILD_DIR}/${BUILD_LINUX}.zip ${BUTLER_ITCHUSERNAME}/${BUTLER_ITCHNAME}:linux64\
		--userversion ${BUTLER_VERSION}
	${BUTLER} status ${BUTLER_ITCHUSERNAME}/${BUTLER_ITCHNAME}

.PHONY: status
status:
	#VERSION: ${BUILD_INFO}
	butler status ${BUTLER_ITCHUSERNAME}/${BUTLER_ITCHNAME}
