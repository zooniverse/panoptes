# CollectionRole
```json
{
    "links": {
        "collection_roles.owner": {
            "href": "/{collection_roles.owner.href}",
            "type": "owners"
        },
        "collection_roles.collection": {
            "href": "/collections/{collection_roles.collection}",
            "type": "collections"
        }
    },
    "meta": {
        "collection_roles": {
            "page": 1,
            "page_size": 2,
            "count": 28,
            "include": [],
            "page_count": 14,
            "previous_page": 14,
            "next_page": 2,
            "first_href": "/collection_roles?page_size=2",
            "previous_href": "/collection_roles?page=14page_size=2",
            "next_href": "/collection_roles?page=2&page_size=2",
            "last_href": "/collection_roles?page=14&page_size=2"
        }
    },
    "collection_roles": [{
        "id": "942",
        "roles": ["collaborator"],
        "created_at": "2014-03-20T06:23:12Z",
        "updated_at": "2014-04-21T08:22:22Z",
        "links": {
            "collection": "11",
            "owner": {
                "id": "4",
                "display_name": "Owner 4",
                "type": "user_groups",
                "href": "user_groups/4"
            }
        }
    },{
    "id": "949",
        "roles": ["viewer"],
        "created_at": "2014-08-20T06:23:12Z",
        "updated_at": "2014-09-21T08:22:22Z",
        "links": {
            "collection": "81",
            "owner": {
                "id": "1",
                "display_name": "Owner 1",
                "type": "users",
                "href": "users/1"
            }
        }
    }]
}
```

Resources related to Roles for _Panoptes Collections_
A Collection Role resources contains an array of roles assigned to a user
for a particular collection.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
created_at | string | read-only
updated_at | string | read-only
roles | array(string) |

*id*, *created_at*, and *updated_at* are set the by the API. Collection
roles are visible to the collection owner and the user given roles.

### Collection Role Types
- `collaborator` - full access to edit or delete a collection
- `viewer` - may view a private collection

## List All Collection Roles

A Collection of CollectionRole resources.

All collections add a meta attribute hash containing paging
information.

CollectionRoles are returned as an array under *collection_roles*.

```http
GET /api/collection_roles HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + user_id (optional, integer) ... user_id to see roles for
  + collection_id (optional, integer) ... collection_id to see roles for
  + include (optional, string) ... comma separate list of linked resources to load



## Retrieve a single CollectionRole

```http
GET /api/collection_roles/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer identifier of the collection role resource
  + include (optional, string) ... comma separate list of linked resources to load

## Create a CollectionRole
```http

POST /api/collection_roles/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "collection_roles": {
        "roles": ["collaborator"],
        "links": {
            "collection": "1",
            "user": "842"
        }
    }
}
```

Creating a Collection Role resource requires a link to a user and a
collection. You may also include an array of roles.


## Edit a CollectionRole
```http
PUT /api/collection_roles/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "collection_roles": {
        "roles": ["viewer"]
    }
}
```
A user with permissions to edit a collection may modify roles for other
users in the collection. A user without edit permissions may not edit
their own roles.

Editing requires sending a full representation of the roles array.
