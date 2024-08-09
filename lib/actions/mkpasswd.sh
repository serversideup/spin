#!/usr/bin/env bash
action_mkpasswd(){
  docker run --rm -it serversideup/mkpasswd "$@"
}