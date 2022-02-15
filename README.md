# Xcode Project Swift Package Dependencies Update Action

This action will resolve the Swift Package Manager dependencies within your Xcode project. This can be useful in workflows that want to detect outdated dependencies, or wish to automatically create pull requests updating dependencies.

It will respect the boundaries you defined on your dependency, such as only updating to the next minor or on a given branch.

This action requires that you have checked out the source code of the project first, for example using [actions/checkout](https://github.com/actions/checkout).

```yaml
jobs:
  dependencies:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: GetSidetrack/action-xcodeproj-spm-update@main
```

By default, this action will fail if one or more of your dependencies are outdated. This can be suppressed by setting the input parameter of `failWhenOutdated` to false. Regardless of this setting, you may use the output parameter `dependenciesChanged` to run further steps (see example workflow at bottom).

```yaml
jobs:
  dependencies:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: GetSidetrack/action-xcodeproj-spm-update@main
        with:
          failWhenOutdated: false
```

Note that this action will change the `Package.resolved` file which should be checked in to your repository. However, this action will not itself commit or push changes to your repository. We recommend using a package such as [peter-evans/create-pull-request](https://github.com/peter-evans/create-pull-request) to achieve this automation.

This action is looking for an `.xcodeproj` file within the current directory (`.`). For projects where this is not true, you may provide a `directory` input parameter. This is helpful for monorepo projects which may contain multiple projects.

```yaml
jobs:
  dependencies:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: GetSidetrack/action-xcodeproj-spm-update@main
        with:
          directory: 'iOS'
```

If the Package.resolved file has been built with an incompatible version of Xcode, or is in any way corrupted then `xcodebuild` is likely to fail. By setting `forceResolution` to true, it will force Xcode to resolve from nothing and avoid this problem.

## Full Workflow

An example workflow is provided below which will create a pull request which any updated dependencies once a week. Feel free to use, or adapt this in your own workflows.

```yaml
name: Xcode Dependencies

on: 
  schedule:
    - cron: '0 6 * * 1' # Monday at 06:00 UTC

permissions:
  contents: write
  pull-requests: write

jobs:
  dependencies:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v2

      - name: Resolve Dependencies
        id: resolution
        uses: GetSidetrack/action-xcodeproj-spm-update@main
        with:
          forceResolution: true
          failWhenOutdated: false

      - name: Create Pull Request
        if: steps.resolution.outputs.dependenciesChanged == 'true'
        uses: peter-evans/create-pull-request@v3
        with:
          branch: 'dependencies/ios'
          delete-branch: true
          commit-message: 'Update Xcode Dependencies'
          title: 'Updated Xcode Dependencies'
```

## Similar Packages

- [swift-package-dependencies-check](https://github.com/MarcoEidinger/swift-package-dependencies-check) is a GitHub Action which helps update dependencies for Swift Packages (as opposed to Xcode Projects with Swift Packages).