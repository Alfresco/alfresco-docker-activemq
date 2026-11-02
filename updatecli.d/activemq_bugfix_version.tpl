{{ $activemqVersions := list "6.2" "5.19" "5.18" "5.17" }}

{{ range $activemqVersion := $activemqVersions }}
---
name: "Bump activemq {{ $activemqVersion }} version"

scms:
  github:
    kind: github
    spec:
      owner: alfresco
      repository: alfresco-docker-activemq
      branch: master
      token: {{ requiredEnv "UPDATECLI_GITHUB_TOKEN" }}
      username: {{ requiredEnv "UPDATECLI_GITHUB_USERNAME" }}
      user: {{ requiredEnv "UPDATECLI_GITHUB_USERNAME" }}
      email: {{ requiredEnv "UPDATECLI_GITHUB_EMAIL" }}
  activemq:
    kind: git
    spec:
      url: https://github.com/apache/activemq.git
      branch: main

sources:
  activemqTag:
    name: Get activemq {{ $activemqVersion }} version
    kind: gittag
    scmid: activemq
    spec:
      versionfilter:
        kind: regex
        pattern: "activemq-{{ $activemqVersion }}"
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
    name: Update version in activemq {{ $activemqVersion }} json target
    kind: json
    sourceid: activemqTag
    scmid: github
    spec:
      file: versions/activemq-{{ $activemqVersion }}.json
      key: activemq_version

actions:
  pr:
    kind: github/pullrequest
    scmid: github
    spec:
      title: Bump activemq {{ $activemqVersion }} to {{ source `activemqTag` }}
      labels:
        - updatecli
      reviewers:
        - Alfresco/alfresco-ops-readiness
{{ end }}
