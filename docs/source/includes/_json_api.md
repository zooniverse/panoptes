# JSON-API conventions

## Resource(s) themselves

```json
{
  "users": [{
    "id": 123,
    ...
  }],
  ...
}
```

If you request a resource, you will find the results under a top-level key with
the plural name of the resource. So for instance, if you a single specific user,
you will find the user record under the `users` key.

<aside class="notice">
Resources will always be returned an array. If you requested a single specific
resource (usually by passing in its <code>id</code>), you can rely on this being an array
with at most one element.
</aside>

## Links

```json
{
  "projects": [{
    ...,
    "links": {
      "workflows": [123],
      "avatar": {"href": "/projects/123/avatar", "type": "avatars"},
      ...
    }
  }],
  "links": {
    "projects.workflows": {
      "href": "/workflows?project_id={projects.id}",
      "type": "workflows"
    },
    "projects.avatar": {
      "href": "/projects/{projects.id}/avatar",
      "type": "media"
    },
    ...
  }
}
```

Any resource returned will specify a list of linked resources under its `links`
attribute. Definition on where to request those linked resources can be found
under the top-level `links` key (as opposed to the per-resource `links`).

## Pagination

```json
{
  "page": 1,
  "page_size": 2,
  "count": 28,
  "include": [],
  "page_count": 14,
  "previous_page": 14,
  "next_page": 2,
  "first_href": "/users?page_size=2",
  "previous_href": "/users?page=14page_size=2",
  "next_href": "/users?page=2&page_size=2",
  "last_href": "/users?page=14&page_size=2"
}
```

When requesting a list of resources, rather than a single resource, the
response will include a top-level `meta` key. For performance reasons, results
are returned in pages. You can use the data under the `meta` key to
automatically navigate these paginated results.

## Including Linked Resources

```http
# Eg. request using the ?include parameter
GET /api/projects?include=avatar HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

When a fetch request includes an `?include` query parameter (a comma-separated list of related resources of the requested resource) the response will contain a *linked* field with those linked resources. This avoids any extra requests since everything will come back in one response.

```json
{
  "projects": [{
    ...,
    "links": {
      "workflows": [123],
      "avatar": {"href": "/projects/123/avatar", "type": "avatars"},
      ...
    }
  }],
  "linked": {
    "avatars": [{
        ...,
        "links": {
          "linked": {
            "href": "/projects/123",
            "id": "123",
            "type": "projects"
          }
        }
      }]
  },
  ...
}

```
