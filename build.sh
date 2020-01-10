#!/usr/bin/env bash
# Copyright (C) 2019 Ahmad Thoriq Najahi (@najahiiii)
# Copyright (C) 2019 Dicky Herlambang (@Nicklas373)
# Copyright (C) 2019 Muhammad Fadlyas (@Mhmmdfas)
#

# Main environtment
KERNEL_DIR="$(pwd)"
KERNEL_TYPE="HMP"
KERNEL_COMP="/root/toolchain"
TEMP="$KERNEL_DIR/TEMP"
KERNEL_LOG="$KERNEL_DIR/out/arch/arm64/boot/build.log"
KERNEL_IMG="$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb"
ZIP_DIR="$KERNEL_DIR/anykernel3"
CONFIG="rolex_defconfig"
DEVICE_SUPPORT="Xiaomi Redmi 4A & 5A"
DEVICE="Xiaomi Redmi 4A"
CODENAME="rolex"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
POINT="$(git --no-pager log --pretty=format:'%h: %s by %an' -1)"

# Clone Dependencies
git clone -j32 --depth=1 https://github.com/Mhmmdfas/anykernel3 -b ${CODENAME}

# Export
export ARCH=arm64
export SUBARCH=arm64
export TZ=":Asia/Jakarta"
export KBUILD_BUILD_USER=MhmmdFadlyas
export KBUILD_BUILD_HOST=Mhmmdfas
export USE_CCACHE=1
export CACHE_DIR=~/.ccache
# export KBUILD_BUILD_VERSION=${CIRCLE_PREVIOUS_BUILD_NUM}

mkdir $KERNEL_DIR/TEMP

#
# Telegram FUNCTION
#
git clone -q https://github.com/fabianonline/telegram.sh telegram

TELEGRAM_ID=${chat_id}
TELEGRAM_TOKEN=${token}
TELEGRAM=telegram/telegram

export TELEGRAM_TOKEN

function make_clang() {
# export KBUILD_COMPILER_STRING="$(${KERNEL_COMP}/nusantara/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g')"
export LD_LIBRARY_PATH="${KERNEL_COMP}/nusantara/bin/../lib:$PATH"
make -s -C "${KERNEL_DIR}" ${THREAD} O=out ${CONFIG}
PATH="${KERNEL_COMP}/nusantara/bin:${PATH}" \
make -C "${KERNEL_DIR}" -j$(nproc) O=out \
                  ARCH=arm64 \
                  CC=clang \
                  CLANG_TRIPLE=aarch64-linux-gnu- \
                  CROSS_COMPILE=aarch64-linux-gnu- \
                  CROSS_COMPILE_ARM32=arm-linux-gnueabi- 2>&1| tee build.log
}

function push() {
    PATH="${KERNEL_COMP}/nusantara/bin:${PATH}"
    ZIP=$(echo *.zip)
	curl -F document=@$ZIP  "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendDocument" \
			-F chat_id="${TELEGRAM_ID}" \
			-F "disable_web_page_preview=true" \
			-F "parse_mode=html" \
			-F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). <b>For ${DEVICE}</b> [ <code>$UTS_VERSION</code> ]"
}

function log_compile() {
    cd ${TEMP}
    TXT=$(echo *.txt)
	curl -F document=@$TXT  "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendDocument" \
			-F chat_id="${TELEGRAM_ID}"
}

function testprivv() {
    PATH="${KERNEL_COMP}/nusantara/bin:${PATH}"
	ZIP=$(echo *.zip)
	curl -F document=@$ZIP  "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendDocument" \
			-F chat_id="${fadlyas}" \
			-F "disable_web_page_preview=true" \
			-F "parse_mode=html" \
			-F caption="Build took $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s). <b>For ${DEVICE}</b> [ <code>$UTS_VERSION</code> ] $BUILD_USER@$BUILD_HOST"
}

