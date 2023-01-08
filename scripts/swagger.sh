#!/usr/bin/env bash

set -eo pipefail

SWAGGER_DIR=./docs
SWAGGER_UI_DIR=${SWAGGER_DIR}/swagger-ui

SDK_VERSION=$(go list -m -f '{{ .Version }}' github.com/cosmos/cosmos-sdk)
IBC_VERSION=$(go list -m -f '{{ .Version }}' github.com/cosmos/ibc-go/v5)
#REGEN_VERSION=$(go list -m -f '{{ .Version }}' github.com/regen-network/regen-ledger/v5)
#CHORA_CONTENT_VERSION=$(go list -m -f '{{ .Version }}' github.com/choraio/mods/content)
#CHORA_GEONODE_VERSION=$(go list -m -f '{{ .Version }}' github.com/choraio/mods/geonode)
#CHORA_VOUCHER_VERSION=$(go list -m -f '{{ .Version }}' github.com/choraio/mods/geonode)
CHORA_CONTENT_VERSION=d1a907e6e185fc80545a20ebefcd509b0a328bf2
CHORA_GEONODE_VERSION=d1a907e6e185fc80545a20ebefcd509b0a328bf2
CHORA_VOUCHER_VERSION=d1a907e6e185fc80545a20ebefcd509b0a328bf2

SDK_RAW_URL=https://raw.githubusercontent.com/cosmos/cosmos-sdk/${SDK_VERSION}/client/docs/swagger-ui/swagger.yaml
IBC_RAW_URL=https://raw.githubusercontent.com/cosmos/ibc-go/${IBC_VERSION}/docs/client/swagger-ui/swagger.yaml
#REGEN_RAW_URL=https://raw.githubusercontent.com/cosmos/cosmos-sdk/${REGEN_VERSION}/app/client/docs/swagger-ui/swagger.yaml
CHORA_CONTENT_RAW_URL=https://raw.githubusercontent.com/choraio/mods/${CHORA_CONTENT_VERSION}/content/docs/swagger.yaml
CHORA_GEONODE_RAW_URL=https://raw.githubusercontent.com/choraio/mods/${CHORA_GEONODE_VERSION}/geonode/docs/swagger.yaml
CHORA_VOUCHER_RAW_URL=https://raw.githubusercontent.com/choraio/mods/${CHORA_VOUCHER_VERSION}/voucher/docs/swagger.yaml

SWAGGER_UI_VERSION=4.11.0
SWAGGER_UI_DOWNLOAD_URL=https://github.com/swagger-api/swagger-ui/archive/refs/tags/v${SWAGGER_UI_VERSION}.zip
SWAGGER_UI_PACKAGE_NAME=${SWAGGER_DIR}/swagger-ui-${SWAGGER_UI_VERSION}

set -eo pipefail

# install swagger-combine if not already installed
npm list -g | grep swagger-combine > /dev/null || npm install -g swagger-combine --no-shrinkwrap

# install statik if not already installed
go install github.com/rakyll/statik@latest

# download Cosmos SDK swagger yaml file
echo "SDK version ${SDK_VERSION}"
curl -o ${SWAGGER_DIR}/swagger-sdk.yaml -sfL "${SDK_RAW_URL}"

# download IBC swagger yaml file
echo "IBC version ${IBC_VERSION}"
curl -o ${SWAGGER_DIR}/swagger-ibc.yaml -sfL "${IBC_RAW_URL}"

# download Regen Ledger swagger yaml file
#echo "Regen version ${REGEN_VERSION}"
#curl -o ${SWAGGER_DIR}/swagger-regen.yaml -sfL "${REGEN_RAW_URL}"

# download Chora Content swagger yaml file
echo "Chora Content version ${CHORA_CONTENT_VERSION}"
curl -o ${SWAGGER_DIR}/swagger-chora-content.yaml -sfL "${CHORA_CONTENT_RAW_URL}"

# download Chora Geonode swagger yaml file
echo "Chora Geonode version ${CHORA_GEONODE_VERSION}"
curl -o ${SWAGGER_DIR}/swagger-chora-geonode.yaml -sfL "${CHORA_GEONODE_RAW_URL}"

# download Chora Voucher swagger yaml file
echo "Chora Voucher version ${CHORA_VOUCHER_VERSION}"
curl -o ${SWAGGER_DIR}/swagger-chora-voucher.yaml -sfL "${CHORA_VOUCHER_RAW_URL}"

# combine swagger yaml files using nodejs package `swagger-combine`
# all the individual swagger files need to be configured in `config.json` for merging
swagger-combine ${SWAGGER_DIR}/config.json -f yaml \
  -o ${SWAGGER_DIR}/swagger.yaml \
  --continueOnConflictingPaths true \
  --includeDefinitions true

# if swagger-ui does not exist locally, download swagger-ui and move dist directory to
# swagger-ui directory, then remove zip file and unzipped swagger-ui directory
if [ ! -d ${SWAGGER_UI_DIR} ]; then
  # download swagger-ui
  curl -o ${SWAGGER_UI_PACKAGE_NAME}.zip -sfL ${SWAGGER_UI_DOWNLOAD_URL}
  # unzip swagger-ui package
  unzip ${SWAGGER_UI_PACKAGE_NAME}.zip -d ${SWAGGER_DIR}
  # move swagger-ui dist directory to swagger-ui directory
  mv ${SWAGGER_UI_PACKAGE_NAME}/dist ${SWAGGER_UI_DIR}
  # remove swagger-ui zip file and unzipped swagger-ui directory
  rm -rf ${SWAGGER_UI_PACKAGE_NAME}.zip ${SWAGGER_UI_PACKAGE_NAME}
fi

# move generated swagger yaml file to swagger-ui directory
cp ${SWAGGER_DIR}/swagger.yaml ${SWAGGER_DIR}/swagger-ui/

# update swagger initializer to default to swagger.yaml
# Note: using -i.bak makes this compatible with both GNU and BSD/Mac
sed -i.bak "s|https://petstore.swagger.io/v2/swagger.json|swagger.yaml|" ${SWAGGER_UI_DIR}/swagger-initializer.js

# generate statik golang code using updated swagger-ui directory
statik -src=${SWAGGER_DIR}/swagger-ui -dest=${SWAGGER_DIR} -f -m

# log whether or not the swagger directory was updated
if [ -n "$(git status ${SWAGGER_DIR} --porcelain)" ]; then
  echo "Swagger statik file updated"
else
  echo "Swagger statik file already in sync"
fi
