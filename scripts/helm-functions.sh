#!/bin/bash
CHART_PROJECT_NAME=${CHART_PROJECT_NAME:-openshift-chart}
CHART_VERSION=${CHART_VERSION:-3.4}
TRACE=${TRACE:-false}

OS_PROJECT=${OS_PROJECT:-poms}
OS_ENV=${OS_ENV:-test}
OS_STORAGE_TYPE=${OS_STORAGE_TYPE:-ocs-storagecluster-ceph-rbd}

HELM_REPO=${HELM_REPO:-oci://registry.npohosting.nl/poms}
REGISTRY=${REGISTRY:-registry.npohosting.nl}
HELM_REGISTRY=${HELM_REGISTRY:-https://$REGISTRY}

OC_CONTEXT_PROD=${OC_CONTEXT_PROD:=pomsp}
OC_CONTEXT_TEST=${OC_CONTEXT_TEST:=pomst}
NAMESPACE=${NAMESPACE:-poms}


echo "helm build setup"
if ! type os_app_name &> /dev/null ; then
. "$KANIKO_SCRIPTS"dockerfile-functions.sh
fi

echo "Using shell $SHELL"

login_oc() {
  # Switch to the correct Openshift cluster (test/acc or prod)
  export SERVER
  if [ "$OS_ENV" = "prod" ]; then
     SERVER=$OPENSHIFT_PROD_SERVER
     CONTEXT=$OC_CONTEXT_PROD
  else
     SERVER=$OPENSHIFT_TEST_SERVER
     CONTEXT=$OC_CONTEXT_TEST
  fi

  if [ "$KUBECONFIG" != "" ]; then
     echo "Fixing permissions on $KUBECONFIG"
     chmod 700 $KUBECONFIG # avoid warning about permissions (https://gitlab.com/gitlab-org/gitlab/-/issues/363057)
  fi

   # - Make sure we are oc logged in.
  #   using KUBECONFIG and CONTEXT
  # - We selected the desired project $OS_PROJECT-$OS_ENV
  # - The variable VALUES is resolved to a comma separated list of relevant values.yaml files
  #   The first argument can be a sub directory
  echo "Using helm $(helm version)"
  oc config use-context $CONTEXT
  oc project $OS_PROJECT-$OS_ENV
  oc projects
}

echo "Defining setup_oc_helm function"

setup_oc_helm() {
 DIR=$1

 echo "Logging in $HARBOR_USER to registry : $HELM_REGISTRY"
 echo  $HARBOR_PASSWORD | helm registry login $HELM_REGISTRY --username $HARBOR_USER --password-stdin

 echo "Pulling chart '$HELM_REPO' '$CHART_PROJECTNAME' '$CHART_VERSION'"
 helm pull $HELM_REPO/$CHART_PROJECT_NAME \
   --version $CHART_VERSION \
   --untar

 VALUESA=()
 if [ "$DIR" != "" ] ; then
   if [ -e ./$DIR/helm/values-$OS_ENV.yaml ]; then
      VALUESA+=("./$DIR/helm/values-$OS_ENV.yaml")
   else
      echo "No ./$DIR/helm/values-$OS_ENV.yaml found"
   fi
   if [ -e ./$DIR/helm/values.yaml ]; then
      VALUESA+=("./$DIR/helm/values.yaml")
   else
       echo "No ./$DIR/helm/values.yaml found"
   fi
 fi
 if [ -e ./values-$OS_ENV.yaml ]; then
    VALUESA+=("./values-$OS_ENV.yaml")
 else
    echo "No ./values-$OS_ENV.yaml found"
 fi

 if [ -e ./values.yaml ]; then
    VALUESA+=(./values.yaml)
 else
    echo "No ./values.yaml found"
 fi
 export VALUES
 VALUES=$(printf '%s\n' "$(IFS=,; printf '%s' "${VALUESA[*]}")")
}

# deploys application using helm
# $1: The first argument is the directory where the docker file is living.
# The application name will be parsed from ARG NAME

deploy_application() {
  DIR=$1
  echo "Deploy application in $DIR"
  OS_APPLICATION=$(os_app_name $DIR)
  exit_code=$?
  echo "Deploy application in $DIR -> $OS_APPLICATION"
  if [[ $exit_code != '0' ]] ; then
    echo "Error with os_app_name function $exit_code"
    exit $exit_code
  fi


  if [[ -z $OS_STORAGE_TYPE && $CHART_PROJECT_NAME = 'openshift-chart' ]]; then
    echo "Variable 'OS_STORAGE_TYPE' should not be empty for stateful set deployments ($CHART_PROJECT_NAME)"
    echo "Choose either 'gp2' (old projects) or 'ocs-storagecluster-ceph-rbd' (new projects)"
    exit 1
  fi

  echo "Deploying \"$OS_APPLICATION\" v \"$PROJECT_VERSION\" to \"$OS_PROJECT-$OS_ENV\""

  sed -i "/^appVersion: .*$/cappVersion: $PROJECT_VERSION" $CHART_PROJECT_NAME/Chart.yaml

  rm -rf $CHART_PROJECT_NAME/config

  # The config dir should contain just files
  if [ -d $DIR/helm/config ];
  then
    echo "Applying config: \"$DIR/helm/config\""
    cp -Rv $DIR/helm/config $CHART_PROJECT_NAME
  fi

  # allow override for given env
  if [ -d $DIR/helm/config-$OS_ENV ];
  then
     mkdir -p $CHART_PROJECT_NAME/config
     echo "Applying config: \"$DIR/helm/config-$OS_ENV/*\""
     cp -Rvf $DIR/helm/config-$OS_ENV/* $CHART_PROJECT_NAME/config
   fi


  rm -rf $CHART_PROJECT_NAME/configMaps
  # The configMaps dir should contain just directories (with just files)

  if [ -d $DIR/helm/configMaps ];
  then
    echo "Applying configMaps: \"$DIR/helm/configMaps\""
    cp -Rv $DIR/helm/configMaps $CHART_PROJECT_NAME
  fi

  if [ -d $DIR/helm/configMaps-$OS_ENV ];
  then
    mkdir -p $CHART_PROJECT_NAME/configMaps
    echo "Applying configMaps: \"$DIR/helm/configMaps-$OS_ENV/*\""
    cp -Rv $DIR/helm/configMaps-$OS_ENV/* $CHART_PROJECT_NAME/configMaps
  fi

  export VALUES=()
  if [ -e ./$DIR/helm/values-$OS_ENV.yaml ]; then
    export VALUES=("./$DIR/helm/values-$OS_ENV.yaml")
  else
    echo "No ./$DIR/helm/values-$OS_ENV.yaml found"
  fi
  if [ -e ./$DIR/helm/values.yaml ]; then
    if [ -z "$VALUES" ]; then
      export VALUES=./$DIR/helm/values.yaml
    else
       export VALUES=./$DIR/helm/values.yaml,$VALUES
    fi
  else
    echo "No ./$DIR/helm/values.yaml found"
  fi
  echo value files: $VALUES


  if [ "$TRACE" = 'true' ] ; then
    echo Calling helm template --debug
    helm template  $OS_APPLICATION-$OS_ENV \
    --debug  \
    --values $VALUES \
    --set application.project=$OS_PROJECT \
    --set application.name=$OS_APPLICATION \
    --set application.storage_type=$OS_STORAGE_TYPE \
    --set container.image=$IMAGE \
    --set application.environment=$OS_ENV \
    ./$CHART_PROJECT_NAME --version $CHART_VERSION
  fi

  echo "Helm upgrade $OS_APPLICATION-$OS_ENV $IMAGE"
  helm upgrade --install $OS_APPLICATION-$OS_ENV \
    --history-max 3 \
    --values $VALUES \
    --set application.project=$OS_PROJECT \
    --set application.name=$OS_APPLICATION \
    --set application.storage_type=$OS_STORAGE_TYPE \
    --set container.image=$IMAGE \
    --set application.environment=$OS_ENV \
    ./$CHART_PROJECT_NAME --version $CHART_VERSION


  if [ $CHART_PROJECT_NAME = 'openshift-chart' ] ; then
    echo -e "${TXT_HI}Force restarting for stateful set $OS_PROJECT-$OS_ENV:$OS_APPLICATION now${TXT_CLEAR}"
    oc -n $OS_PROJECT-$OS_ENV  rollout restart statefulset/$OS_APPLICATION
  elif [ $CHART_PROJECT_NAME = 'openshift-chart-deployment' ] ; then
    echo -e "${TXT_HI}Force restarting for deployment $OS_PROJECT-$OS_ENV:$OS_APPLICATION now${TXT_CLEAR}"
    oc -n $OS_PROJECT-$OS_ENV rollout restart deployments/$OS_APPLICATION
  fi
}

deploy_applications() {
  if [ $TRACE = 'true' ] ; then
      helm version
  fi

  if [ -z "$DEPLOY_APPLICATIONS" ]; then
    echo "No DEPLOY_APPLICATIONS defined. Taking it from OS_APPLICATIONS=${OS_APPLICATIONS}"
     DEPLOY_APPLICATIONS=$OS_APPLICATIONS
  fi
  if [ -z "$DEPLOY_APPLICATIONS" ]; then
    echo "Deploy the root directory only"
    get_docker_image_name . $PROJECT_VERSION
    deploy_application .
  else
    echo -e "Deploying ${TXT_HI}${DEPLOY_APPLICATIONS}${TXT_CLEAR}"
    pwd
    #ls
    for app_dir in ${DEPLOY_APPLICATIONS//,/ } ; do
      echo deploy application in $app_dir
      get_docker_image_name $app_dir $PROJECT_VERSION
      deploy_application $app_dir
    done
  fi
}