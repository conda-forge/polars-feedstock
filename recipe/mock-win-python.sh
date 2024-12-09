#!/bin/bash

PY_MINOR=$(echo ${PY_VER}| cut -d. -f2)

echo "{\"implementation_name\": \"cpython\", \"executable\": \"${PYTHON}\", \"major\": 3, \"minor\": ${PY_MINOR}, \"abiflags\": null, \"interpreter\": \"cpython\", \"ext_suffix\": \".cp3${PY_MINOR}-win_amd64.pyd\", \"soabi\": null, \"platform\": \"win-amd64\", \"system\": \"windows\", \"pointer_width\": 64, \"gil_disabled\": false}"
