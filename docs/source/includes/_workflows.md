# Workflows
```json
{
    "links": {
    "workflows.subjects": {
        "href": "/subjects{?workflow_id=workflows.id}",
        "type": "subjects"
    },
    "workflows.project": {
        "href": "/projects/{workflows.project}",
        "type": "projects"
    },
    "workflows.subject_sets": {
        "href": "/subject_sets?workflow_id={workflows.id}",
        "type": "subject_sets"
    }
    },
    "meta": {
    "workflows": {
        "page": 1,
        "page_size": 2,
        "count": 28,
        "include": [],
        "page_count": 14,
        "previous_page": 14,
        "next_page": 2,
        "first_href": "/workflows?page_size=2",
        "previous_href": "/workflows?page=14page_size=2",
        "next_href": "/workflows?page=2&page_size=2",
        "last_href": "/workflows?page=14&page_size=2"
    }
},
"workflows": [{
    "id": "22",
    "display_name": "Find moons",
    "created_at": "2014-02-13T10:11:34Z",
    "updated_at": "2014-02-13T10:11:34Z",
    "classifications_count": 1000,
    "pairwise": false,
    "grouped" : false,
    "prioritized": false,
    "primary_language": "es_MX",
    "workflow_version": "22.1",
    "content_language": "en_US",
    "first_task": "interest",
    "tasks": {
            "interest": {
                "type": "drawing",
                "question": "Color some points",
                "tools": [
                    {"value": "red", "label": "Red", "type": "point", "color": "red"},
                    {"value": "green", "label": "Green", "type": "point", "color": "lime"},
                    {"value": "blue", "label": "Blue", "type": "point", "color": "blue"}
                ],
                "next": "shape"
            },
            "shape": {
                "type": "multiple",
                "question": "What shape is this galaxy?",
                "answers": [
                    {"value": "smooth", "label": "Smooth"},
                    {"value": "features", "label": "Features"},
                    {"value": "other", "label": "Star or artifact"}
                ],
                "required": true,
                "next": "roundness"
            },
            "roundness": {
                "type": "single",
                "question": "How round is it?",
                "answers": [
                    {"value": "very", "label": "Very...", "next": "shape"},
                    {"value": "sorta", "label": "In between"},
                    {"value": "not", "label": "Cigar shaped"}
                ],
                "next": null
            }
        },
    "links": {
        "project": "1",
        "subject_sets": ["10", "11", "12"]
    }
},{
    "id": "23",
    "display_name": "Find moons",
    "created_at": "2014-02-13T10:11:34Z",
    "updated_at": "2014-02-13T10:11:34Z",
    "classifications_count": 1000,
    "pairwise": false,
    "grouped" : false,
    "prioritized": false,
    "primary_language": "es_MX",
    "workflow_version": "22.1",
    "content_language": "en_US",
    "first_task": "interest",
    "tasks": {
            "interest": {
                "type": "drawing",
                "question": "Color some points",
                "tools": [
                    {"value": "red", "label": "Red", "type": "point", "color": "red"},
                    {"value": "green", "label": "Green", "type": "point", "color": "lime"},
                    {"value": "blue", "label": "Blue", "type": "point", "color": "blue"}
                ],
                "next": "shape"
            },
            "shape": {
                "type": "multiple",
                "question": "What shape is this galaxy?",
                "answers": [
                    {"value": "smooth", "label": "Smooth"},
                    {"value": "features", "label": "Features"},
                    {"value": "other", "label": "Star or artifact"}
                ],
                "required": true,
                "next": "roundness"
            },
            "roundness": {
                "type": "single",
                "question": "How round is it?",
                "answers": [
                    {"value": "very", "label": "Very...", "next": "shape"},
                    {"value": "sorta", "label": "In between"},
                    {"value": "not", "label": "Cigar shaped"}
                ],
                "next": null
            }
        },
    "links": {
        "project": "1",
        "subject_sets": ["10", "11", "12"]
    }
}]
}
```

