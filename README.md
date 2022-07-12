# losantiville

Turbo Fast Server Side Rendered OpenAPI Specification Documentation Site Generator for Swagger 2.0

## example generation

```
polly build && cat api-with-examples.yaml | docker run -i losantiville:latest bundle exec losantiville
```
