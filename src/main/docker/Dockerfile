FROM jboss/wildfly:15.0.1.Final
# https://hub.docker.com/r/jboss/wildfly
ADD /maven/server.war /opt/jboss/wildfly/standalone/deployments/
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