Workflows represent the series of questions/tasks a user will be asked
to complete for a subject. Subjects are selected from SubjectSets. A
Workflow may have many SubjectSets linked to, but a SubjectSet may
only be linked to a single Workflow.

A workflow has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
display_name | string |
finished_at | datetime |
tasks | jsonb |
classifications_count | integer |
pairwise | boolean |
grouped | boolean |
prioritized | boolean |
retirement | jsonb |
retired_set_member_subjects_count | integer  |
active | boolean |
aggregation | jsonb |
configuration | jsonb |
completeness | decimal |
primary_language | string |
workflow_version | string |
content_language | string |
created_at | datetime | read-only
updated_at | datetime | read-only


*id*, *created_at*, *updated_at*, *workflow_version*, *content_language*,
and *classifications_count* are assigned by the API

*finished_at* is set by the API to a date/time when all subjects for this workflow have been retired.

Three parameters: _grouped_, _prioritized_, and _pairwise_ configure
how the api chooses subjects for classification. They are all false by default,
which will give a random selection of subjects from all subject\_sets that
are part of a workflow. _grouped_ enables selecting subjects from a specific
subject set. _prioritized_ ensures that users will see subjects in a
predetermined order. _pairwise_ will select two subjects at a tim for classification.

A workflow's `tasks` is a hash of keys to task definitions.

A workflow's `first_task` is a string matching the key of its first task. (The order of keys in JSON hashes is not guaranteed).

