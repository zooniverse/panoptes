# Field Guides

```json
{
  "field_guides": [{
    "id": "123",
    "language": "en",
    "items": [
      {
        "title": "Example Guide Entry",
        "content": "Example field guide content."
      }
    ],
    "href": "/field_guides/123",
    "created_at": "2026-01-01T12:00:00.000Z",
    "updated_at": "2026-01-01T12:05:00.000Z",
    "links": {
      "project": "456",
      "attached_images": {
        "href": "/field_guides/123/attached_images",
        "type": "attached_images",
        "ids": []
      }
    }
  }],
  "links": {
    "field_guides.project": {
      "href": "/projects/{field_guides.project}",
      "type": "projects"
    },
    "field_guides.attached_images": {
      "href": "/field_guides/{field_guides.id}/attached_images",
      "type": "media"
    }
  }
}
```

A Field Guide stores reference material for a project.

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
language | string |
items | array(object) |
href | string | read-only
created_at | datetime | read-only
updated_at | datetime | read-only

### Field Guide Links

- project
- attached_images

## List Field Guides

```http
GET /api/field_guides HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Example query:

```http
GET /api/field_guides?project_id=456 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve, default is 1
  + page_size (optional, integer) ... number of items to include on a page, default is 20
  + sort (optional, string) ... field to sort by
  + project_id (optional, integer) ... return field guides linked to the identified project
  + language (optional, string) ... filter field guides by language, defaults to `en`
  + include (optional, string) ... comma separated list of linked resources to include in the response

## Retrieve a single Field Guide

```http
GET /api/field_guides/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the field guide to retrieve
  + include (optional, string) ... comma separated list of linked resources to include in the response

## Create a Field Guide

```http
POST /api/field_guides HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "field_guides": {
    "language": "en",
    "items": [],
    "links": {
      "project": "456"
    }
  }
}
```

The create schema accepts:

- `language`
- `items`
- `links.project`

Each item may include:

- `icon`
- `title`
- `content`

Example response:

```json
{
  "field_guides": [
    {
      "id": "124",
      "items": [],
      "language": "en",
      "href": "/field_guides/124",
      "created_at": "2026-01-01T12:10:00.000Z",
      "updated_at": "2026-01-01T12:10:00.000Z",
      "links": {
        "project": "456",
        "attached_images": {
          "href": "/field_guides/124/attached_images",
          "type": "attached_images",
          "ids": []
        }
      }
    }
  ],
  "links": {
    "field_guides.project": {
      "href": "/projects/{field_guides.project}",
      "type": "projects"
    },
    "field_guides.attached_images": {
      "href": "/field_guides/{field_guides.id}/attached_images",
      "type": "media"
    }
  },
  "meta": {
    "field_guides": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/field_guides",
      "previous_href": null,
      "next_href": null,
      "last_href": "/field_guides"
    }
  }
}
```

## Edit a single Field Guide

```http
PUT /api/field_guides/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "field_guides": {
    "items": [
      {
        "title": "Updated Guide Page",
        "content": "Updated reference material.",
        "icon": "654321"
      }
    ]
  }
}
```

## Destroy a single Field Guide

```http
DELETE /api/field_guides/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Response will be an HTTP 204.

Example request:

```http
DELETE /api/field_guides/124 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
