FROM swift:5.5

LABEL description="Docker Container for GitHub Action xcodeproj-spm-update"
LABEL repository="https://github.com/getsidetrack/action-xcodeproj-spm-update"
LABEL maintainer="James Sherlock <james@sidetrack.app>"

ADD entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint

ENTRYPOINT [ "entrypoint" ]