#!/bin/bash

DEPOT_DOWNLOADER_VERSION=$1
BEATSABER_VERSION=$2
STEAM_MANIFEST_ID=$3
STEAM_USERNAME=$4
STEAM_PASSWORD=$5
MODS_LIST=$6

DEPOT_DOWNLOADER_DIR=depotdownloader
MODS_DOWNLOAD_DIR=mods_${BEATSABER_VERSION}_download
MODS_EXTRACT_DIR=mods_${BEATSABER_VERSION}
DEPOT_DOWNLOADER_ZIP=${DEPOT_DOWNLOADER_DIR}/depotdownloader-${DEPOT_DOWNLOADER_VERSION}.zip
DEPOT_DOWNLOADER_DLL=${DEPOT_DOWNLOADER_DIR}/DepotDownloader.dll
STEAM_APP_ID=620980
STEAM_DEPOT_ID=620981

if [ ! -d ${DEPOT_DOWNLOADER_DIR} ]; then 
    echo "create ${DEPOT_DOWNLOADER_DIR}"
    mkdir ${DEPOT_DOWNLOADER_DIR}
fi

if [ ! -f ${DEPOT_DOWNLOADER_ZIP} ]; then
    echo "download depot downloader ${DEPOT_DOWNLOADER_VERSION}"
    curl https://github.com/SteamRE/DepotDownloader/releases/download/DepotDownloader_${DEPOT_DOWNLOADER_VERSION}/depotdownloader-${DEPOT_DOWNLOADER_VERSION}.zip -L --output ${DEPOT_DOWNLOADER_ZIP}
fi

if [ ! ${DEPOT_DOWNLOADER_DLL} ]; then
    echo "unzip depot downloader"
    unzip ${DEPOT_DOWNLOADER_ZIP} -d ${DEPOT_DOWNLOADER_DIR}
fi

if [ ! -d $(pwd)/beatsaber_${BEATSABER_VERSION} ]; then 
    docker run \
        -it \
        --rm \
        -v $(pwd)/${DEPOT_DOWNLOADER_DIR}:/depotdownloader \
        -v $(pwd)/beatsaber_${BEATSABER_VERSION}:/download \
        --workdir=/depotdownloader \
        mcr.microsoft.com/dotnet/runtime \
        dotnet DepotDownloader.dll \
        -app ${STEAM_APP_ID} \
        -depot ${STEAM_DEPOT_ID} \
        -manifest ${STEAM_MANIFEST_ID} \
        -username ${STEAM_USERNAME} \
        -password ${STEAM_PASSWORD} \
        -dir /download
fi

if [ ! -d ${MODS_DOWNLOAD_DIR} ]; then 
    echo "create ${MODS_DOWNLOAD_DIR} directory"
    mkdir ${MODS_DOWNLOAD_DIR}
fi

if [ ! -d ${MODS_EXTRACT_DIR} ]; then 
    echo "create ${MODS_EXTRACT_DIR} directory"
    mkdir ${MODS_EXTRACT_DIR}
fi

function download_mod {
    SEARCH_TERM=$1
    echo
    echo "# Download ${SEARCH_TERM}"
    URL="https://beatmods.com/api/v1/mod?search=${SEARCH_TERM}&status=approved&gameVersion=${BEATSABER_VERSION}&sort=&sortDirection=1"
    MOD_DOWNLOAD_URL="https://beatmods.com$(curl -s ${URL} | jq -r .[0].downloads[0].url)"
    curl -s "${MOD_DOWNLOAD_URL}" > "${MODS_DOWNLOAD_DIR}/${SEARCH_TERM}.zip"
    unzip -o "${MODS_DOWNLOAD_DIR}/${SEARCH_TERM}.zip" -d "${MODS_EXTRACT_DIR}"
    rm "${MODS_DOWNLOAD_DIR}/${SEARCH_TERM}.zip"
}
for word in $(echo "${MODS_LIST}" | sed -n 1'p' | tr ',' '\n')
do download_mod "$word"
done
    
sudo chown -R $(id -u):$(id -g) $(pwd)/beatsaber_${BEATSABER_VERSION} ${DEPOT_DOWNLOADER_DIR}
rm -rf ${DEPOT_DOWNLOADER_DIR} ${MODS_DOWNLOAD_DIR}