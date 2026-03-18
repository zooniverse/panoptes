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
    "workflow_versions": [
        {
            "id": "7106287",
            "href": "/workflow_versions/7106287",
            "created_at": "2026-03-18T20:34:31.593Z",
            "updated_at": "2026-03-18T20:34:31.593Z",
            "major_number": 1,
            "minor_number": 1,
            "grouped": false,
            "pairwise": false,
            "prioritized": false,
            "tasks": {},
            "first_task": "",
            "strings": {},
            "links": {
                "workflow": "31444"
            }
        },
        {
            "id": "7106288",
            "href": "/workflow_versions/7106288",
            "created_at": "2026-03-18T20:35:05.137Z",
            "updated_at": "2026-03-18T20:35:05.137Z",
            "major_number": 2,
            "minor_number": 2,
            "grouped": false,
            "pairwise": false,
            "prioritized": false,
            "tasks": {
                "T0": {
                    "help": "T0.help",
                    "type": "single",
                    "answers": [],
                    "question": "T0.question",
                    "required": false
                }
            },
            "first_task": "T0",
            "strings": {
                "T0.help": "",
                "T0.question": "Yes or No"
            },
            "links": {
                "workflow": "31444"
            }
        },
        {
            "id": "7106289",
            "href": "/workflow_versions/7106289",
            "created_at": "2026-03-18T20:35:05.299Z",
            "updated_at": "2026-03-18T20:35:05.299Z",
            "major_number": 3,
            "minor_number": 3,
            "grouped": false,
            "pairwise": false,
            "prioritized": false,
            "tasks": {
                "T0": {
                    "help": "T0.help",
                    "type": "single",
                    "answers": [
                        {
                            "label": "T0.answers.0.label"
                        }
                    ],
                    "question": "T0.question",
                    "required": false
                }
            },
            "first_task": "T0",
            "strings": {
                "T0.help": "",
                "T0.question": "Yes or No",
                "T0.answers.0.label": "Enter an answer"
            },
            "links": {
                "workflow": "31444"
            }
        },
        {
            "id": "7106290",
            "href": "/workflow_versions/7106290",
            "created_at": "2026-03-18T20:35:11.118Z",
            "updated_at": "2026-03-18T20:35:11.118Z",
            "major_number": 3,
            "minor_number": 4,
            "grouped": false,
            "pairwise": false,
            "prioritized": false,
            "tasks": {
                "T0": {
                    "help": "T0.help",
                    "type": "single",
                    "answers": [
                        {
                            "label": "T0.answers.0.label"
                        }
                    ],
                    "question": "T0.question",
                    "required": false
                }
            },
            "first_task": "T0",
            "strings": {
                "T0.help": "",
                "T0.question": "Yes or No",
                "T0.answers.0.label": "Yes"
            },
            "links": {
                "workflow": "31444"
            }
        },
        {
            "id": "7106291",
            "href": "/workflow_versions/7106291",
            "created_at": "2026-03-18T20:35:11.277Z",
            "updated_at": "2026-03-18T20:35:11.277Z",
            "major_number": 4,
            "minor_number": 5,
            "grouped": false,
            "pairwise": false,
            "prioritized": false,
            "tasks": {
                "T0": {
                    "help": "T0.help",
                    "type": "single",
                    "answers": [
                        {
                            "label": "T0.answers.0.label"
                        },
                        {
                            "label": "T0.answers.1.label"
                        }
                    ],
                    "question": "T0.question",
                    "required": false
                }
            },
            "first_task": "T0",
            "strings": {
                "T0.help": "",
                "T0.question": "Yes or No",
                "T0.answers.0.label": "Yes",
                "T0.answers.1.label": "Enter an answer"
            },
            "links": {
                "workflow": "31444"
            }
        },
        {
            "id": "7106292",
            "href": "/workflow_versions/7106292",
            "created_at": "2026-03-18T20:35:16.785Z",
            "updated_at": "2026-03-18T20:35:16.785Z",
            "major_number": 4,
            "minor_number": 6,
            "grouped": false,
            "pairwise": false,
            "prioritized": false,
            "tasks": {
                "T0": {
                    "help": "T0.help",
                    "type": "single",
                    "answers": [
                        {
                            "label": "T0.answers.0.label"
                        },
                        {
                            "label": "T0.answers.1.label"
                        }
                    ],
                    "question": "T0.question",
                    "required": false
                }
            },
            "first_task": "T0",
            "strings": {
                "T0.help": "",
                "T0.question": "Yes or No",
                "T0.answers.0.label": "Yes",
                "T0.answers.1.label": "No"
            },
            "links": {
                "workflow": "31444"
            }
        }
    ],
    "links": {
        "workflow_versions.workflow": {
            "href": "/workflows/{workflow_versions.workflow}",
            "type": "workflows"
        }
    },
    "meta": {
        "workflow_versions": {
            "page": 1,
            "page_size": 20,
            "count": 6,
            "include": [],
            "page_count": 1,
            "previous_page": null,
            "next_page": null,
            "first_href": "/workflow_versions?workflow_id=31444",
            "previous_href": null,
            "next_href": null,
            "last_href": "/workflow_versions?workflow_id=31444"
        }
    }
}
```

A Workflow  Version resource represents a set of changes made to
a Workflow  resource.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
created_at | datetime | read-only
updated_at | datetime | read-only
major_number | integer | read-only
minor_number | integer | read-only
grouped | boolean | read-only
pairwise | boolean | read-only
prioritized | boolean | read-only
tasks | jsonb | read-only
first_task | string | read-only
strings | jsonb | read-only


**It is NOT editable.**

## List All Workflow Versions
```http
GET /api/workflow_versions?workflow_id=123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + workflow_id (required, integer) ... integer id of the workflow resource
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20

