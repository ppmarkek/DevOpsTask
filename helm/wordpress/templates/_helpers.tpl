{{- define "wordpress.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wordpress.fullname" -}}
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

{{- define "wordpress.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "wordpress.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "wordpress.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wordpress.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "wordpress.dbHost" -}}
{{- if .Values.wordpress.db.host }}
{{- .Values.wordpress.db.host }}
{{- else }}
{{- printf "%s-mariadb" .Release.Name }}
{{- end }}
{{- end }}

{{- define "wordpress.dbPassword" -}}
{{- if .Values.standaloneMariadb.enabled }}
{{- .Values.standaloneMariadb.password }}
{{- else }}
{{- .Values.wordpress.db.password }}
{{- end }}
{{- end }}
