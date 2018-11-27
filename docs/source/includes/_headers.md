# Headers

Panoptes API sometime requires specific headers to be sent as part of requests.

All requests should set `Accept: application/vnd.api+json; version=1`. You will receive a `404 Not Found` without it.

All PUT and POST requests should set `Content-Type: application/vnd.api+json; version=1` or `Content-Type: application/json`. You will receive a `415 Unsupported Media Type` without one of those two headers.

All PUT and DELETE requests should set the `If-Match` header to the value of the `ETag` header of the request where the resource was originally retrieved. You will receive a `428 Precondition Required` without the header and a `412 Precondition Failed` if the etags do not match.

