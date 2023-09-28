# riskheiv-tests

```sh
docker build -t riskheiv-tests .
docker run --rm -v $(pwd):/output riskheiv-tests bash -c "cp -r /tmp /output/"
```
