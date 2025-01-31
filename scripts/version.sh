#!/bin/bash

set -eu

VERSION_REGEX='[0-9]{1,2}\.[0-9]{1}\.[0-9]{1}$'

# Validate script parameters
if [ -z "$OLD_VERSION" ]; then
    echo "OLD_VERSION must be set (e.g. 8.0.0). Exiting..."
    exit 1
fi

if [ -z "$NEW_VERSION" ]; then
    echo "NEW_VERSION must be set (e.g. 8.0.0). Exiting..."
    exit 1
fi

if ! echo $OLD_VERSION | grep -Eq $VERSION_REGEX; then 
    echo "OLD_VERSION must be of form {major}.{minor}.{patch} (e.g. 8.0.0). Exiting..."
fi 

if ! echo $NEW_VERSION | grep -Eq $VERSION_REGEX; then 
    echo "NEW_VERSION must be of form {major}.{minor}.{patch} (e.g. 8.0.0). Exiting..."
fi 

if [ "$(basename "$PWD")" != "stride" ]; then
    echo "The script must be run from the project home directory. Exiting..."
fi

# Update version 
CONFIG_FILE=cmd/strided/config/config.go
APP_FILE=app/app.go

sed -i '' "s/$OLD_VERSION/$NEW_VERSION/g" $CONFIG_FILE
sed -i '' "s/$OLD_VERSION/$NEW_VERSION/g" $APP_FILE

git add $CONFIG_FILE $APP_FILE
git commit -m "updated version from $OLD_VERSION to $NEW_VERSION"


# Update package name
OLD_MAJOR_VERSION=v$(echo "$OLD_VERSION" | cut -d '.' -f 1)
NEW_MAJOR_VERSION=v$(echo "$NEW_VERSION" | cut -d '.' -f 1)

for parent_directory in "app" "cmd" "proto" "testutil" "third_party" "utils" "x"; do
    for file in $(find $parent_directory -type f \( -name "*.go" -o -name "*.proto" \)); do 
        echo "Updating version in $file"
        sed -i '' "s|github.com/Stride-Labs/stride/$OLD_MAJOR_VERSION|github.com/Stride-Labs/stride/$NEW_MAJOR_VERSION|g" $file
    done
done

sed -i '' "s|github.com/Stride-Labs/stride/$OLD_MAJOR_VERSION|github.com/Stride-Labs/stride/$NEW_MAJOR_VERSION|g" go.mod

git add .
git commit -m "updated package from $OLD_MAJOR_VERSION -> $NEW_MAJOR_VERSION"


# Re-generate protos
make proto-all

git add .
git commit -m 'generated protos'

