FROM gitlab/gitlab-runner:ubuntu-v17.0.0
COPY ./filesystem /.
COPY ./filesystem-shared-ca-certificates /.

RUN bash /mnt/pre-install.sh
RUN bash /mnt/setup-ca.sh
RUN bash /mnt/install-tools.sh
