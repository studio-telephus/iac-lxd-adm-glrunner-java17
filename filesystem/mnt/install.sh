#!/usr/bin/env bash
: "${GITLAB_RUNNER_REGISTRATION_KEY?}"
: "${GIT_SA_USERNAME?}"
: "${GIT_SA_TOKEN?}"

##
echo "Install the base tools"

apt-get update
apt-get install -y \
 curl vim wget htop unzip gnupg2 netcat-traditional \
 bash-completion git software-properties-common

## Run pre-install scripts
sh /mnt/setup-ca.sh


##
echo "Install GitLab Runner"

# Add the official GitLab repository
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

# Disable skel & install
export GITLAB_RUNNER_DISABLE_SKEL=true
apt-get install gitlab-runner -y

echo "Register GitLab Runner"
gitlab-runner register \
    --non-interactive \
    --url https://gitlab.adm.acme.corp/gitlab \
    --registration-token "$GITLAB_RUNNER_REGISTRATION_KEY" \
    --tag-list "java17" \
    --executor shell

export cred_home="/home/gitlab-runner"

echo "Create GitLab credentials file"
cat << EOF > ${cred_home}/.my-git-credentials
https://${GIT_SA_USERNAME}:${GIT_SA_TOKEN}@gitlab.adm.acme.corp
EOF

echo "Set ownership & permissions of .my-git-credentials"
chmod 644 ${cred_home}/.my-git-credentials

echo "Add Github credentials to git global config file"
cat << EOF > ${cred_home}/.gitconfig
[credential]
	helper = store --file ${cred_home}/.my-git-credentials
[user]
	user = ${GIT_SA_USERNAME}
	email = ${GIT_SA_USERNAME}@mail.adm.acme.corp
EOF

echo "Set ownership & permissions"
chmod 644 ${cred_home}/.gitconfig
chown -R gitlab-runner:gitlab-runner /home/gitlab-runner

##
echo "Install JDK"

### Import the Corretto public key and then add the repository to the system list
wget -O - https://apt.corretto.aws/corretto.key | gpg --dearmor -o /usr/share/keyrings/corretto-keyring.gpg && \
echo "deb [signed-by=/usr/share/keyrings/corretto-keyring.gpg] https://apt.corretto.aws stable main" | tee /etc/apt/sources.list.d/corretto.list

### After the repo has been added, you can install Corretto 17
apt-get update
apt-get install -y java-17-amazon-corretto-jdk

### Verify the installation
java -version
