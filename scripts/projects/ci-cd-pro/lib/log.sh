#!/usr/bin/env bash
log() { echo "[$(date +'%H:%M:%S')] INFO  $*"; }
error() { echo "[$(date +'%H:%M:%S')] ERROR $*" >&2; }
die() {
	error "$*"
	exit 1
}
