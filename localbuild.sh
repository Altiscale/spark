#!/bin/bash

xmake -cie --debug-xmake --buildruntime linuxx86_64 \
    -I DOCKER=docker.wdf.sap.corp:50002
