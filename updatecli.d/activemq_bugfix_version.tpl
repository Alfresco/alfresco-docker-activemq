name: "Bump activemq versions"

scms:
  activemqGitHub:
    kind: "git"
    spec:
      url: https://github.com/apache/activemq.git
      branch: main

sources:
  activemqTag:
    name: Get activemq version
    kind: gittag
    scmid: activemqGitHub
    spec:
      versionfilter:
        kind: regex
        pattern: "activemq-{{ requiredEnv "ACTIVEMQ_BASE_VERSION" }}"
    transformers:
      - trimprefix: "activemq-"

targets:
  activemqJson:
    name: Update version in json target
    kind: json
    sourceid: activemqTag
    spec:
      file: versions/activemq-{{ requiredEnv "ACTIVEMQ_BASE_VERSION" }}.json
      key: activemq_version
