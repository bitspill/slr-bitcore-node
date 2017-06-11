#!/bin/bash

set -e

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
platform=`uname -a | awk '{print tolower($1)}'`
arch=`uname -m`
version="0.12.1"
url="https://github.com/bitpay/bitcoin/releases/download"
tag="v0.12.1-bitcore-4"

if [ "${platform}" == "linux" ]; then
    if [ "${arch}" == "x86_64" ]; then
        tarball_name="bitcoin-${version}-linux64.tar.gz"
    elif [ "${arch}" == "x86_32" ]; then
    echo "Bitcoin binary distribution not available for platform and architecture"
    exit -1
        tarball_name="bitcoin-${version}-linux32.tar.gz"
    fi
elif [ "${platform}" == "darwin" ]; then
    echo "Bitcoin binary distribution not available for platform and architecture"
    exit -1
    tarball_name="bitcoin-${version}-osx64.tar.gz"
else
    echo "Bitcoin binary distribution not available for platform and architecture"
    exit -1
fi

binary_url="${url}/${tag}/${tarball_name}"
shasums_url="${url}/${tag}/SHA256SUMS.asc"

download_bitcoind() {

    cd "${root_dir}/bin"

    echo "Downloading bitcoin: ${binary_url}"

    # ToDO: Solarcoin publish releases to download
    cp /media/sf_host-bitoin/src/bitcoin-cli ./bitcoin-cli
    cp /media/sf_host-bitoin/src/bitcoind ./bitcoind
    cp /media/sf_host-bitoin/src/bitcoin-tx ./bitcoin-tx
    return

    is_curl=true
    if hash curl 2>/dev/null; then
        curl --fail -I $binary_url >/dev/null 2>&1
    else
        is_curl=false
        wget --server-response --spider $binary_url >/dev/null 2>&1
    fi

    if test $? -eq 0; then
        if [ "${is_curl}" = true ]; then
            curl -L $binary_url > $tarball_name
            curl -L $shasums_url > SHA256SUMS.asc
        else
            wget $binary_url
            wget $shasums_url
        fi
        if test -e "${tarball_name}"; then
            echo "Unpacking bitcoin distribution"
            tar -xvzf $tarball_name
            if test $? -eq 0; then
                ln -sf "bitcoin-${version}/bin/bitcoind"
                return;
            fi
        fi
    fi
    echo "Bitcoin binary distribution could not be downloaded"
    exit -1
}

verify_download() {
    echo "Verifying signatures of bitcoin download"
    gpg --verify "${root_dir}/bin/SHA256SUMS.asc"

    if hash shasum 2>/dev/null; then
        shasum_cmd="shasum -a 256"
    else
        shasum_cmd="sha256sum"
    fi

    download_sha=$(${shasum_cmd} "${root_dir}/bin/${tarball_name}" | awk '{print $1}')
    expected_sha=$(cat "${root_dir}/bin/SHA256SUMS.asc" | grep "${tarball_name}" | awk '{print $1}')
    echo "Checksum (download): ${download_sha}"
    echo "Checksum (verified): ${expected_sha}"
    if [ "${download_sha}" != "${expected_sha}" ]; then
        echo -e "\033[1;31mChecksums did NOT match!\033[0m\n"
        exit 1
    else
        echo -e "\033[1;32mChecksums matched!\033[0m\n"
    fi
}

download=1
verify=0

if [ "${SKIP_BITCOIN_DOWNLOAD}" = 1 ]; then
    download=0;
fi

if [ "${VERIFY_BITCOIN_DOWNLOAD}" = 1 ]; then
    verify=1;
fi

while [ -n "$1" ]; do
  param="$1"
  value="$2"

  case $param in
    --skip-bitcoin-download)
          download=0
          ;;
    --verify-bitcoin-download)
          verify=1
          ;;
  esac
  shift
done

if [ "${download}" = 1 ]; then
    download_bitcoind
fi

#if [ "${verify}" = 1 ]; then
#    verify_download
#fi

exit 0
