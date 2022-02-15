#!/bin/bash
set -e

# Load Options
while getopts "a:b:c:" o; do
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
  esac
done

# Change Directory
if [ "$directory" != "." ]; then
	echo "Changing directory to '$directory'."
	cd $directory
fi

# Identify `Package.resolved` location
RESOLVED_PATH=$(find . -type f -name "Package.resolved" | grep -v "*/*.xcodeproj/*")
CHECKSUM=$(md5sum "$RESOLVED_PATH")

echo "Identified Package.resolved at '$RESOLVED_PATH'."

# If `forceResolution`, then delete the `Package.resolved`
if [ "$forceResolution" = true ] || [ "$forceResolution" = 'true' ]; then
	echo "Deleting Package.resolved to force it to be regenerated under new format."
	rm -rf "$RESOLVED_PATH" 2> /dev/null
fi

# Cleanup Caches
DERIVED_DATA=$(xcodebuild -showBuildSettings -disableAutomaticPackageResolution | grep -m 1 BUILD_DIR | grep -oE "\/.*" | sed 's|/Build/Products||')
SPM_CACHE="~/Library/Caches/org.swift.swiftpm/"

rm -rf "$DERIVED_DATA"
rm -rf "$CACHE_PATH"

# Resolve Dependencies
echo "::group::xcodebuild resolve dependencies"
xcodebuild -resolvePackageDependencies
echo "::endgroup"

# Determine Changes
NEWCHECKSUM=$(md5sum "$RESOLVED_PATH")

if [ "$CHECKSUM" != "$NEWCHECKSUM" ]; then
	echo "::set-output name=dependenciesChanged::true"

	if [ "$failWhenOutdated" = true ] || [ "$failWhenOutdated" = 'true' ]; then
		exit 1
	fi
else
	echo "::set-output name=dependenciesChanged::false"
fi