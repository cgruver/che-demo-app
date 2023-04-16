#!/usr/bin/env bash

CHE_NAMESPACE=""
GIT_PAT="hello"
GIT_PAT_CHK="goodbye"

function getNamespaceInfo() {
  CHE_USER=$(oc whoami)

  for i in $(oc get project --selector app.kubernetes.io/component=workspaces-namespace -o name)
  do
    NAMESPACE_USER=$(oc get ${i} -o jsonpath='{.metadata.annotations.che\.eclipse\.org/username}')
    if [[ ${NAMESPACE_USER} == ${CHE_USER} ]]
    then
      CHE_NAMESPACE=$(oc get ${i} -o jsonpath='{.metadata.name}')
      break
    fi
  done
}

function getPat() {
  echo "Enter your Github User ID:"
  read GIT_USER
  while [[ ${GIT_PAT} != ${GIT_PAT_CHK} ]]
  do
    echo "Enter Your Github Personal Access Token and hit <Return>:"
    read -s GIT_PAT
    echo "Re-Enter Your Github Personal Access Token and hit <Return>:"
    read -s GIT_PAT_CHK
    if [[ ${GIT_PAT} != ${GIT_PAT_CHK} ]]
    then
      echo "Tokens do not match. Please Try Again."
    fi
  done
}

function createGitHubSecret() {
cat << EOF | oc apply -f -
kind: Secret
apiVersion: v1
metadata:
  name: personal-access-token-${CHE_USER}
  namespace: ${CHE_NAMESPACE}
  labels:
    app.kubernetes.io/component: scm-personal-access-token
    app.kubernetes.io/part-of: che.eclipse.org
  annotations:
    che.eclipse.org/che-userid: ${CHE_USER}
    che.eclipse.org/scm-personal-access-token-name: github
    che.eclipse.org/scm-url: https://github.com
    che.eclipse.org/scm-userid: ${GIT_USER}
data:
  token: ${GIT_PAT}
type: Opaque
EOF
}

getNamespaceInfo
if [[ ${CHE_NAMESPACE} == "" ]]
then
  echo "unable to identify a namespace for user: ${CHE_USER}"
  exit 1
fi
getPat
createGitHubSecret

GIT_PAT=""
GIT_PAT_CHK=""
GIT_USER=""
