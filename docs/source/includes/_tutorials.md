# Tutorials

A Tutorial stores instructional content that can be linked to a project and one
or more workflows.

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
display_name | string |
language | string |
kind | string |
steps | array(object) |
configuration | object |
created_at | datetime | read-only
updated_at | datetime | read-only

### Tutorial Links

- project
- workflows
- attached_images

## List Tutorials

```http
GET /api/tutorials HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve, default is 1
  + page_size (optional, integer) ... number of items to include on a page, default is 20
  + sort (optional, string) ... field to sort by
  + project_id (optional, integer) ... return tutorials linked to the identified project
  + language (optional, string) ... filter tutorials by language, defaults to `en`
  + workflow_id (optional, integer) ... return tutorials linked to the identified workflow
  + kind (optional, string) ... filter tutorials by kind
  + include (optional, string) ... comma separated list of linked resources to include in the response

## Retrieve a single Tutorial

```http
GET /api/tutorials/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the tutorial to retrieve
  + include (optional, string) ... comma separated list of linked resources to include in the response

Example response:

```json
{
  "tutorials": [
    {
      "steps": [],
      "href": "/tutorials/123",
      "id": "123",
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z",
      "language": "en",
      "kind": "tutorial",
      "display_name": "Example Tutorial Title",
      "configuration": {},
      "links": {
        "project": "456",
        "workflows": [],
        "attached_images": {
          "href": "/tutorials/123/attached_images",
          "type": "attached_images",
          "ids": []
        }
      }
    }
  ],
  "links": {
    "tutorials.project": {
      "href": "/projects/{tutorials.project}",
      "type": "projects"
    },
    "tutorials.workflows": {
      "href": "/workflows?tutorial_id={tutorials.id}",
      "type": "workflows"
    },
    "tutorials.attached_images": {
      "href": "/tutorials/{tutorials.id}/attached_images",
      "type": "media"
    }
  },
  "meta": {
    "tutorials": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/tutorials?id=123",
      "previous_href": null,
      "next_href": null,
      "last_href": "/tutorials?id=123"
    }
  }
}
```

## Create a Tutorial

```http
POST /api/tutorials HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "tutorials": {
    "display_name": "Example Tutorial Title",
    "language": "en",
    "kind": "tutorial",
    "steps": [],
    "links": {
      "project": "456"
    },
    "configuration": {}
  }
}
```

Example response:

```json
{
  "tutorials": [
    {
      "steps": [],
      "href": "/tutorials/123",
      "id": "123",
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z",
      "language": "en",
      "kind": "tutorial",
      "display_name": "Example Tutorial Title",
      "configuration": {},
      "links": {
        "project": "456",
        "workflows": [],
        "attached_images": {
          "href": "/tutorials/123/attached_images",
          "type": "attached_images",
          "ids": []
        }
      }
    }
  ],
  "links": {
    "tutorials.project": {
      "href": "/projects/{tutorials.project}",
      "type": "projects"
    },
    "tutorials.workflows": {
      "href": "/workflows?tutorial_id={tutorials.id}",
      "type": "workflows"
    },
    "tutorials.attached_images": {
      "href": "/tutorials/{tutorials.id}/attached_images",
      "type": "media"
    }
  },
  "meta": {
    "tutorials": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/tutorials",
      "previous_href": null,
      "next_href": null,
      "last_href": "/tutorials"
    }
  }
}
```

## Edit a single Tutorial

```http
PUT /api/tutorials/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "tutorials": {
    "steps": [
      {
        "media": "",
        "content": ""
      }
    ]
  }
}
```

Example response:

```json
{
  "tutorials": [
    {
      "steps": [
        {
          "media": "",
          "content": ""
        }
      ],
      "href": "/tutorials/123",
      "id": "123",
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:05:00.000Z",
      "language": "en",
      "kind": "tutorial",
      "display_name": "Example Tutorial Title",
      "configuration": {},
      "links": {
        "project": "456",
        "workflows": [],
        "attached_images": {
          "href": "/tutorials/123/attached_images",
          "type": "attached_images",
          "ids": []
        }
      }
    }
  ],
  "links": {
    "tutorials.project": {
      "href": "/projects/{tutorials.project}",
      "type": "projects"
    },
    "tutorials.workflows": {
      "href": "/workflows?tutorial_id={tutorials.id}",
      "type": "workflows"
    },
    "tutorials.attached_images": {
      "href": "/tutorials/{tutorials.id}/attached_images",
      "type": "media"
    }
  },
  "meta": {
    "tutorials": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/tutorials",
      "previous_href": null,
      "next_href": null,
      "last_href": "/tutorials"
    }
  }
}
```

## Destroy a single Tutorial

```http
DELETE /api/tutorials/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Response will be an HTTP 204.

Example request:

```http
DELETE /api/tutorials/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
