FROM ghcr.io/seankhliao/blogengine AS build
WORKDIR /workspace
COPY . .
RUN ["/bin/blogengine", "-gtm=GTM-TLVN7D6"]

FROM ghcr.io/seankhliao/webserve
COPY redirects.csv /srv/redirects.csv
COPY --from=build /workspace/dst /srv/http
ENTRYPOINT ["/bin/webserve", "-webserve.src=/srv/http", "-webserve.redirects=/srv/redirects.csv"]
