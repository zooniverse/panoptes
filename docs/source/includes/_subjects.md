# Subjects
```json
    {
        "links": {
            "subjects.project": {
                "href": "/projects/subjects.project",
                "type": "projects"
            },
            "subjects.subject_sets": {
                "href": "/subject_sets/subjects.subject_sets",
                "type": "subject_sets"
            }
        },
        "meta": {
            "subjects": {
                "page": 1,
                "page_size": 2,
                "count": 28,
                "include": [],
                "page_count": 14,
                "previous_page": 14,
                "next_page": 2,
                "first_href": "/subjects?page_size=2",
                "previous_href": "/subjects?page=14page_size=2",
                "next_href": "/subjects?page=2&page_size=2",
                "last_href": "/subjects?page=14&page_size=2"
            }
        },
        "subjects": [{
            "id": "1",
            "zooniverse_id": "AGFS0001231",
            "created_at": "2014-03-24T10:42:21Z",
            "updated_at": "2014-03-24T10:42:21Z",
            "locations": [
                {"image/jpeg": "http://s3.amazonaws.com/subjects/1.png"}
            ],
            "metadata": {
                "lens_type": "50mm"
            },
            "links": {
                "project": "1"
                "subject_sets": ["1"]
            }
        },{
            "id": "2",
            "zooniverse_id": "AGFS0001232",
            "created_at": "2014-03-24T10:44:21Z",
            "updated_at": "2014-03-24T10:44:21Z",
            "locations": [
                {"image/jpeg": "http://s3.amazonaws.com/subjects/2.png"}
            ],
            "metadata": {
                "lens_type": "50mm"
            },
            "links": {
                "project": "1"
                "subject_sets": ["1"]
            }
        }]
    }
```

A single Subject object. A Subject is a resource that describe a
piece of media to be classified including metadata about the object.

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
zooniverse_id | integer | read-only
locations | array(hash) |
metadata | hash |
created_at | datetime | read-only
updated_at | datetime | read-only

*id*, *zooniverse_id*, *created_at*, and *updated_at* are assigned by
the API.

## List Subjects
```http
GET /api/subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + workflow_id (optional, integer) ... filter to subjects belonging to a specific workflow
  + subject_set_id (optional, integer) ... return subjects belonging to the identified subject_set

Response will have a *meta* attribute hash containing paging information.

Subjects are returned as an array under the _subjects_ key.

## Retrieve a single Subject
```http
GET /api/subjects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the subject resource

## Create a Subject
```http
POST /api/subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subjects": {
        "locations": [
            "image/png",
            [
                "video/webm",
                "video/mp4"
            ]
        ],
        "metadata": {
            "lens_type": "50mm"
        },
        "links": {
            "project": "1"
        }
    }
}
```

A *locations* attribute and a project link are required.

To have the Zooniverse host your media resources the *locations* array
should have the mime-types of the subject's associated media,
e.g `"locations":["image/png", "image/jpeg", "image/png"]`,
note the locations mime types are stored in order.

The create response will contain signed panoptesuploads blob urls the client may make a PUT
request containing the media to. The signed urls will be valid for 20 minutes.
Please take the order of the returned panoptesuploads urls into account when PUT'ing
local media resources to the remote location.

To use your own hosted media resources the *locations* array
should be comprised of objects that represent the mime-type and the hosted URL
of the subject's associated media,
e.g. `"locations":[
{"image/png": "https://your.s3_account.com/subjects/1.png"},
{"image/jpeg": "https://your.s3_account.com/subjects/1.jpg"}
]`.

The *metadata* attribute is optional.

## Edit a single Subject
```http
PUT /api/subjects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subjects": {
        "locations": [
            "image/png"
        ]
    }
}
```

Users are permitted to edit subjects belonging to projects a user
has edit permissions for. A user may not change the project of a
subject.

The *locations* array should have the mime-types of the subject's
associated media. The response will contain signed panoptesuploads blob urls the client
may make a PUT request containing the media to. The signed urls will
be valid for 20 minutes.