Response will have a meta attribute hash containing paging
information.

Workflow Versions are returned as an array under *workflow_versions*.

## Retrieve a Single Version
```http
GET /api/workflow_versions/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the version to retrieve

## Retire Subjects by Workflow
```http
POST /api/workflows/123/retired_subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subject_ids": [9],
    "retirement_reason": "other"
}
```

A user may fast track retirement of a subject/multiple subjects on a workflow if they have proper permissions on the workflow's project.

One can retire a subject (using `subject_id` key request body) or multiple subjects (using `subject_ids` in request body).

Response will be an HTTP 204

+ Parameters
  + workflow_id (required, integer) ... integer id of the workflow resource
  + subject_id (optional, integer) ... integer id of the subject one wishes to retire
  + subject_ids (optional, array(integer)) ... array of integer ids of the subjects one wishes to retire
  + retirement_reason (optional, string) ... reason for retirement (defaults to 'other'). (See [<b>SubjectWorkflowStatuses Retirement Reason Types</b>](#retirement-reason-types))


## Un-retire Subjects by Workflow
```http
POST /api/workflows/123/unretire_subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subject_ids": [9]
}
```

A user may unretire a subject/multiple subjects on a workflow if they have proper permissions on the workflow's project.

```http
# Eg of unretiring all subjects within multiple subject sets
POST /api/workflows/123/unretire_subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subject_set_ids": [9, 10]
}
```


One can unretire:

+ a subject (using `subject_id` key request body)
+ multiple subjects (using `subject_ids` in request body)
+ all subjects in a subject_set (using `subject_set_id` in request body).
+ all subjects in multiple subject_sets (using `subject_set_ids` in request body)

Response will be an HTTP 204

+ Parameters
  + workflow_id (required, integer) ... integer id of the workflow resource
  + subject_id (optional, integer) ... integer id of the subject one wishes to unretire
  + subject_ids (optional, array(integer)) ... array of integer ids of the subjects one wishes to unretire
  + subject_set_id (optional, integer) ... integer id of the subject_set with subjects that one wishes to unretire
  + subject_set_ids (optional, array(integer)) ... integer ids of the subject_sets with subjects that one wishes to unretire

## Request Classification Export by Workflow

```http
POST /api/workflows/123/classifications_export HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
A user can request a classification export by workflow of a project they own or have proper permissions.

<aside class="notice">
<b>Please wait at least 24 hours for your export to be generated.</b> <br>

When Panoptes receives this request, it runs a background job to create the csv export. <br>
 Once your csv has been generated, you should receive an email from <i>no-reply@zooniverse.org</i> titled <i>Classification Data is Ready</i> which will contain a link to the project's lab data exports page where you can download the generated export.
</aside>

See: <a href="https://help.zooniverse.org/next-steps/data-exports/" target="_blank"><b>Data Exports Section on Next Steps</b></a> to parse the resulting csv.

Response will be an HTTP 201