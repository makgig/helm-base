{{/*
----------------------------------------
Основные хелперы для именования
----------------------------------------
*/}}

{{/*
Базовое имя приложения
Используется как основа для именования ресурсов
*/}}
{{- define "base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Полное имя приложения
Комбинирует имя релиза и чарта, используется для уникальной идентификации инсталляции
*/}}
{{- define "base.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Создает имя чарта для использования в метках
*/}}
{{- define "base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
----------------------------------------
Хелперы для работы с метками
----------------------------------------
*/}}

{{/*
Общие метки, используемые всеми ресурсами
*/}}
{{- define "base.labels" -}}
helm.sh/chart: {{ include "base.chart" . }}
{{ include "base.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Селекторы для подов и сервисов
*/}}
{{- define "base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- with .component }}
app.kubernetes.io/component: {{ . }}
{{- end }}
{{- end -}}


{{/*
----------------------------------------
Хелперы для сервисных аккаунтов
----------------------------------------
*/}}

{{/*
Имя сервисного аккаунта
*/}}
{{- define "base.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "base.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
----------------------------------------
Хелперы для проверки условий
----------------------------------------
*/}}

{{/*
Проверка обязательных значений
Использование: include "base.validateRequired" (dict "value" .Values.something "field" "something" "context" $)
*/}}
{{- define "base.validateRequired" -}}
{{- if not .value -}}
{{- fail (printf "Error: Field '%s' is required" .field) -}}
{{- end -}}
{{- end -}}

{{/*
Проверка диапазона значений
Использование: include "base.validateRange" (dict "value" .Values.someNumber "min" 1 "max" 100 "field" "someNumber" "context" $)
*/}}
{{- define "base.validateRange" -}}
{{- if and (not (empty .value)) (or (lt .value .min) (gt .value .max)) -}}
{{- fail (printf "Error: Field '%s' must be between %v and %v" .field .min .max) -}}
{{- end -}}
{{- end -}}

{{/*
----------------------------------------
Утилитарные хелперы
----------------------------------------
*/}}

{{/*
Генерация имени компонента с учетом релиза
*/}}
{{- define "base.componentName" -}}
{{- $name := include "base.fullname" .context -}}
{{- printf "%s-%s" $name .component | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Хелпер для формирования строки образа контейнера
Использует локальные настройки образа с возможностью fallback на глобальные настройки
Пример использования:
include "base.container.image" (dict "local" $values.image "global" $.Values.image)
*/}}
{{- define "base.container.image" -}}
{{- $localImage := .local | default dict }}
{{- $globalImage := .global | default dict }}
{{- $repository := $localImage.repository | default $globalImage.repository }}
{{- $tag := $localImage.tag | default $globalImage.tag | default "latest" }}
{{- printf "%s:%s" $repository $tag }}
{{- end -}}

{{/*
Хелпер для конфигурации портов контейнера
Поддерживает множественные порты с разными протоколами
Пример использования:
include "base.container.ports" (dict "ports" $values.ports)
*/}}
{{- define "base.container.ports" -}}
{{- range .ports }}
- name: {{ .name | default "http" }}
  containerPort: {{ .containerPort }}
  protocol: {{ .protocol | default "TCP" }}
  {{- if .hostPort }}
  hostPort: {{ .hostPort }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Хелпер для настройки ресурсов с дефолтными значениями
*/}}
{{- define "base.container.resources" -}}
{{- $values := .values | default dict }}
{{- $defaults := .defaults | default dict }}
requests:
  cpu: {{ $values.requests.cpu | default $defaults.requests.cpu | default "100m" }}
  memory: {{ $values.requests.memory | default $defaults.requests.memory | default "128Mi" }}
{{- with $values.limits | default $defaults.limits }}
limits:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}