function tg_sendstick() {
	curl -s -F chat_id=${TELEGRAM_ID} -F sticker="CAADBQADeQEAAn1Cwy71MK7Ir5t0PhYE" https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendSticker
}

function tg_channelprivv() {
	"${TELEGRAM}" -c ${fadlyas} -H \
		"$(
			for POST in "${@}"; do
				echo "${POST}"
			done
		)"
}

function tg_channelcast() {
	"${TELEGRAM}" -c ${TELEGRAM_ID} -H \
		"$(
			for POST in "${@}"; do
				echo "${POST}"
			done
		)"
}

function logerr() {
    cat build.log | curl -F 'sprunge=<-' http://sprunge.us > link
    LOG="$(cat link)"
}

function tg_sendinfo() {
	curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
		-d "parse_mode=markdown" \
		-d text="${1}" \
		-d chat_id="${TELEGRAM_ID}" \
		-d "disable_web_page_preview=true"
}

function telegram_info() {
     UTS_VERSION=$(cat ${KERNEL_DIR}/out/include/generated/compile.h | grep UTS_VERSION | cut -d '"' -f2)
     BUILD_USER=$(cat ${KERNEL_DIR}/out/include/generated/compile.h | grep LINUX_COMPILE_BY | cut -d '"' -f2)
     BUILD_HOST=$(cat ${KERNEL_DIR}/out/include/generated/compile.h | grep LINUX_COMPILE_HOST | cut -d '"' -f2)
}

function finerr_privv() {
   logerr
   paste
   curl -s "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
		-d "parse_mode=markdown" \
		-d text="Build throw an error(s).%0AFor $DEVICE %0A🖇️: ${LOG}" \
		-d chat_id="${fadlyas}" \
		-d "disable_web_page_preview=true"
	exit 1
}

function make_zip() {
    cd ${ZIP_DIR}
    zip -r9q GREENFORCE-${KERNEL_TYPE}-${CODENAME}-${TANGGAL}.zip * -x .git README.md
}

function clean() {
    rm -rf ${TELEGRAM}
    rm -rf ${ZIP_DIR}
    rm -rf ${KERNEL_IMG}
    rm -rg ${KERNEL_COMP}
}

#
# Telegram FUNCTION end
#

TANGGAL=$(TZ=Asia/Jakarta date +'%H%M-%d%m%y')
DATE=`date`
BUILD_START=$(date +"%s")

make_clang
telegram_info
                              
if [[ ! -f "${KERNEL_IMG}" ]]; then
	tg_sendinfo "$(echo "Build throw an error(s) took $((${DIFF} / 60)) minute(s) and $((${DIFF} % 60)) seconds.")"
	finerr_privv
	logerr
	exit 1;
fi
cp ${KERNEL_LOG} ${TEMP}/build.txt
cp ${KERNEL_IMG} ${ZIP_DIR}/zImage
make_zip
testprivv
push
cd $KERNEL_DIR
BUILD_END=$(date +"%s")
DIFF=$((${BUILD_END} - ${BUILD_START}))
log_compile

tg_sendstick

tg_channelcast "<b>GREENFORCE ${KERNEL_TYPE} new build is up</b>!!" \
                             "<b>Device :</b><code> ${DEVICE_SUPPORT} </code>" \
                             "<b>Branch :</b><code> ${BRANCH} </code>" \
                             "<b>Latest commit :</b><code> ${POINT} </code>" \
                             "<b>Toolchain :</b><code> ${KBUILD_COMPILER_STRING} </code>"
                             
tg_channelprivv "GREENFORCE new build for ${CODENAME}" \
                              "📱: <code>${DEVICE}</code>" \
                              "⏰: <code>$(TZ=Asia/Jakarta date)</code>" \
                              "📑: <code>${POINT}</code>" \
                              "🖇️: <a href='${CIRCLE_BUILD_URL}'>here</a> | #${CIRCLE_BUILD_NUM}."
clean
