#!/usr/bin/env bash
# scripts/projects/ci-cd-pro/lib/helpers.sh
# Shared utility functions for the CI/CD pipeline

log() {
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] [INFO] $*"
}

log_error() {
	echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $*" >&2
}

retry() {
	local max_attempts=${1:-3}
	shift
	local attempt=1
	while ((attempt <= max_attempts)); do
		"$@" && return 0
		log "Attempt $attempt failed. Retrying in 5s..."
		sleep 5
		((attempt++))
	done
	log_error "Command failed after $max_attempts attempts: $*"
	return 1
}