A request changing the *metadata* hash must contain a full
representation of the attribute.

## Destroy a single subject
```http
DELETE /api/subjects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Users are permitted to destroy a subjects they own or
subjects belongs to a project a user has destroy permissions for.

## Subject Versions
```json
{
    "meta": {
        "versions": {
            "page": 1,
            "page_size": 2,
            "count": 28,
            "include": [],
            "page_count": 14,
            "previous_page": 14,
            "next_page": 2,
            "first_href": "/subjects/101/versions?page_size=2",
            "previous_href": "/subjects/101/versions?page=14page_size=2",
            "next_href": "/subjects/101/versions/?page=2&page_size=2",
            "last_href": "/subjects/101/versions?page=14&page_size=2"
        }
    },
    "versions":  [{
        "id": "42",
        "changeset": {
            "metadata": [{
                "ra": "120.2",
                "dec": "-12.4"
            },{
                "ra": "121.1",
                "dec": "-11.1"
            }]
        },
        "whodunnit": "stuartlynn",
        "created_at": "2014-03-20T06:23:12Z",
        "links": {
            "item": {
                "id": "101",
                "href": "/subject/101",
                "type": "subjects"
            }
        }
    },{
        "id": "43",
        "changeset": {
            "metadata": [{
                "ra": "20.2",
                "dec": "12.4"
            },{
                "ra": "21.1",
                "dec": "11.1"
            }]
        },
        "whodunnit": "stuartlynn",
        "created_at": "2014-03-20T06:23:12Z",
        "links": {
            "item": {
                "id": "101",
                "href": "/subject/101",
                "type": "subjects"
            }
        }
    }]
}
```

A Subject Version resource represents a set of changes made to
a Subject resource.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
changeset | jsonb | read-only
whodunnit | string | read-only
created_at | datetime | read-only


**It is NOT editable.**

## List all Subject Versions
```http
GET /api/subjects/123/versions HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
    + subject_id (required, integer) ... id of the subject to retreive versions for
    + page (optional, integer) ... the index of the page to retrieve default is 1
    + page_size (optional, integer) ... number of items to include on a page default is 20

Response will have a meta attribute hash containing paging
information.

Subject Versions are returned as an array under *versions*.


## Retrieve a Single Subject Version
```http
GET /api/subjects/123/versions/2 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + subject_id (required, integer) ... id of the subject to retreive versions for
  + id (required, integer) ... integer id of the version to load


## Retrieve subjects to classify
```http

GET /api/subjects/queued HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

While the normal `GET /api/subjects` request returns a list of subjects, the
selection endpoints below return subjects chosen for classification.

+ Parameters
  + workflow_id (required, integer)
  + subject_set_id (optional, integer) ... required when the workflow is grouped
  + page_size (optional, integer) ... if omitted, the selector fills this in from workflow configuration or a default

Example request:

```http
GET /api/subjects/queued?workflow_id=321 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Example response:

```json
{
  "subjects": [
    {
      "id": "1001",
      "metadata": {
        "Filename": "example-1.jpg"
      },
      "locations": [
        {
          "image/jpeg": "https://panoptes-uploads.example.org/subject_location/example-1.jpeg"
        }
      ],
      "zooniverse_id": null,
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z",
      "href": "/subjects/1001",
      "selected_at": "2026-01-02T09:30:00.000Z",
      "retired": true,
      "already_seen": true,
      "finished_workflow": true,
      "user_has_finished_workflow": true,
      "favorite": false,
      "selection_state": "failover_fallback"
    },
    {
      "id": "1002",
      "metadata": {
        "Filename": "example-2.jpg"
      },
      "locations": [
        {
          "image/jpeg": "https://panoptes-uploads.example.org/subject_location/example-2.jpeg"
        }
      ],
      "zooniverse_id": null,
      "created_at": "2026-01-01T12:01:00.000Z",
      "updated_at": "2026-01-01T12:01:00.000Z",
      "href": "/subjects/1002",
      "selected_at": "2026-01-02T09:30:00.000Z",
      "retired": true,
      "already_seen": true,
      "finished_workflow": true,
      "user_has_finished_workflow": true,
      "favorite": true,
      "selection_state": "failover_fallback"
    }
  ],
  "meta": {
    "subjects": {
      "page": 1,
      "page_size": 20,
      "count": 0,
      "include": [],
      "page_count": 0,
      "previous_page": 0,
      "next_page": 2,
      "first_href": "/subjects",
      "previous_href": "/subjects?page=0",
      "next_href": "/subjects?page=2",
      "last_href": "/subjects?page=0"
    }
  }
}
```

If the workflow has no linked subject sets, the selector raises `no subject set
is associated with this workflow`.

If the workflow has no selectable subjects, the selector raises `No data
available for selection`.

For grouped workflows, `subject_set_id` is required and the selector raises
`subject_set_id parameter missing for grouped workflow` if it is omitted.

## Retrieve grouped subjects to classify

```http
GET /api/subjects/grouped HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Returns virtual subject groups serialized under the top-level `subjects` key.

