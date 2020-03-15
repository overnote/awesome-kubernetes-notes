#!/bin/env bash


$(which pandoc) -s -t rst --toc source/awesome-kubernetes-notes.md -o source/awesome-kubernetes-notes.rst

make html