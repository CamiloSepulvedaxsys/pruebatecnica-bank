{{/*
Nombre completo de la aplicación
*/}}
{{- define "flask-app.fullname" -}}
{{- .Chart.Name -}}
{{- end -}}

{{/*
Labels comunes para todos los recursos
*/}}
{{- define "flask-app.labels" -}}
app: {{ .Chart.Name }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
release: {{ .Release.Name }}
managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "flask-app.selectorLabels" -}}
app: {{ .Chart.Name }}
release: {{ .Release.Name }}
{{- end -}}
