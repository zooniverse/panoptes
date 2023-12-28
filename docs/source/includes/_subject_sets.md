# SubjectSets
```json
{
    "links": {
        "subject_sets.workflows": {
            "href": "/workflows?subject_set_id={subject_sets.id}",
            "type": "workflows"
        },
        "subject_sets.subjects": {
            "href": "/subjects{?subject_set_id=subject_sets.id}",
            "type": "subjects"
        },
        "subject_sets.set_member_subjects": {
            "href": "/set_member_subjects{?subject_set_id=subject_sets.id}",
            "type": "set_member_subjects"
        },
        "subject_sets.project": {
            "href": "/project/{subject_sets.project}",
            "type": "projects"
        }
    },
    "meta": {
        "subject_sets": {
            "page": 1,
            "page_size": 2,
            "count": 28,
            "include": [],
            "page_count": 14,
            "previous_page": 14,
            "next_page": 2,
            "first_href": "/subject_sets?page_size=2",
            "previous_href": "/subject_sets?page=14page_size=2",
            "next_href": "/subject_sets?page=2&page_size=2",
            "last_href": "/subject_sets?page=14&page_size=2"
        }
    },
    "subject_sets": [{
        "id": "20",
        "display_name": "Weird Looking Galaxies",
        "metadata": {
            "category": "things"
        },
        "created_at": "2014-02-13T10:11:34Z",
        "updated_at": "2014-02-13T10:11:34Z",
        "set_member_subject_count": 100,
        "links": {
            "project": "1",
            "workflow": "10"
        }
    },{
        "id": "20",
        "display_name": "Boring Looking Galaxies",
        "metadata": {
            "category": "things"
        },
        "created_at": "2014-02-13T10:11:34Z",
        "updated_at": "2014-02-13T10:11:34Z",
        "set_member_subject_count": 100,
        "links": {
            "project": "1",
            "workflow": "11"
        }
    }]
}
```

Subject Sets represent collections of Subjects that are paired with a
workflow of questions to be answered. A SubjectSet belongs to one
Workflow, while a single Workflow may have many SubjectSets.

A SubjectSet has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
display_name | string |
metadata | jsonb |
set_member_subjects_count | integer |
created_at | datetime | read-only
updated_at | datetime | read-only

All attributes except display_name are set by the API

## List all Subject Sets
```http
GET /api/subject_sets HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... index of the page to retrieve 1 by default
  + page_size (optional, integer) ... number of items per page 20 by default
  + sort (optional, string) ... field to sort by, id by default
  + project_id (optional, integer) ... filter by linked project
  + workflow_id (optional, integer) ... filter by linked workflow
  + include (optional, string) ... comma separated list of linked resources to include in the response

Response contains a meta attribute hash containing paging
information.

Subject Sets are returned as an array under *subject_sets*.


## Retrieve a single Subject Set
```http
GET /api/subject_sets/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
    + id (required, integer) ... integer id of the subject_set to retrieve
    + include (optional, string) ... comma separated list of linked resources to include in the response

## Create a Subject Set
```http
POST /api/subject_sets HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subject_sets": {
        "display_name": "A Group of Interesting Subjects",
        "metadata": {
            "category": "things"
        },
        "links": {
            "project": "43",
            "workflows": ["47"],
            "subjects": ["234", "1243", "8023"]
        }
    }
}
```
A subject set must supply a display_name and a link to a project. Optionally,
it may include links to subjects and a single workflow.

Instead of a list of subjects a SubjectSet may include a link to a
Collection which will import the collection's subjects into a new
SubjectSet.


## Edit a single Subject Set
```http
PUT /api/subject_sets/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subject_sets": {
        "display_name": "Normal Galaxies",
        "links": {
            "subjects": ["1", "2", "4", "5", "10"]
        }
    }
}
```

A user may only edit a subject if they edit permissions for the parent
project. The display_name attributes and links to workflows and subjects are
editable. Editing links requires a full representation of the new set
of links, but does not destroy unlinked resources.

This is NOT the recommended way to manage linked subjects.


## Destroy a Subject Set
```http
DELETE /api/subject_sets/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

A user may only destroy a subject set if they have destroy permissions
for the subject set's project.

## Subject Set Links
Allows the addition of links to subjects to a subject
set object without needing to send a full representation of the linked
relationship.

**This is the recommended way to managed linked subjects.**

## Add Subject Set Link
```http
POST /api/subject_sets/123/links/subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subjects": ["1", "5", "9", "11"]
}
```

+ Parameters
  + id (required, integer) ... the id of the Subject Set to modify
  + link_type (required, string) ... the relationship to modify must be the same as the supplied body key
Only Subjects links may be edited.


## Destroy Subject Set Links
```http
DELETE /api/subject_sets/123/links/subjects/1,2,3 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Allows links to be removed without sending a full representation of the
linked relationship.

+ Parameters
  + id (required, integer) ... the id of the Subject Set to modify
  + link_type (required, string) ... the relationship to modify
  + link_ids (required, integer) ... comma separated list of ids to remove

Will only remove the link. This operation does not destroy the linked object.