+ Parameters
  + workflow_id (required, integer)
  + num_rows (required, integer) ... must be between 1 and 9 inclusive
  + num_columns (required, integer) ... must be between 1 and 9 inclusive
  + subject_set_id (optional, integer)

Example request:

```http
GET /api/subjects/grouped?workflow_id=321&num_rows=5&num_columns=5 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Example response:

```json
{
  "subjects": [
    {
      "id": "-1",
      "metadata": {
        "#subject_group_id": true,
        "#group_subject_ids": "1001-1002-1003-1004-1005"
      },
      "locations": [
        {
          "image/png": "https://panoptes-uploads.example.org/subject_location/example-1.png"
        },
        {
          "image/png": "https://panoptes-uploads.example.org/subject_location/example-2.png"
        },
        {
          "image/png": "https://panoptes-uploads.example.org/subject_location/example-3.png"
        }
      ],
      "zooniverse_id": null,
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z",
      "href": null,
      "selected_at": "2026-01-01T12:00:05.000Z",
      "retired": false,
      "already_seen": false,
      "finished_workflow": false,
      "user_has_finished_workflow": false,
      "favorite": false,
      "selection_state": "internal_fallback"
    },
    {
      "id": "-2",
      "metadata": {
        "#subject_group_id": true,
        "#group_subject_ids": "1006-1007-1008-1009-1010"
      },
      "locations": [
        {
          "image/png": "https://panoptes-uploads.example.org/subject_location/example-4.png"
        },
        {
          "image/png": "https://panoptes-uploads.example.org/subject_location/example-5.png"
        }
      ],
      "zooniverse_id": null,
      "created_at": "2026-01-01T12:00:01.000Z",
      "updated_at": "2026-01-01T12:00:01.000Z",
      "href": null,
      "selected_at": "2026-01-01T12:00:05.000Z",
      "retired": false,
      "already_seen": false,
      "finished_workflow": false,
      "user_has_finished_workflow": false,
      "favorite": false,
      "selection_state": "internal_fallback"
    }
  ],
  "links": {},
  "meta": {
    "subjects": {
      "page": 1,
      "page_size": 75,
      "count": 2,
      "include": [],
      "page_count": 0,
      "previous_page": 0,
      "next_page": 2,
      "first_href": null,
      "previous_href": null,
      "next_href": null,
      "last_href": null
    }
  }
}
```

If `num_rows` or `num_columns` are missing or invalid, the API returns HTTP 422.

- missing `num_rows` and `num_columns`
- non-integer `num_columns`
- array `num_rows` parameter rejected as unpermitted

## Retrieve specific subjects to classify

```http
GET /api/subjects/selection HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Returns specific subjects by id for a workflow.

+ Parameters
  + workflow_id (required, integer)
  + ids (required, string) ... comma-separated list of digits, maximum 10 ids

If `ids` is missing, the API returns HTTP 422 with `Ids is required`.


