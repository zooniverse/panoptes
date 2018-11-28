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

- id
- display_name
- classifications_count
- subjects_count
- created_at
- updated_at
- available_languages
- title
- description
- guide
- team_members
- science_case
- introduction
- avatar
- background_image
- private
- faq
- result
- education_content
- retired_subjects_count
- configuration
- beta
- approved
- live

*id*, *created_at*, *updated_at*, *user_count*, and
*classifications_count* are set by the API.

## Project [/projects/{id}{?include,display_name,approved,beta,live}]

+ Parameters
  + id (required, integer) ... integer id of the resource to retrieve
  + display_name (string) ... project name filter
  + approved (boolean) ... approved state filter
  + beta (boolean) ... beta state filter
  + live (boolean) ... live state filter

+ Model

    + Body


### Retrieve a single Project [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Project][]

### Edit a single Project [PUT]
A User must be the owner of a project or have update
permissions to edit the resource. Workflow and Subject Set links may be
edited. Removing a subject set or workflow causes the subject set or
workflow to be destroyed. Adding a workflow or subject set causes
the original to be copied and a new id to be returned.

Setting has may links through a PUT, while supported, is not
recommended. Instead, use the link endpoints explained below.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "projects": {
                    "display_name": "Galaxy Zooooooooo!",
                    "links": {
                        "workflows": ["1"],
                        "subject_sets": ["10"]
                    }
                }
            }

+ Response 200

    [Project][]

### Destroy a single Project [DELETE]
A user may destroy a project they own or have destroy permissions for.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Project Create Links [/project/{id}/links/{link_type}]
The recommended way to edit a project's subject set and workflow
links.

### Add a Link [POST]
The body key must match the link_type parameter. Workflows and Subject Sets
added in this way will be copied and their id will be returned as part
of the complete Project representation response.

+ Parameters
  + id (required, integer) - the id of the project to add
  + link_type (required, string)
    the name of the link to edit
        + Members
            + `workflows`
            + `subject_sets`

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "subject_sets": ["1", "2"]
            }

+ Response 200

    [Project][]

## Project Destroy Links [/project/{id}/links/{link_type}/{link_ids}]
The recommended way to destroy project links.

### Destroy a Link [DELETE]
Will destroy the comma separated list of link ids for the given link
type. For Projects, only workflow and subject_set links can be
destroyed in this manner. The linked object will be destroyed with
this action.

+ Parameters
  + id (required, integer) ... the id of the project to modify
  + link_type (required, string)
    the name of the link to edit
        + Members
            + `workflows`
            + `subject_sets`
  + link_ids (required, string) ... comma separated list of ids to destroy

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Project Collection [/projects{?page,page_size,sort,owner,include}]
A collection of _Panotpes Project_ resources.

All collections add a *meta* attribute hash containing
paging information.

Projects are returned as an array under the _projects_ key.

+ Model

    A JSON API formatted representation of a collection of Projects.

    + Body

            {
                "links": {
                    "projects.subjects": {
                        "href": "/subjects{?project_id=projects.id},
                        "type": "subjects"
                    },
                    "projects.classifications": {
                        "href": "/classifications{?project_id=projects.id}",
                        "type": "classifications"
                    },
                    "projects.workflows": {
                        "href": "/workflows/{projects.workflows}",
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
                },
                "meta": {
                   "projects": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/projects?page_size=2",
                        "previous_href": "/projects?page=14page_size=2",
                        "next_href": "/projects?page=2&page_size=2",
                        "last_href": "/projects?page=14&page_size=2"
                    }
                },
                "projects": [{
                    "id": "1",
                    "created_at": "2014-03-24T10:42:21Z",
                    "updated_at": "2014-03-24T10:42:21Z",
                    "name": "galaxy_zoo",
                    "display_name": "Galaxy Zoo",
                    "primary_language": "en",
                    "user_count": "10000",
                    "classifications_count": "1000000",
                    "activated_state": 0,
                    "title": "Galaxy Zoo",
                    "description": "A Project ...",
                    "introduction": "asdfasdf",
                    "science_case": "88mph + 1.21 GW = 1955",
                    "team_members": [{
                        "name": "Doc Brown",
                        "bio": "",
                        "twitter": "thatsmydelorean",
                        "insitution": nil
                    }],
                    "guide": [{
                        "image": "http://something.example.com/delorean.jpg",
                        "explanation": "our ride"
                    }],
                    "links": {
                        "owner": {
                            "id": "2",
                            "display_name": "Owner 2",
                            "href": "/users/2",
                            "type": "users"
                        }
                    }
                },{
                    "id": "2",
                    "created_at": "2014-03-24T10:42:21Z",
                    "updated_at": "2014-03-24T10:42:21Z",
                    "name": "galaxy_zoo_2",
                    "display_name": "Galaxy Zoo 2",
                    "primary_language": "en",
                    "user_count": "10000",
                    "classifications_count": "1000000",
                    "activated_state": 0,
                    "title": "Galaxy Zoo",
                    "description": "A Project ...",
                    "introduction": "asdfasdf",
                    "science_case": "88mph + 1.21 GW = 1955",
                    "team_members": [{
                        "name": "Doc Brown",
                        "bio": "",
                        "twitter": "thatsmydelorean",
                        "insitution": nil
                    }],
                    "guide": [{
                        "image": "http://something.example.com/delorean.jpg",
                        "explanation": "our ride"
                    }],
                    "links": {
                        "owner": {
                            "id": "2",
                            "display_name": "Owner 2",
                            "href": "/users/2",
                            "type": "users"
                        }
                    }
                }]
            }

### List All Projects [GET]

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + owner (optional, string) ... string owner name of either a user or a user group to filter by.
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Project Collection][]


### Create a Project [POST]
Requires at least a *display_name*, *description*, *primary_language* and *private*. Workflows
and Subject sets added as links will be copied and their new ids
returned.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

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

+ Response 201

    [Project][]


