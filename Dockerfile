# We define 2 versions - one is the version of docker image that we patch, the second is the release branch suffix
ARG SONATYPE_VERSION=3.36.0
ARG SONATYPE_RELEASE=${SONATYPE_VERSION}-01

FROM alpine:latest AS os

RUN apk add \
  g++ \
  git \
  make \
  nodejs \
  npm \
  openjdk8 \
  python2 \
  yarn

WORKDIR /opt/sonatype
# Declare we want to use global SONATYPE_RELEASE from above
ARG SONATYPE_RELEASE
# We are only interested in the last commit of specific release
RUN git clone --branch release-${SONATYPE_RELEASE} --depth 1 https://github.com/sonatype/nexus-public .

RUN sed -i 's/ document.field(P_CREATED_BY_IP, OType.STRING);/ "127.0.0.1";/g' components/nexus-repository/src/main/java/org/sonatype/nexus/repository/storage/AssetEntityAdapter.java
RUN ./mvnw -T 1C -ntp package -Dmaven.test.skip -DskipTests


FROM sonatype/nexus3:${SONATYPE_VERSION}

ARG SONATYPE_RELEASE
COPY --from=os "/opt/sonatype/components/nexus-repository/target/nexus-repository-${SONATYPE_RELEASE}.jar" "/opt/sonatype/nexus/system/org/sonatype/nexus/nexus-repository/${SONATYPE_RELEASE}/nexus-repository-${SONATYPE_RELEASE}.jar"
