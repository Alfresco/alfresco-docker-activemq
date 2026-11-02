name: "Bump activemq version"

scms:
  activemq:
    kind: git
    spec:
      url: https://github.com/apache/activemq.git
      branch: main

sources:
  activemqTag:
    name: Get activemq {{ requiredEnv "ACTIVEMQ_MAJOR" }} version
    kind: gittag
    scmid: activemq
    spec:
      versionfilter:
        kind: regex
        pattern: "activemq-{{ requiredEnv "ACTIVEMQ_MAJOR" }}"
    transformers:
      - trimprefix: "activemq-"

conditions:
  archiveReady:
    kind: http
    disablesourceinput: true
    spec:
      url: https://archive.apache.org/dist/activemq/{{ source `activemqTag` }}/apache-activemq-{{ source `activemqTag` }}-bin.tar.gz

targets:
  activemqJson:
    name: Update version in activemq json target
    kind: json
    sourceid: activemqTag
    spec:
      file: versions/activemq-{{ requiredEnv "ACTIVEMQ_MAJOR" }}.json
      key: activemq_version
