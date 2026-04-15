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
        },
        "projects.organizations": {
            "href": "/organizations/{projects.organizations}",
            "type": "organizations"
        }
    }
}
```

A Project is a collection of subjects and task workflows that a
volunteer performs on subjects. The project also holds supplementary
text describing the tasks volunteers perform. A project can be linked to
multiple organizations.

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
- `organizations` (read-only) - Projects may be linked to multiple organizations.
  Add or remove these links through the organization project link endpoints.

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
  + organization_id (optional, integer or comma-separated integers) ... return projects linked to one or more organizations.
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

## Copy a Project

```http
POST /api/projects/123/copy HTTP/1.1
Accept: application/vnd.api+json; version=1
```

Creates a new project by copying an existing template project.

The source project must:

- have `configuration.template` set
- not be live

If `create_subject_set` is provided, the copied project will also get a new
empty subject set with that display name.

+ Parameters
  + project_id (required, integer) ... integer id of the template project to copy
  + create_subject_set (optional, string) ... display name for a new empty subject set on the copied project


```http
POST /api/projects/123/copy HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

```http
# Eg request with `create_subject_set`:
POST /api/projects/123/copy HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "create_subject_set": "New Subject Set"
}
```

```json
{
  "projects": [
    {
      "id": "124",
      "display_name": "Example Project (copy: 2026-01-01 12:00:00)",
      "classifications_count": 0,
      "subjects_count": 0,
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z",
      "available_languages": [
        "en"
      ],
      "title": "Example Project (copy: 2026-01-01 12:00:00)",
      "description": "An example project description.",
      "introduction": "An example project introduction.",
      "private": false,
      "retired_subjects_count": 0,
      "configuration": {
        "source_project_id": 123
      },
      "live": false,
      "urls": [],
      "migrated": false,
      "classifiers_count": 0,
      "slug": "example-user/example-project-copy-2026-01-01-12-00-00",
      "redirect": "",
      "beta_requested": false,
      "beta_approved": false,
      "launch_requested": false,
      "launch_approved": false,
      "launch_date": null,
      "href": "/projects/124",
      "workflow_description": null,
      "primary_language": "en",
      "tags": [],
      "experimental_tools": [],
      "completeness": 0.0,
      "activity": 0,
      "state": "development",
      "researcher_quote": null,
      "mobile_friendly": false,
      "featured": false,
      "run_subject_set_completion_events": false,
      "links": {
        "workflows": [
          "321"
        ],
        "active_workflows": [
          "321"
        ],
        "subject_sets": [],
        "owner": {
          "id": "789",
          "display_name": "example-user",
          "type": "users",
          "href": "/users/789"
        },
        "project_roles": [
          "654"
        ],
        "pages": [],
        "organization": null,
        "avatar": {
          "href": "/projects/124/avatar",
          "type": "avatars",
          "id": "9001"
        },
        "background": {
          "href": "/projects/124/background",
          "type": "backgrounds",
          "id": "9002"
        },
        "attached_images": {
          "href": "/projects/124/attached_images",
          "type": "attached_images",
          "ids": []
        },
        "classifications_export": {
          "href": "/projects/124/classifications_export",
          "type": "classifications_exports"
        },
        "subjects_export": {
          "href": "/projects/124/subjects_export",
          "type": "subjects_exports"
        }
      }
    }
  ],
  "linked": {
    "owners": [
      {
        "id": "789",
        "login": "example-user",
        "display_name": "example-user",
        "credited_name": "Example Researcher",
        "created_at": "2025-12-01T08:30:00.000Z",
        "updated_at": "2026-01-01T11:45:00.000Z",
        "type": "users",
        "href": "/users/789",
        "private_profile": true,
        "avatar_src": "https://panoptes-uploads.example.org/user_avatar/example-avatar.jpeg",
        "links": {}
      }
    ]
  },
  "meta": {
    "projects": {
      "include": [
        "owners"
      ]
    }
  }
}
```

## Request a Classifications Export for a Project

```http
POST /api/projects/123/classifications_export HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
A user can request a classification export of a project they own or have proper permissions.

<aside class="notice">
<b>Please wait at least 24 hours for your export to be generated.</b> <br>

When Panoptes receives this request, it runs a background job to create the csv export. <br>
 Once your csv has been generated, you should receive an email from <i>no-reply@zooniverse.org</i> titled <i>Classification Data is Ready</i> which will contain a link to the project's lab data exports page where you can download the generated export.
</aside>

See: <a href="https://help.zooniverse.org/next-steps/data-exports/" target="_blank"><b>Data Exports Section on Next Steps</b></a> to parse the resulting csv.

Response will be an HTTP 201

## Request a Subjects Export for a Project

```http
POST /api/projects/123/subjects_export HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
A user can request a subjects export of a project they own or have proper permissions.

<aside class="notice">
<b>Please wait at least 24 hours for your export to be generated.</b> <br>

When Panoptes receives this request, it runs a background job to create the csv export. <br>
 Once your csv has been generated, you should receive an email from <i>no-reply@zooniverse.org</i> titled <i>Subject Data is Ready</i> which will contain a link to the project's lab data exports page where you can download the generated export.
</aside>

See: <a href="https://help.zooniverse.org/next-steps/data-exports/" target="_blank"><b>Data Exports Section on Next Steps</b></a> to parse the resulting csv.

Response will be an HTTP 201

## Request a Workflows Export for a Project

```http
POST /api/projects/123/workflows_export HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
A user can request a workflows export of a project they own or have proper permissions.

<aside class="notice">
<b>Please wait at least 24 hours for your export to be generated.</b> <br>

When Panoptes receives this request, it runs a background job to create the csv export. <br>
 Once your csv has been generated, you should receive an email from <i>no-reply@zooniverse.org</i> titled <i>Workflow Data is Ready</i> which will contain a link to the project's lab data exports page where you can download the generated export.
</aside>

See: <a href="https://help.zooniverse.org/next-steps/data-exports/" target="_blank"><b>Data Exports Section on Next Steps</b></a> to parse the resulting csv.

Response will be an HTTP 201

