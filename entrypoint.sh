#!/bin/bash
set -e

# Load Options
while getopts "a:b:c:d:e:f:" o; do
  case "${o}" in
  a)
    export directory=${OPTARG}
    ;;
  b)
    export forceResolution=${OPTARG}
    ;;
  c)
    export failWhenOutdated=${OPTARG}
    ;;
  d)
    if [ ! -z "${OPTARG}" ]; then
      export DEVELOPER_DIR="${OPTARG}"
    fi
    ;;
  e)
    export workspaceName=${OPTARG}
    ;;
  f)
    export scheme=${OPTARG}
    ;;
  esac
done

# Input Validation
if [ ! -z "$workspaceName" ] && [ -z "$scheme" ]; then
  echo "::error::Your action specifies a workspace name but does not define a scheme. You must provide both when using the workspace option."
  exit 1
fi

# Change Directory
if [ "$directory" != "." ]; then
  echo "Changing directory to '$directory'."
  cd $directory
fi

# Identify `Package.resolved` location
if [ ! -z "$workspaceName" ]; then
  RESOLVED_PATH=$(find $workspaceName -type f -name "Package.resolved" | grep -v "*/*.xcworkspace/*")
else
  RESOLVED_PATH=$(find . -type f -name "Package.resolved" | grep -v "*/*.xcodeproj/*")
fi

CHECKSUM=$(shasum "$RESOLVED_PATH")
echo "Identified Package.resolved at '$RESOLVED_PATH'."
echo "Checksum: $CHECKSUM."

# Define Xcodebuild Inputs
if [ ! -z "$workspaceName" ]; then
  xcodebuildInputs="-workspace $workspaceName -scheme $scheme"
else
  xcodebuildInputs=""
fi

# Cleanup Caches
DERIVED_DATA=$(xcodebuild ${xcodebuildInputs} -showBuildSettings -disableAutomaticPackageResolution -skipPackageUpdates | grep -m 1 BUILD_DIR | grep -oE "\/.*" | sed 's|/Build/Products||')
rm -rf "$DERIVED_DATA"

# If `forceResolution`, then delete the `Package.resolved`
if [ "$forceResolution" = true ] || [ "$forceResolution" = 'true' ]; then
  echo "Deleting Package.resolved to force it to be regenerated under new format."
  rm -rf "$RESOLVED_PATH" 2>/dev/null
fi

# Should be mostly redundant as we use the disable cache flag.
SPM_CACHE="~/Library/Caches/org.swift.swiftpm/"
rm -rf "$SPM_CACHE"

# Resolve Dependencies
echo "::group::xcodebuild resolve dependencies"
xcodebuild ${xcodebuildInputs} -resolvePackageDependencies -disablePackageRepositoryCache
echo "::endgroup"

# Determine Changes
NEWCHECKSUM=$(shasum "$RESOLVED_PATH")

if [ "$CHECKSUM" != "$NEWCHECKSUM" ]; then
  echo "dependenciesChanged=true" >> $GITHUB_OUTPUT

  if [ "$failWhenOutdated" = true ] || [ "$failWhenOutdated" = 'true' ]; then
    exit 1
  fi
else
  echo "dependenciesChanged=false" >> $GITHUB_OUTPUT
fi
