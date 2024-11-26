#!/bin/bash

# Exit on any error
set -e

# Check if the module name argument is provided
if [ -z "$1" ]; then
  echo "Error: No module name provided."
  exit 1
fi

# Get the module name from the first argument
MODULE_NAME=$1

# Restore, build, and publish the project
dotnet restore "./$MODULE_NAME/$MODULE_NAME.csproj" \
  && dotnet build "./$MODULE_NAME/$MODULE_NAME.csproj" \
  && dotnet publish "./$MODULE_NAME/$MODULE_NAME.csproj" -c Release -o "./$MODULE_NAME/publish"

echo "Build completed successfully."