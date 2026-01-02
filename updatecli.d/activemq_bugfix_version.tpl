name: "Bump activemq versions"

{{ $activemqVersions := list "6.2" "5.19" "5.18" "5.17" }}

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
{{ range $activemqVersion := $activemqVersions }}
  activemq{{ $activemqVersion }}Tag:
    name: Get activemq {{ $activemqVersion }} version
    kind: gittag
    scmid: activemq
    spec:
      versionfilter:
        kind: regex
        pattern: "activemq-{{ $activemqVersion }}"
    transformers:
      - trimprefix: "activemq-"
{{ end }}

conditions:
{{ range $activemqVersion := $activemqVersions }}
{{ $activemqSourceRef := printf "activemq%sTag" $activemqVersion }}
  archive{{ $activemqVersion }}Ready:
    kind: http
    disablesourceinput: true
    spec:
      url: https://archive.apache.org/dist/activemq/{{ source $activemqSourceRef }}/apache-activemq-{{ source $activemqSourceRef }}-bin.tar.gz
{{ end }}

targets:
{{ range $activemqVersion := $activemqVersions }}
  activemq{{ $activemqVersion }}Json:
    name: Update version in activemq {{ $activemqVersion }} json target
    kind: json
    sourceid: activemq{{ $activemqVersion }}Tag
    scmid: github
    spec:
      file: versions/activemq-{{ $activemqVersion }}.json
      key: activemq_version
{{ end }}


actions:
  pr:
    kind: github/pullrequest
    scmid: github
    spec:
      title: Bump Activemq versions
      labels:
        - updatecli
      reviewers:
        - Alfresco/alfresco-ops-readiness
