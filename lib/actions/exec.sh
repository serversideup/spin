#!/usr/bin/env bash
action_exec(){
  shift 1

  $COMPOSE exec $@ 
}