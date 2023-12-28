# Organizations

```json
{
  "organizations": [
    {
      "id": "5",
      "display_name": "United Federation of Projects",
      "description": "Every project in the galaxy",
      "introduction": "Hello and welcome to the UFP",
      "title": "United Federation of Projects",
      "href": "/organizations/5",
      "primary_language": "en",
      "listed_at": null,
      "listed": true,
      "slug": "user/slug",
      "urls": [
        {
          "url": "https://twitter.com/UFP",
          "path": "United Federation of Twitter",
          "site": "twitter.com/",
          "label": ""
        }
      ],
      "categories": [],
      "announcement": "Oh Gosh!",
      "links": {
        "organization_contents": [
          "5"
        ],
        "organization_roles": [
          "9999"
        ],
        "projects": [
          "1",
          "2"
        ],
        "owner": {
          "id": "811067",
          "display_name": "meredithspalmer",
          "type": "users",
          "href": "/users/811067"
        },
        "pages": [
          "5"
        ],
        "avatar": {
          "href": "/organizations/5/avatar",
          "type": "avatars",
          "id": "27687087"
        },
        "background": {
          "href": "/organizations/5/background",
          "type": "backgrounds",
          "id": "30335947"
        },
        "attached_images": {
          "href": "/organizations/5/attached_images",
          "type": "attached_images"
        }
      }
    }
  ],
  "links": {
    "organizations.attached_images": {
      "href": "/organizations/{organizations.id}/attached_images",
      "type": "media"
    },
    "organizations.organization_contents": {
      "href": "/organization_contents?organization_id={organizations.id}",
      "type": "organization_contents"
    },
    "organizations.organization_roles": {
      "href": "/organization_roles?organization_id={organizations.id}",
      "type": "organization_roles"
    },
    "organizations.projects": {
      "href": "/projects?organization_id={organizations.id}",
      "type": "projects"
    },
    "organizations.pages": {
      "href": "/organizations/{organizations.id}/pages",
      "type": "organization_pages"
    },
    "organizations.owner": {
      "href": "/{organizations.owner.href}",
      "type": "owners"
    },
    "organizations.avatar": {
      "href": "/organizations/{organizations.id}/avatar",
      "type": "media"
    },
    "organizations.background": {
      "href": "/organizations/{organizations.id}/background",
      "type": "media"
    }
  },
  "meta": {
    "organizations": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/organizations",
      "previous_href": null,
      "next_href": null,
      "last_href": "/organizations"
    }
  }
}
```

An Organization is a collection of projects that are related by dicipline, research group

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
display_name | string |
title | string |
description | string |
introduction | string |
slug | string |
primary_language | string |
listed_at | datetime |
activated_state | integer |
created_at | datetime | read-only
updated_at | datetime | read-only
urls | jsonb |
listed | boolean |
categories | string |
available_languages | array(string) |
background | string |
avatar | string |

## List All Organizations
```http
GET /api/organizations HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + owner (optional, string) ... string owner name of either a user or a user group to filter by.
  + include (optional, string) ... comma separated list of linked resources to include in the response

Response a *meta* attribute hash containing
paging information.

Organizations are returned as an array under the _organizations_ key.


## Retrieve a single Organization
```http
GET /api/organizations/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
+ Parameters
  + id (required, integer) ... integer id of the resource to retrieve
  + include (optional, string) ... comma separated list of linked resources to include in the response
  + display_name (optional, string)...name filter
  + listed (boolean) ... publicly visible


## Create a Organization
```http
POST /api/organizations HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "Organizations": {
        "display_name": "United Federation of Projects",
        "description": "Lots o' Projects",
        "primary_language": "en-us",
        "links": {
            "projects": ["1", "2"]
        }
    }
}
```

Requires at least a *display_name*, *description* and primary_language*.


## Edit a single Organization
```http
PUT /api/organizations/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "organizations": {
      "display_name": "Klingon Empire",
      "links": {
          "workflows": ["1"],
          "subject_sets": ["10"]
      }
  }
}
```

A User must be the owner of a Organization or have update
permissions to edit the resource.

Setting has may links through a PUT, while supported, is not
recommended. Instead, use the link endpoints explained below.


## Destroy a single Organization
```http
DELETE /api/organizations/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
A user may destroy a Organization they own or have destroy permissions for.

## Add Organization Links
```http
POST /api/organizations/123/links/projects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "projects": ["1", "2"]
}
```
The body key must match the link_type parameter.

+ Parameters
  + id (required, integer) - the id of the project to add
  + link_type (required, string)
    the name of the link to edit
        + Members
            + `projects`


## Destroy a Link
```http
DELETE /api/organizations/123/links/projects/1,2 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
The recommended way to destroy Organization links.
Will destroy the comma separated list of link ids for the given link
type. 

+ Parameters
  + id (required, integer) ... the id of the project to modify
  + link_type (required, string)
    the name of the link to edit
        + Members
            + `projects`
  + link_ids (required, string) ... comma separated list of ids to destroy