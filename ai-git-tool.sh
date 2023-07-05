#!/bin/bash

#--------------------------------------
# Author: Harish Garg (https://twitter.com/harishkgarg)
# Date: 2023-07-05
# Version: 1.0
# Description: 
# This bash script checks for the availability of 'jq' and OpenAI API key,
# and then uses git diff and OpenAI's GPT-4 API to generate commit messages.
# The commit message is generated based on differences detected by git.
# Please ensure that 'jq' is installed and OpenAI API key is set in the 
# environment before running this script.
#--------------------------------------

echo "Script started."

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "The jq utility is not installed. Please install it to proceed."
    echo "You can typically install it using your package manager, for instance:"
    echo "    sudo apt-get install jq    # Ubuntu"
    echo "    brew install jq            # macOS"
    exit 1
fi

echo "jq is installed."

# Check if API key is present in the environment
if [ -z "$OPENAI_API_KEY" ]; then
    echo "The OpenAI API key is not present in the environment."
    echo "Please add it to your environment variables."
    echo "You can add it to your .bashrc or .bash_profile like so:"
    echo "    export OPENAI_API_KEY=your_api_key_here"
    exit 1
fi

echo "OpenAI API Key is set in the environment."

# Use Git to get diff
DIFF=$(git diff) || {
    echo "Failed to get git diff. Are you in a git repository?"
    exit 1
}

echo "Got git diff."

# If DIFF is empty, try git diff --staged
if [ -z "$DIFF" ]; then
    DIFF=$(git diff --staged) || {
        echo "Failed to get git diff --staged. Are you in a git repository?"
        exit 1
    }
fi

echo "Got git diff --staged."

# If DIFF is still empty, notify the user and exit
if [ -z "$DIFF" ]; then
    echo "No differences detected. No commit message to generate."
    exit 0
fi

echo "Differences detected."

# Print DIFF
echo "Git diff:"
echo "$DIFF"

# Get the API key from the environment variable
API_KEY=$OPENAI_API_KEY

# Prepare API request
read -r -d '' REQUEST <<EOF
{
  "model": "gpt-4",
  "messages": [
    {"role": "system", "content": "You are an assistant that generates a commit message given a git diff."},
    {"role": "user", "content": $(echo "$DIFF" | jq -Rs .)}
  ]
}
EOF

# Print the request
echo "API request:"
echo "$REQUEST"

echo "API request prepared."

# Call GPT-3 API and get the response
echo "Calling OpenAI API..."
RESPONSE=$(curl -v -s -H "Content-Type: application/json" -H "Authorization: Bearer $API_KEY" -d "$REQUEST" "https://api.openai.com/v1/chat/completions") || {
    echo "API call failed. Please check your internet connection and API key."
    exit 1
}

echo "API response:"
echo "$RESPONSE"

echo "API response received."


# Extract commit message from the response using jq
COMMIT_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content')

# Print the commit message
echo "Generated commit message:"
echo $COMMIT_MSG
