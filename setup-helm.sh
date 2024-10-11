#!/bin/sh
echo "helm build setup"
source /docker-build-setup.sh

echo "Using shell $SHELL"
# Switch to the correct Openshift cluster (test/acc or prod)
if [ "$OS_ENV" == "prod" ]; then
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

 echo "Logging in to registry : $HELM_REGISTRY"
 echo  $HARBOR_PASSWORD | helm registry login $HELM_REGISTRY --username $HARBOR_USER --password-stdin

 echo "Pulling chart $HELM_REPO $CHART_PROJECTNAME $CHART_VERSION"
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