Each task has a `type` string of "single" or "multiple" choice, or "drawing". (More task types to come, e.g. Serengeti-style filter and Sunspotter's comparison.)

"multiple" and "drawing" tasks have a `next` string, linking to the next task in the workflow. If this string is empty, the workflow ends. In "single" tasks, each answer has a `next` string, allowing branching based on the user's decisions.

"single" and "multiple" tasks have a `question` string, which the user must answer. Answers to the question are in an `answers` array. Each answer has a `label` string displayed to the user.

"single" and "multiple" tasks may define a boolean `required`, which when true will force the user to provide an answer before moving on to the next task.

"drawing" tasks have an `instruction` string telling the user how to complete the task.

"drawing" tasks have a `tools` array.

Each tool has a `label` shown to the user.

Each tool has a string `type`. Options include:

+ point
+ ellipse
+ circle
+ line
+ rectangle
+ polygon

Each tool has a string `color`, which is applied to the marks made by the tool. Any format valid as CSS can be used.

## List All Workflows
```http
GET /api/workflows HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by id by default
  + project_id (optional, integer) ... filter workflows by project id
  + include (optional, string) ... comma separated list of linked resources to load

Response has a *meta* attribute hash containing
paging information.

Workflows are returned as an array under the _workflows_ key.

## Retrieve a single Workflow
```http
GET /api/workflows/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
    + id (required, integer) ... id of the workflow
    + include (optional, string) ... comma separated list of linked resources to include in the response

## Create a Workflow
```http
POST /api/workflows HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "workflows": {
        "display_name": "Spot Monsters!",
        "tasks":  {
            "interest": {
                "type": "drawing",
                "question": "Color some points",
                "tools": [
                    {"value": "red", "label": "Red", "type": "point", "color": "red"},
                    {"value": "green", "label": "Green", "type": "point", "color": "lime"},
                    {"value": "blue", "label": "Blue", "type": "point", "color": "blue"}
                ],
                "next": "shape"
            },
            "shape": {
                "type": "multiple",
                "question": "What shape is this galaxy?",
                "answers": [
                    {"value": "smooth", "label": "Smooth"},
                    {"value": "features", "label": "Features"},
                    {"value": "other", "label": "Star or artifact"}
                ],
                "required": true,
                "next": "roundness"
            },
            "roundness": {
                "type": "single",
                "question": "How round is it?",
                "answers": [
                    {"value": "very", "label": "Very...", "next": "shape"},
                    {"value": "sorta", "label": "In between"},
                    {"value": "not", "label": "Cigar shaped"}
                ],
                "next": null
            }
        },
        "retirement": {
            "criteria": "classification_count",
            "options": {
                "count": 15
            }
        },
        "primary_language": "en-ca",
        "links": {
            "project": "42",
            "subject_sets": ["1", "2"]
        }
    }
}
```

Requires a set of *tasks*, a *primary_language*, a *display_name*, and a
link to a *project*. Can optionally set cellect parameters *grouped*,
*prioritized*, and *pairwise* (all false by default) and links to
*subject_sets*.

A SubjectSet that already belongs to another workflow will be
duplicated when it is linked.

A Workflow may also include a _retirement_ object with a _criteria_
key and an _options_ key. _criteria_ describes the strategy Panoptes
will use to decide when to retire subjects while _options_ configures
the strategy. There are 2 valid criteria:
 1. `classification_count` will retire subjects after a target number
 of classifications are reached. You must supply an `options` hash
 with an integer `count` to specify the minimum number of classifications.
   + `{"criteria": "classification_count", "options": {"count": 15} }`
 2. `never_retire` will never retire subjects and requires an empty
 `options` hash.
   + `{"criteria": "never_retire "options": {} }`

If retirement is left blank Panoptes defaults to the `classification_count`
strategy with 15 classifications per subject.


## Edit a single workflow
```http
PUT /api/workflows/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "workflows": {
        "tasks": { "format": "all new!"},
        "links": {
            "subject_sets": ["8"]
        }
    }
}
```

A user may edit a workflow if they have edit permissions for the parent
project. Editing tasks content requires a full replacement for the
field. Only the subject set link may be edited. Removing a subject_set
link doesn't destroy the subject_set.

This is not the recommended way to edit links. Use the subject_set
link mode documented below.


## Destroy a single workflow
```http
DELETE /api/workflows/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

A user may destroy a workflow if they have destroy permissions for the
parent project.

## Link Subject Set to Workflow
```http
POST /api/workflows/123/links/subject_sets HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{ "subject_sets": ["9"] }
```

**The recommended way to update links.**

Adds the posted subject sets to a workflow's links. Creates a copy of
the subject set if it belongs do a different project.

+ Parameters
  + id (required, integer) ... id of workflow to update



## Destroy Workflow's Subject Set Links
```http
DELETE /api/workflows/123/links/subject_sets/1,2,3 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

**The recommended way to remove links.**

Removes workflow's links to the given subject_sets. It does not
destroy the subject set models.

+ Parameters
  + id (required, integer) ... id of workflow to update
  + subject_set_ids (required, string) ... comma separated list of ids to destroy

## Workflow Versions
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
            "first_href": "/workflows/101/versions?page_size=2",
            "previous_href": "/workflows/101/versions?page=14page_size=2",
            "next_href": "/workflows/101/versions/?page=2&page_size=2",
            "last_href": "/workflows/101/versions?page=14&page_size=2"
        }
    },
    "versions":  [{
        "id": "42",
        "changeset": {
            "grouped": [
                true,
                false
            ]
        },
        "whodunnit": "stuartlynn",
        "created_at": "2014-03-20T06:23:12Z",
        "links": {
            "item": {
                "id": "101",
                "href": "/workflows/101",
                "type": "workflows"
            }
        }
    },{
        "id": "43",
        "changeset": {
            "prioritized": [
                false,
                true
            ]
        },
        "whodunnit": "stuartlynn",
        "created_at": "2014-03-20T06:23:12Z",
        "links": {
            "item": {
                "id": "101",
                "href": "/workflows/101",
                "type": "workflows"
            }
        }
    }]
}
```

A Workflow  Version resource represents a set of changes made to
a Workflow  resource.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
changeset | hash | read-only
whodunnit | string | read-only
created_at | datetime | read-only


**It is NOT editable.**

## List All Workflow Versions
```http
GET /api/workflows/123/versions HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + workflow_id (required, integer) ... integer id of the workflow resource
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20

Response will have a meta attribute hash containing paging
information.

Workflow Versions are returned as an array under *versions*.

## Retrieve a Single Version
```http
GET /api/workflows/123/versions/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + workflow_id (required, integer) ... integer id of the workflow resource
  + id (required, integer) ... integer id of the version to retrieve

