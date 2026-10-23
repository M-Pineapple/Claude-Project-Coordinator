# Linux image for hosts that build and run this stdio MCP server in a container.
# The process starts with no arguments and needs no network or credentials.
# CPC_KNOWLEDGE_BASE is an empty writable directory. Project and analytics
# data are not copied into the image.
FROM swift:6.0-jammy

WORKDIR /app
COPY . .

RUN mkdir -p /data/KnowledgeBase \
    && swift build -c release

ENV CPC_KNOWLEDGE_BASE=/data/KnowledgeBase

CMD ["/app/.build/release/project-coordinator"]
