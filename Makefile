
ROOT_DIR=${CURDIR}

PLATFORMS_SUPPORTED=win linux macos
ifeq (${OS},Windows_NT)
  PLATFORM:=win
else
  UNAME_S=${shell uname -s}
  ifeq (${UNAME_S},Linux)
    PLATFORM:=linux
  endif
  ifeq (${UNAME_S},Darwin)
    PLATFORM:=macos
  endif
endif
ifeq ($(filter ${PLATFORM},${PLATFORMS_SUPPORTED}),)
  ${error Platform not detected or unsupported.}
endif

ifeq (${PLATFORM},win)
QT_SRC_FILE=qt-everywhere-src-5.12.5.zip
QT_SRC_MD5=157fa5d9c897737ce06ba4f9a20151e0
QT_SRC_URL=https://download.qt.io/official_releases/qt/5.12/5.12.5/single/qt-everywhere-src-5.12.5.zip
else
QT_SRC_FILE=qt-everywhere-src-5.12.5.tar.xz
QT_SRC_MD5=d8c9ed842d39f1a5f31a7ab31e4e886c
QT_SRC_URL=https://download.qt.io/official_releases/qt/5.12/5.12.5/single/qt-everywhere-src-5.12.5.tar.xz
endif

QT_SRC_DIR=qt-everywhere-src-5.12.5
QT_BUILD_DIR=${QT_SRC_DIR}/build
QT_PREFIX=${ROOT_DIR}/qt

JOM_URL=https://download.qt.io/official_releases/jom/jom.zip

ifeq (${PLATFORM},linux)
PLATFORM_QT_CONFIGURE=configure
PLATFORM_QT_OPTIONS=-xcb -gtk -ccache
endif
ifeq (${PLATFORM},macos)
PLATFORM_QT_CONFIGURE=configure
PLATFORM_QT_OPTIONS=-ccache -dbus-runtime
endif
ifeq (${PLATFORM},win)
PLATFORM_QT_CONFIGURE=configure.bat
PLATFORM_QT_OPTIONS=-skip qtwayland -skip qtmacextras -skip qtx11extras
endif

BUILD_THREADS:=4

PACKAGE_FILE=cutter-deps-qt-${PLATFORM}.tar.gz

all: qt pkg

ifeq (${PLATFORM},macos)
  define check_md5
	if [ "`md5 -r \"$1\"`" != "$2 $1" ]; then \
		echo "MD5 mismatch for file $1"; \
		exit 1; \
	else \
		echo "$1 OK"; \
	fi
  endef
else
  define check_md5
	echo "$2 $1" | md5sum -c -
  endef
endif

ifeq (${PLATFORM},win)
  define extract
	7z x "$1" -bsp1 \
		-x'!'${QT_SRC_DIR}/qtwebengine \
		-x'!'${QT_SRC_DIR}/qt3d \
		-x'!'${QT_SRC_DIR}/qtcanvas3d \
		-x'!'${QT_SRC_DIR}/qtcharts \
		-x'!'${QT_SRC_DIR}/qtconnectivity \
		-x'!'${QT_SRC_DIR}/qtdeclarative \
		-x'!'${QT_SRC_DIR}/qtdoc \
		-x'!'${QT_SRC_DIR}/qtscript \
		-x'!'${QT_SRC_DIR}/qtdatavis3d \
		-x'!'${QT_SRC_DIR}/qtgamepad \
		-x'!'${QT_SRC_DIR}/qtlocation \
		-x'!'${QT_SRC_DIR}/qtgraphicaleffects \
		-x'!'${QT_SRC_DIR}/qtmultimedia \
		-x'!'${QT_SRC_DIR}/qtpurchasing \
		-x'!'${QT_SRC_DIR}/qtscxml \
		-x'!'${QT_SRC_DIR}/qtsensors \
		-x'!'${QT_SRC_DIR}/qtserialbus \
		-x'!'${QT_SRC_DIR}/qtserialport \
		-x'!'${QT_SRC_DIR}/qtspeech \
		-x'!'${QT_SRC_DIR}/qttranslations \
		-x'!'${QT_SRC_DIR}/qtvirtualkeyboard \
		-x'!'${QT_SRC_DIR}/qtwebglplugin \
		-x'!'${QT_SRC_DIR}/qtwebsockets \
		-x'!'${QT_SRC_DIR}/qtwebview \
		-x'!'${QT_SRC_DIR}/qtmacextras \
		-x'!'${QT_SRC_DIR}/qtwayland \
		-x'!'${QT_SRC_DIR}/qtquickcontrols \
		-x'!'${QT_SRC_DIR}/qtquickcontrols2 \
		-x'!'${QT_SRC_DIR}/qtx11extras \
		-x'!'${QT_SRC_DIR}/qtandroidextras \
		-x'!'${QT_SRC_DIR}/qtwebchannel
  endef
