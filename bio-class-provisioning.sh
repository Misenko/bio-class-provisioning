#!/bin/bash

# create tmp directory
TMP_DIR=$(mktemp -d --suffix bio-class-provisioning)
PROVISIONING_DIR=$(dirname $(realpath $0))

# export necessary variables
export OPENNEBULA_ENDPOINT="https://cloud.metacentrum.cz:6443/RPC2"
export OPENNEBULA_SALT_SECRET=
export OPENNEBULA_CLOUDKEEPER_SECRET=
export OPENNEBULA_BASE_IMAGE_SIZE="25600"
export OPENNEBULA_NFS_IMAGE_ID="6795"
export OPENNEBULA_SWAP_IMAGE_ID="4200"
export OPENNEBULA_PUBLIC_STUDENT_NETWORK_ID="1543"
export OPENNEBULA_PUBLIC_TEACHER_NETWORK_ID="1544"
export OPENNEBULA_PUBLIC_NFS_NETWORK_ID="1542"
export OPENNEBULA_PRIVATE_NETWORK_ID="1383"
export OPENNEBULA_PUBLIC_NETWORK_SECURITY_GROUPS=""
export OPENNEBULA_PRIVATE_NETWORK_SECURITY_GROUPS="101"
export OPENNEBULA_DEPLOY_CLUSTER_ID="120"
export OPENNEBULA_CPU="4"
export OPENNEBULA_MEMORY="16384"
export OPENNEBULA_DATASTORE="metacloud-dukan"
export OPENNEBULA_IMAGE_FORMAT="qcow2"
export SALT_MASTER_PUBLIC_IP_ADDRESS=
export SALT_MASTER_PRIVATE_IP_ADDRESS=
export SALT_MASTER_USER="root"
export IMAGEMASTER3000_STUDENT_BRANCH="bio-class-student"
export IMAGEMASTER3000_TEACHER_BRANCH="bio-class-teacher"
export IMAGEMASTER3000_NFS_BRANCH="bio-class-nfs"
export IMAGEMASTER3000_STUDENT_GROUP="bioconductor"
export IMAGEMASTER3000_TEACHER_GROUP="bioconductor-teachers"
export IMAGEMASTER3000_NFS_GROUP="bioconductor-nfs"
export CLOUDKEEPER_PUBLIC_IP=
export CLOUDKEEPER_TEMPLATES_DIR="${TMP_DIR}/opennebula/cloudkeeper-one/templates"
export SALT_REPO_PACKAGE="https://repo.saltstack.com/yum/redhat/salt-repo-2017.7-1.el7.noarch.rpm"
export SALT_REPO_VERSION="2017.7"
export DOCKER_VERSION="18.06.0.ce"

# copy all necessary files
cp -r ${PROVISIONING_DIR}/{salt-ssh,opennebula,docker} ${TMP_DIR}/

# run all necessary variable substitutions
envsubst '$SALT_MASTER_PUBLIC_IP_ADDRESS, $SALT_MASTER_USER' < ${PROVISIONING_DIR}/salt-ssh/roster > ${TMP_DIR}/salt-ssh/roster
envsubst '$OPENNEBULA_ENDPOINT, $OPENNEBULA_SALT_SECRET' < ${PROVISIONING_DIR}/salt-ssh/salt/salt-master/master > ${TMP_DIR}/salt-ssh/salt/salt-master/master
envsubst '$DOCKER_VERSION' < ${PROVISIONING_DIR}/salt-ssh/salt/salt-master/salt/appliance-common.sls > ${TMP_DIR}/salt-ssh/salt/salt-master/salt/appliance-common.sls
envsubst '$SALT_REPO_VERSION' < ${PROVISIONING_DIR}/salt-ssh/salt/salt-master.sls > ${TMP_DIR}/salt-ssh/salt/salt-master.sls
envsubst '$SALT_MASTER_PRIVATE_IP_ADDRESS, $SALT_REPO_PACKAGE' < ${PROVISIONING_DIR}/salt-ssh/salt/lighttpd/contextualization.sh > ${TMP_DIR}/salt-ssh/salt/lighttpd/contextualization.sh
envsubst '$OPENNEBULA_BASE_IMAGE_SIZE, $OPENNEBULA_NFS_IMAGE_ID, $OPENNEBULA_SWAP_IMAGE_ID, $OPENNEBULA_PUBLIC_STUDENT_NETWORK_ID, $OPENNEBULA_PUBLIC_TEACHER_NETWORK_ID, $OPENNEBULA_PUBLIC_NFS_NETWORK_ID, $OPENNEBULA_PRIVATE_NETWORK_ID, $OPENNEBULA_PUBLIC_NETWORK_SECURITY_GROUPS, $OPENNEBULA_PRIVATE_NETWORK_SECURITY_GROUPS, $OPENNEBULA_CPU, $OPENNEBULA_MEMORY, $OPENNEBULA_DEPLOY_CLUSTER_ID, $SALT_MASTER_PRIVATE_IP_ADDRESS' < ${PROVISIONING_DIR}/opennebula/cloudkeeper-one/templates/template.erb > ${TMP_DIR}/opennebula/cloudkeeper-one/templates/template.erb
envsubst '$IMAGEMASTER3000_STUDENT_BRANCH, $IMAGEMASTER3000_TEACHER_BRANCH, $IMAGEMASTER3000_NFS_BRANCH, $IMAGEMASTER3000_STUDENT_GROUP, $IMAGEMASTER3000_TEACHER_GROUP, $IMAGEMASTER3000_NFS_GROUP' < ${PROVISIONING_DIR}/docker/imagemaster3000-compose.yml > ${TMP_DIR}/docker/imagemaster3000-compose.yml
envsubst '$CLOUDKEEPER_PUBLIC_IP, $OPENNEBULA_CLOUDKEEPER_SECRET, $OPENNEBULA_DATASTORE, $CLOUDKEEPER_TEMPLATES_DIR, $OPENNEBULA_ENDPOINT, $OPENNEBULA_IMAGE_FORMAT' < ${PROVISIONING_DIR}/docker/cloudkeeper-compose.yml > ${TMP_DIR}/docker/cloudkeeper-compose.yml

# remove previously created volumes
docker volume rm bio-imagemaster3000_imagemaster3000-images-teacher bio-imagemaster3000_imagemaster3000-images-student bio-imagemaster3000_imagemaster3000-images-nfs
# deploy imagemaster300 stack
docker stack deploy -c ${TMP_DIR}/docker/imagemaster3000-compose.yml bio-imagemaster3000

# wait for images to download
for biotype in nfs student teacher; do
  while true; do
    content_type=$(curl --fail -I --silent http://127.0.0.1:8080/${biotype}/imagemaster3000.list | grep Content-Type | cut -d ' ' -f 2 | tr -d '\r')
    if [ "${content_type}" = "application/octet-stream" ]; then
      break;
    fi
    sleep 30
  done
done

# deploy cloudkeeper stack
docker stack deploy -c ${TMP_DIR}/docker/cloudkeeper-compose.yml bio-cloudkeeper

# wait for appliances to upload
while true; do
  docker stack ps bio-cloudkeeper | grep -v bio-cloudkeeper_cloudkeeper-one | grep -q Shutdown
  if [ $? -eq 0 ]; then
    break;
  fi
  sleep 30
done

# remove all stacks
docker stack rm bio-cloudkeeper
docker stack rm bio-imagemaster3000

# run agentless salt - prepare salt master
pushd ${TMP_DIR}/salt-ssh/
salt-ssh '*' state.apply
popd

# remove tmp directory
rm -rf ${TMP_DIR}
