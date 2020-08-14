#! /bin/bash

set -e
UBUNTU_RELEASE=bionic
KEYSID=8C718D3B5072E1F5
UPSTREAM_URL=(
"https://mirrors.tuna.tsinghua.edu.cn/mysql/apt/ubuntu/"
)
REPOS=(bionic)
COMPONENTS=(mysql-8.0)
PKGS=(mysql-server)
VERS=()
set +e

# Create local repository if they don't exist
aptly repo list -raw | grep "^local$" &> /dev/null
if [[ $? -ne 0 ]]; then
    echo -n "Creating local repository..."
    aptly  -distribution ${UBUNTU_RELEASE} -component main \
      repo create local
    echo
fi

# Import repository key
set -e
gpg --no-default-keyring --keyring trustedkeys.gpg --keyserver pool.sks-keyservers.net --recv-keys ${KEYID}
set +e

for i in $(seq ${#COMPONENTS[*]}); do
  i=$((i-1))

  # Create repository mirrors
  aptly mirror list -raw | grep "^${UBUNTU_RELEASE}-${COMPONENTS[$i]}$" &> /dev/null
  if [[ $? -ne 0 ]]; then
    set -e
    aptly mirror create -architectures=amd64 \
      -force-components -filter="${PKGS[$i]} ${VERS[$i]}" -filter-with-deps \
      ${UBUNTU_RELEASE}-${COMPONENTS[$i]} ${UPSTREAM_URL[$i]} ${REPOS[*]} ${COMPONENTS[$i]}
    set +e
  fi

  # Update repository mirrors
  set -e
  aptly mirror update ${UBUNTU_RELEASE}-${COMPONENTS[$i]}
  set +e

  # Import mirror to local repository
  set -e
  aptly repo import -architectures=amd64 -with-deps \
    ${UBUNTU_RELEASE}-${COMPONENTS[$i]} local ${PKGS[$i]}
  set +e
done

# Publish/Update  local repository
aptly  publish list | grep ".*${UBUNTU_RELEASE}.* publishes .*local.*"
if [[ $? -ne 0 ]]; then
    echo "Publish local repository..."
    aptly -passphrase="${GPG_PASSWORD}" publish repo local 
else
    echo "Update local repository..."
    aptly -passphrase="${GPG_PASSWORD}" publish update ${UBUNTU_RELEASE}
fi