else
  define extract
	tar -xf "$1"
  endef
endif

define download_extract
	curl -L "$1" -o "$2"
	${call check_md5,$2,$3}
	$(call extract,$2)
endef

ifeq (${PLATFORM},win)
PLATFORM_QT_DEPS=jom
PLATFORM_CLEAN_DEPS=clean-jom

jom:
	mkdir -p jom
	curl -fL "${JOM_URL}" -o jom/jom.zip
	cd jom && 7z x jom.zip

.PHONY: clean-jom
clean-jom:
	rm -rf jom

else
PLATFORM_QT_DEPS=
PLATFORM_CLEAN_DEPS=
endif

.PHONY: clean
clean: clean-qt ${PLATFORM_CLEAN_DEPS}

.PHONY: distclean
distclean: distclean-qt ${PLATFORM_CLEAN_DEPS}

${QT_SRC_DIR}:
	@echo ""
	@echo "#########################"
	@echo "# Downloading Qt Source #"
	@echo "#########################"
	@echo ""
	$(call download_extract,${QT_SRC_URL},${QT_SRC_FILE},${QT_SRC_MD5})
	#cp patch/qttools-src.pro "${QT_SRC_DIR}/qttools/src/src.pro"

.PHONY: src
src: ${QT_SRC_DIR}

qt: ${QT_SRC_DIR} ${PLATFORM_QT_DEPS}
	@echo ""
	@echo "#########################"
	@echo "# Building Qt           #"
	@echo "#########################"
	@echo ""

	mkdir -p "${QT_BUILD_DIR}"
	cd "${QT_BUILD_DIR}" && \
		../${PLATFORM_QT_CONFIGURE} \
			-prefix "${QT_PREFIX}" \
			-opensource -confirm-license \
			-release \
			-qt-libpng \
			-qt-libjpeg \
			-no-feature-cups \
			-no-feature-icu \
			-no-sql-db2 \
			-no-sql-ibase \
			-no-sql-mysql \
			-no-sql-oci \
			-no-sql-odbc \
			-no-sql-psql \
			-no-sql-sqlite2 \
			-no-sql-sqlite \
			-no-sql-tds \
			-nomake tests \
			-nomake examples \
			-nomake tools \
			-skip qtwebengine \
			-skip qt3d \
			-skip qtcanvas3d \
			-skip qtcharts \
			-skip qtconnectivity \
			-skip qtdeclarative \
			-skip qtdoc \
			-skip qtscript \
			-skip qtdatavis3d \
			-skip qtgamepad \
			-skip qtlocation \
			-skip qtgraphicaleffects \
			-skip qtmultimedia \
			-skip qtpurchasing \
			-skip qtscxml \
			-skip qtsensors \
			-skip qtserialbus \
			-skip qtserialport \
			-skip qtspeech \
			-skip qttranslations \
			-skip qtvirtualkeyboard \
			-skip qtwebglplugin \
			-skip qtwebsockets \
			-skip qtwebview \
			-skip qtquickcontrols \
			-skip qtquickcontrols2 \
			${PLATFORM_QT_OPTIONS}

ifeq (${PLATFORM},win)
	cd "${QT_BUILD_DIR}" && "${ROOT_DIR}/jom/jom.exe" -J ${BUILD_THREADS}
	cd "${QT_BUILD_DIR}" && "${ROOT_DIR}/jom/jom.exe" install
else
	cd "${QT_BUILD_DIR}" && make -j${BUILD_THREADS} | awk "NR%10==1" # Travis doesn't like too much and too little output
	cd "${QT_BUILD_DIR}" && make install
endif

ifeq (${PLATFORM},macos)
	cd "${QT_PREFIX}/include" && \
	for header_dir in ../lib/*.framework/Headers; do \
		module="$${header_dir%.framework/Headers}"; \
		module="$${module#../lib/}"; \
		ln -s "$$header_dir" "$$module"; \
	done
endif

.PHONY: clean-qt
clean-qt:
	rm -f "${QT_SRC_FILE}"
	rm -rf "${QT_SRC_DIR}"

.PHONY: distclean-qt
distclean-qt: clean-qt
	rm -rf "${QT_PREFIX}"

${PACKAGE_FILE}: qt
	tar -czf "${PACKAGE_FILE}" qt

.PHONY: pkg
pkg: ${PACKAGE_FILE}

.PHONY: distclean-pkg
distclean-pkg:
	rm -f "${PACKAGE_FILE}"

