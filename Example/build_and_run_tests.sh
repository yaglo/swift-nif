#!/usr/bin/env bash

swift build --package-path swift/Base64 && \
    cp swift/Base64/.build/debug/libBase64.dylib priv/native/libBase64.so && \
    mix test
