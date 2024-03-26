#!/bin/bash
termux-setup-storage & PM_PROCESS=$!
(echo "GRANT"; sleep 1; echo "ALLOW") | pm grant com.termux 'android.permission.WRITE_EXTERNAL_STORAGE' >/dev/null 2>&1
wait $PM_PROCESS
apt update
yes | apt upgrade
yes | pkg install clang wget cmake
wget https://github.com/ggerganov/llama.cpp/archive/refs/tags/b2144.zip
unzip b2144.zip
mv llama.cpp-b2144 llama.cpp
cd llama.cpp
make
echo "Environment is set up successfully"