#!/bin/bash

cd ~

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Please provide an argument:"
    echo "1 -> TinyLlama"
    echo "2 -> phi2"
    echo "3 -> gemma 2B"
    echo "Usage: curl -sL https://raw.githubusercontent.com/your-username/your-repo/main/download_llm.sh | bash -s <argument>"
    exit 1
fi

# Set up model directory
cd llama.cpp/models/
mkdir -p 7B
cd 7B

# Download the model based on the argument
case "$1" in
    1)
        wget https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q5_K_S.gguf?download=true -O ggml-model-f16.gguf
        echo "TinyLlama model downloaded successfully"
        ;;
    2)
        echo "Downloading phi2 model..."
        # Add the URL and download command for phi2 model here
        ;;
    3)
        echo "Downloading gemma 2B model..."
        # Add the URL and download command for gemma 2B model here
        ;;
    *)
        echo "Invalid argument"
        exit 1
        ;;
esac