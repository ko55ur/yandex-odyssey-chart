{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "yandex-odyssey.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "yandex-odyssey.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "yandex-odyssey.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "yandex-odyssey.labels" -}}
helm.sh/chart: {{ include "yandex-odyssey.chart" . }}
{{ include "yandex-odyssey.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "yandex-odyssey.selectorLabels" -}}
app.kubernetes.io/name: {{ include "yandex-odyssey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "yandex-odyssey.serviceAccount" -}}
{{- if .Values.yandex_odyssey.serviceAccount.create }}
{{- default (include "yandex-odyssey.name" .) .Values.yandex_odyssey.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.yandex_odyssey.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Secrets
*/}}
{{- define "secrets.odyssey" -}}
{{- range $key, $val := .Values.yandex_odyssey.secrets }}
  {{ $key }}: {{ $val | b64enc | quote }}
{{- end }}
{{- end -}}

{{/*
yandex-odyssey "image" and "tag" variable representation
*/}}
{{- define "yandex-odyssey.image" -}}
{{- if .Values.common.registry -}}
{{- .Values.common.registry -}}/{{ .Values.yandex_odyssey.image }}:{{ default .Chart.AppVersion .Values.yandex_odyssey.imageTag }}
{{- else -}}
{{- .Values.yandex_odyssey.image -}}:{{ default .Chart.AppVersion .Values.yandex_odyssey.imageTag }}
{{- end -}}
{{- end -}}

{{/*
yandex-odyssey "image" and "tag" variable representation
*/}}
{{- define "yandex-odyssey-exporter.image" -}}
{{- if .Values.common.registry -}}
{{- .Values.common.registry -}}/{{ .Values.yandex_odyssey_exporter.image }}:{{ default .Chart.AppVersion .Values.yandex_odyssey_exporter.imageTag }}
{{- else -}}
{{- .Values.yandex_odyssey_exporter.image -}}:{{ default .Chart.AppVersion .Values.yandex_odyssey_exporter.imageTag }}
{{- end -}}
{{- end -}}

{{/*
Certificates volume
*/}}
{{- define "yandex-odyssey.certsVolume" -}}
{{- if or (ne .Values.yandex_odyssey.tls.odyssey.mode "disable") (ne .Values.yandex_odyssey.tls.postgres1.mode "disable") (ne .Values.yandex_odyssey.tls.postgres2.mode "disable") (ne .Values.yandex_odyssey.tls.postgres3.mode "disable") }}
- name: certs
  secret:
    secretName: {{ include "yandex-odyssey.name" . }}
    items:
{{- if ne .Values.yandex_odyssey.tls.odyssey.mode "disable" }}
    - key: odyssey.key
      path: odyssey.key
    - key: odyssey.crt
      path: odyssey.crt
{{- end }}
{{- if ne .Values.yandex_odyssey.tls.postgres1.mode "disable" }}
    - key: {{ .Values.yandex_odyssey.tls.postgres1.secret_name }}
      path: postgres1-ca.crt
{{- end }}
{{- if ne .Values.yandex_odyssey.tls.postgres2.mode "disable" }}
    - key: {{ .Values.yandex_odyssey.tls.postgres2.secret_name }}
      path: postgres2-ca.crt
{{- end }}
{{- if ne .Values.yandex_odyssey.tls.postgres3.mode "disable" }}
    - key: {{ .Values.yandex_odyssey.tls.postgres3.secret_name }}
      path: postgres3-ca.crt
{{- end }}
{{- end }}
{{- end -}}

{{- define "yandex-odyssey.certsMount" -}}
{{- if or (ne .Values.yandex_odyssey.tls.odyssey.mode "disable") (ne .Values.yandex_odyssey.tls.postgres1.mode "disable") (ne .Values.yandex_odyssey.tls.postgres2.mode "disable") (ne .Values.yandex_odyssey.tls.postgres3.mode "disable") }}
- name: certs
  readOnly: true
  mountPath: "/home/appuser/certs"
{{- end }}
{{- end -}}

{{- define "yandex-odyssey.certsEnv" -}}
- name: ODYSSEY_TLS
  value: {{ .Values.yandex_odyssey.tls.odyssey.mode }}
- name: POSTGRES_TLS1
  value: {{ .Values.yandex_odyssey.tls.postgres1.mode }}
- name: POSTGRES_TLS1_CA_PATH
  value: /home/appuser/certs/postgres1-ca.crt
- name: POSTGRES_TLS2
  value: {{ .Values.yandex_odyssey.tls.postgres2.mode }}
- name: POSTGRES_TLS2_CA_PATH
  value: /home/appuser/certs/postgres2-ca.crt
- name: POSTGRES_TLS3
  value: {{ .Values.yandex_odyssey.tls.postgres3.mode }}
- name: POSTGRES_TLS3_CA_PATH
  value: /home/appuser/certs/postgres3-ca.crt
{{- end -}}

{{/*
yandex-odyssey-exporter connection string 
*/}}

{{- define "odyssey-exporter.string" -}}
{{- $user := .Values.yandex_odyssey.env.ODYSSEY_MONITORING_USER -}}
{{- $pass := .Values.yandex_odyssey.env.ODYSSEY_MONITORING_PASSWORD -}}
{{- $base := .Values.yandex_odyssey_exporter.connection.dbname -}}
{{- $sslmode := .Values.yandex_odyssey_exporter.connection.sslmode -}}
{{- printf "postgres://%s:%s@localhost:5432/%s?%s" $user $pass $base $sslmode | trimSuffix "-" -}}
{{- end -}}
