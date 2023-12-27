# Collections

```json
{
    "links": {
        "collections.subjects": {
            "href": "/subjects{?collection_id=collections.id}",
            "type": "subjects"
        }
    },
    "collections": [{
        "id": "101",
        "created_at": "2014-04-20T06:23:12Z",
        "updated_at": "2014-04-20T06:23:12Z",
        "name" : "flowers",
        "display_name": "Lots of Pretty flowers",
        "default_subject_src": "panoptes-uploads.zooniverse.org/production/subject_location/hash.jpeg",
        "links": {
            "owner": {
                "id": "10",
                "display_name": "Owner 10",
                "href": "/users/10",
                "type": "users"
            }
        }
    }]
}
```

A collection is a user curated set of subjects for a particular
project.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
display_name | string |
name | string |
created_at | string | read-only
updated_at | string | read-only
default_subject | id |


*id*, *created_at*, and *updated_at* are set by the API.

## List all collections
```http
GET /api/collections HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + owner (optional, string) ... string name of either a user or user group to filter by

All collections add a meta attribute hash containing paging
information. <br/>
Collections are returned as an array under *collections*.

## Retrieve a single collection
```http
GET /api/projects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the resource to retrieve
  + display_name (string) ... project name filter

## Create a Collection
A Collection only needs a *display name* to be created. By default
name will be the underscored and downcased version of *display_name*,
and the current user will be set as the owner.

Optionally a create request may include name, a link to an
owner, and links to subjects.

```http
POST /api/collections HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "collections": {
        "display_name": "flowers",
        "links": {
            "owner": {
                "id" : "10",
                "display_name": "Owner 10",
                "type": "user_groups",
                "href": "/user_groups/10"
            }
        }
    }
}
```


## Edit a Collection

```http
PUT /api/collections/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "collections": {
        "name": "flower_power",
    }
}
```
A user may edit a collection they are the owner of or have edit
permissions for. A user may edit a collection's name, or display_name,
and may also send a full representation of a collections subject links
or a single subject id to set the default subject.

Sending subject links through a put is not recommend, especially if a
collection has many subjects.

Removing subjects from a collection does not destroy the subject record.


## Destroy a Collection
```http
DELETE /api/collections/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
A user who is the owner of a collection or who has destroy permissions
for a collection, may delete it.


## Add subject links
Add subjects to a collection.

```http
POST /api/collections/123/links/subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subjects": ["1", "2"]
}
```

A user is permitted to add subject if they are the collection owner or
have edit permissions.


## Remove subject links [/collection/{id}/links/subjects/{link_ids}]
```http
DELETE /api/collections/123/links/subjects/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Remove subjects from a collection.

A user is permitted to remove subjects if they are the collection
owner or have edit permissions.

+ Parameters
  + id (required, integer) ... id of collection to edit
  + link_ids (required, string) ... comma separated list of ids to remove


## Add default subject link

```http
POST /api/collections/123/links/default_subject HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "default_subject": "1"
}
```
Links a default subject to a collection. This subject's first media
location URL will be included in the serialized collection and used
as the thumbnail. Update this attribute with `null` to use the first
subject in the linked list instead.

A user is permitted to add a default subject if they are the collection
owner or have edit permissions.