# Projects

```json
{
    "projects": [{
        "id": "1",
        "display_name": "Galaxy Zoo",
        "classifications_count": "1000000",
        "subjects_count": "10000",
        "created_at": "2014-03-24T10:42:21Z",
        "updated_at": "2014-03-24T10:42:21Z",
        "available_languages": ["en"],
        "title": "Galaxy Zoo",
        "description": "A Project ...",
        "guide": [{
            "image": "http://something.example.com/delorean.jpg",
            "explanation": "our ride"
        }],
        "team_members": [{
            "name": "Doc Brown",
            "bio": "",
            "twitter": "thatsmydelorean",
            "insitution": nil
        }],
        "science_case": "88mph + 1.21 GW = 1955",
        "introduction": "asdfasdf",
        "background_image": "http://test.host/12312asd.jp2",
        "private": false,
        "faq": "This project uses..",
        "result": "We found amazing things",
        "education_content": "Educator content goes here",
        "retired_subjects_count": "5000",
        "configuration": { "option_1": "value" },
        "beta": "false",
        "approved": "true",
        "live": "true",
        "links": {
            "owner": {
                "id": "2",
                "display_name": "Owner 2",
                "href": "/users/2",
                "type": "user"
            }
        }
    }],
    "links": {
        "projects.subjects": {
            "href": "/subjects?project_id={projects.id}",
            "type": "subjects"
        },
        "projects.classifications": {
            "href": "/classifications?project_id={projects.id}",
            "type": "classifications"
        },
        "projects.workflows": {
            "href": "/workflows?project_id={projects.id}",
            "type": "workflows"
        },
        "projects.subject_sets": {
            "href": "/subject_sets/{projects.subject_sets}",
            "type": "subject_sets"
        },
        "projects.owner": {
            "href": "/{projects.owner.href}",
            "type": "owners"
        }
    }
}
```

A Project is a collection of subjects and task workflows that a
volunteer performs on subjects. The project also holds supplementary
text describing the tasks volunteers perform.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
display_name | string |
classifications_count | integer | read-only
subjects_count | integer | read-only
created_at | string | read-only
updated_at | string | read-only
available_languages | array(string) |
title | string |
description | string |
guide | array(hash) |
team_members | array(hash) |
science_case | string |
introduction | string |
avatar | ?? |
background_image | string |
private | boolean |
faq | string |
result | string |
education_content | string |
retired_subjects_count | integer | read-only
configuration | hash |
beta | boolean |
approved | boolean |
live | boolean |

*id*, *created_at*, *updated_at*, *user_count*, and
*classifications_count* are set by the API.

### Project Links

- `workflows`
- `subject_sets` - If you add a link to a subject set that does not already belong
  to the project, Panoptes will make a duplicate of that subject set in this
  project. Note that you can only link subject sets of other projects that you
  are a collaborator on.
- subjects (read-only)
- classifications (read-only)
- owner (read-only)

## List All Projects

```http
GET /api/projects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + display_name (string) ... project name filter
  + approved (boolean) ... approved state filter
  + beta (boolean) ... beta state filter
  + live (boolean) ... live state filter
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + owner (optional, string) ... string owner name of either a user or a user group to filter by.
  + include (optional, string) ... comma separated list of linked resources to include in the response

## Retrieve a single Project

```http
GET /api/projects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the resource to retrieve
  + display_name (string) ... project name filter
  + approved (boolean) ... approved state filter
  + beta (boolean) ... beta state filter
  + live (boolean) ... live state filter

## Create a Project

```http
POST /api/projects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "projects": {
        "name": "galaxy_zoo",
        "description": "A doubleplus good project",
        "primary_language": "en-us",
        "private": true,
        "links": {
            "workflows": ["1", "2"]
            "owner": {
                "id": 10,
                "display_name": "Owner 2",
                "type": "user_groups",
                "href": "user_groups/10"
            }
        }
    }
}
```

Requires at least a *display_name*, *description*, *primary_language* and *private*. Workflows
and SubjectSets added as links will be copied and their new ids
returned.


## Edit a single Project

```http
PUT /api/projects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "projects": {
        "display_name": "Galaxy Zooooooooo!",
        "links": {
            "workflows": ["1"],
            "subject_sets": ["10"]
        }
    }
}
```

A User must be the owner of a project or have update
permissions to edit the resource. Workflow and Subject Set links may be
edited. Removing a subject set or workflow causes the subject set or
workflow to be destroyed. Adding a workflow or subject set causes
the original to be copied and a new id to be returned.

Setting has may links through a PUT, while supported, is not
recommended. Instead, use the link endpoints explained below.

## Destroy a single Project

```http
DELETE /api/projects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

A user may destroy a project they own or have destroy permissions for.

Response will be an HTTP 204.
