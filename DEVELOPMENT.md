## Testing and building instructions

### Prerequisites

- you might test the action through the Github's UI, however [nektos/act](https://github.com/nektos/act) helps you test the action locally before committing your code.

### Helpful oneliners

```bash
docker rm -f $(docker ps -qa) && \
  docker rmi -f $(docker images -aq --filter "since=nektos/act-environments-ubuntu:18.04") && \
  act -j Deepcode-Build -v

docker rm -f $(docker ps -qa) && docker rmi -f $(docker images -aq) && act -j Deepcode-Build -v

docker rm -f $(docker ps -qa)
docker rmi -f $(docker images -aq --filter "since=nektos/act-environments-ubuntu:18.04")
act -j Deepcode-Build -v

docker build -t deepcodeg/deepcode-code-scanning-analysis .
````
