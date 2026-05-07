FROM squidfunk/mkdocs-material:latest AS docs-builder

WORKDIR /opt

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY mkdocs.yml .
COPY docs/ docs/
COPY includes/ includes/
COPY overrides/ overrides/
COPY ALCFBeginnersGuide/ ALCFBeginnersGuide/
COPY AuroraBugTracking/ AuroraBugTracking/
COPY GettingStarted/ GettingStarted/

RUN mkdocs build

FROM nginx:alpine AS docs-server

COPY --from=docs-builder /opt/site /usr/share/nginx/html

EXPOSE 80
