#!/bin/bash
echo "helm build setup"
. /docker-build-setup.sh

echo "Using shell $SHELL"
# Switch to the correct Openshift cluster (test/acc or prod)
export SERVER
if [ "$OS_ENV" = "prod" ]; then
   SERVER=$OPENSHIFT_PROD_SERVER
   CONTEXT=pomsp
else
   SERVER=$OPENSHIFT_TEST_SERVER
   CONTEXT=pomst
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

echo "${BASH_VERSION} $LINENO Defining setup_oc_helm function"

function setup_oc_helm() {
 DIR=$1

 echo "Logging in $HARBOR_USER to registry : $HELM_REGISTRY"
 echo  $HARBOR_PASSWORD | helm registry login $HELM_REGISTRY --username $HARBOR_USER --password-stdin

 echo "Pulling chart '$HELM_REPO' '$CHART_PROJECTNAME' '$CHART_VERSION'"
 helm pull $HELM_REPO/$CHART_PROJECT_NAME \
   --version $CHART_VERSION \
   --untar

 VALUES=()
 if [ "$DIR" != "" ] ; then
   if [ -e ./$DIR/helm/values-$OS_ENV.yaml ]; then
      VALUES+=(./$DIR/helm/values-$OS_ENV.yaml)
   else
      echo "No ./$DIR/helm/values-$OS_ENV.yaml found"
   fi
   if [ -e ./$DIR/helm/values.yaml ]; then
      VALUES+=(./$DIR/helm/values.yaml)
   else
       echo "No ./$DIR/helm/values.yaml found"
   fi
 fi
 if [ -e ./values-$OS_ENV.yaml ]; then
    VALUES+=(./values-$OS_ENV.yaml)
 else
    echo "No ./values-$OS_ENV.yaml found"
 fi

 if [ -e ./values.yaml ]; then
    VALUES+=(./values.yaml)
 else
    echo "No ./values.yaml found"
 fi
 export VALUES=$(printf '%s\n' "$(IFS=,; printf '%s' "${VALUES[*]}")")
}

 # defining a bash ansi color (yellow) to make some of this stand out better.
TXT_HI="\e[93m" && TXT_CLEAR="\e[0m"
# deploys application using helm
# $1: The first argument is the directory where the docker file is living.
# The application name will be parsed from ARG NAME

function deploy_application() {
  DIR=$1

  OS_APPLICATION=$(os_app_name $DIR)
  exit_code=$?
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

  export VALUES=""
  if [ -e ./$DIR/helm/values-$OS_ENV.yaml ]; then
    export VALUES=./$DIR/helm/values-$OS_ENV.yaml
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

  echo "Helm upgrade $OS_APPLICATION-$OS_ENV"
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

function deploy_applications() {
  if [ $TRACE = 'true' ] ; then
      helm version
  fi

  if [ -z "$DEPLOY_APPLICATIONS" ]; then
     DEPLOY_APPLICATIONS=$OS_APPLICATIONS
  fi
  if [ -z "$DEPLOY_APPLICATIONS" ]; then
    echo "Deploy the root directory only"
    get_artifact_versions . $PROJECT_VERSION
    deploy_application .
  fi
  for app_dir in $(echo $DEPLOY_APPLICATIONS | sed "s/,/ /g")
  do
    echo deploy application in $app_dir
    get_artifact_versions $app_dir $PROJECT_VERSION
    deploy_application $app_dir
  done
}