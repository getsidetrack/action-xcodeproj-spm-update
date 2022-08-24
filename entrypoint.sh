#!/bin/bash
set -e

# Load Options
while getopts "a:b:c:d:" o; do
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
  esac
done

# Change Directory
if [ "$directory" != "." ]; then
	echo "Changing directory to '$directory'."
	cd $directory
fi

# Identify `Package.resolved` location
RESOLVED_PATH=$(find . -type f -name "Package.resolved" | grep -v "*/*.xcodeproj/*")
CHECKSUM=$(shasum "$RESOLVED_PATH")

echo "Identified Package.resolved at '$RESOLVED_PATH'."

# If `forceResolution`, then delete the `Package.resolved`
if [ "$forceResolution" = true ] || [ "$forceResolution" = 'true' ]; then
	echo "Deleting Package.resolved to force it to be regenerated under new format."
	rm -rf "$RESOLVED_PATH" 2> /dev/null
fi

# Cleanup Caches
DERIVED_DATA=$(xcodebuild -showBuildSettings -disableAutomaticPackageResolution -disablePackageRepositoryCache | grep -m 1 BUILD_DIR | grep -oE "\/.*" | sed 's|/Build/Products||')
rm -rf "$DERIVED_DATA"

# Should be mostly redundant as we use the disable cache flag.
SPM_CACHE="~/Library/Caches/org.swift.swiftpm/"
rm -rf "$CACHE_PATH"

# Resolve Dependencies
echo "::group::xcodebuild resolve dependencies"
xcodebuild -resolvePackageDependencies -disablePackageRepositoryCache
echo "::endgroup"

# Determine Changes
NEWCHECKSUM=$(shasum "$RESOLVED_PATH")

if [ "$CHECKSUM" != "$NEWCHECKSUM" ]; then
	echo "::set-output name=dependenciesChanged::true"

	if [ "$failWhenOutdated" = true ] || [ "$failWhenOutdated" = 'true' ]; then
		exit 1
	fi
else
	echo "::set-output name=dependenciesChanged::false"
fi