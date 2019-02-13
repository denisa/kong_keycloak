FROM kong:1.0.3-centos

RUN yum install -y git unzip && yum clean all

RUN luarocks install kong-oidc
