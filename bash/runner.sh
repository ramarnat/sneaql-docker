#!/bin/bash

# support for biscuit secrets management
# provide http path to secrets.yml file via SNEAQL_BISCUIT env var
# all secrets in the file will be decrypted into env vars

if [ -n "$SNEAQL_BISCUIT" ] 
then 
  echo "pulling secrets file $SNEAQL_BISCUIT"
  cd /tmp
  # pull it down
  wget -O secrets.yml $SNEAQL_BISCUIT
  # create a source compatible shell script
  ruby /usr/sbin/source_biscuit.rb secrets.yml
  # source the vars then remove the file
  source secrets.sh
  rm -f secrets.sh
fi

# configure env vars for redshift JDBC driver
# note that in this version only redshift driver is supported

if [ $SNEAQL_DATABASE == 'redshift' ] 
then
  echo "by using this software you agree to Amazon Redshift JDBC Driver License Agreement https://s3.amazonaws.com/redshift-downloads/drivers/Amazon+Redshift+JDBC+Driver+License+Agreement.pdf"
  export SNEAQL_JDBC_DRIVER_JAR=/jars/RedshiftJDBC4-1.1.6.1006.jar
  export SNEAQL_JDBC_DRIVER_CLASS=com.amazon.redshift.jdbc4.Driver
fi

# https user/pass authenticated git repos are supported
# only the specified branch is cloned

if [ -n "$SNEAQL_GIT_REPO" ] 
then 
  echo "pulling git repo $SNEAQL_GIT_REPO branch $SNEAQL_GIT_REPO_BRANCH"
  
  # a QD ruby script creates the fully authenticated https url
  GIT_HTTPS_URL_WITH_AUTH=`ruby /usr/sbin/git_clone_url.rb $SNEAQL_GIT_REPO $SNEAQL_GIT_USER $SNEAQL_GIT_PASSWORD`
  
  # repo is cloned with --quiet to obscure the credentials
  cd /tmp
  git clone $GIT_HTTPS_URL_WITH_AUTH --branch $SNEAQL_GIT_REPO_BRANCH --single-branch --quiet ./repo 
fi

cd /tmp/repo

# execute the transform in the current working directory
sneaql exec .