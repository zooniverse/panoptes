# Memberships
```json
{
    "links": {
        "memberships.user_group": {
            "href": "/user_groups/{memberships.user_group}",
            "type": "user_groups"
        },
        "memberships.user": {
            "href": "/users/{memberships.user}",
            "type": "users"
        }
    },
    "meta": {
        "memberships": {
            "page": 1,
            "page_size": 2,
            "count": 28,
            "include": [],
            "page_count": 14,
            "previous_page": 14,
            "next_page": 2,
            "first_href": "/memberships?page_size=2",
            "previous_href": "/memberships?page=14page_size=2",
            "next_href": "/memberships?page=2&page_size=2",
            "last_href": "/memberships?page=14&page_size=2"
        }
    },
    "memberships": [{
        "id": "101",
        "created_at": "2014-04-20T06:23:12Z",
        "updated_at": "2014-04-20T06:23:12Z",
        "state": "active",
        "roles": ["group_admin"],
        "links": {
            "user": "12",
            "user_groups": "31"
        }
    },{
        "id": "111",
        "created_at": "2014-04-20T06:23:12Z",
        "updated_at": "2014-04-20T06:23:12Z",
        "state": "inactive",
        "roles": [],
        "links": {
            "user": "12",
            "user_groups": "20"
        }
    }]
}
```

A membership represents and user's status in a group and their role
within the group.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
created_at | string | read-only
updated_at | string | read-only
state | string |
roles | array(string) |


*id*, *created_at*, and *update_at* are assigned by the API.

+ Membership *state* can be:
  + "invited"
  + "active"
  + "inactive"

When a user is added to a group, their state is set to "invited". After they take
action to join the group their state becomes "active". A User who leaves
a group has their state set to "inactive".

## List All Memberships
```http
GET /api/memberships HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... index of the page to retrieve 1 by default
  + page_size (optional, integer) ... number of items per page 20 by default
  + sort (optional, string) ... field to sort by, id by default
  + user_id (optional, integer) ... filter list to memberships for a user
  + user_group_id (optional, integer) ... filter list to memberships for a user group

All memberships add a meta attribute hash containing paging
information.

Memberships are returned as an array under *memberships*.


## Retreive a Membership
```http
GET /api/memberships/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the resource to retrieve

## Create a Membership
```http
POST /api/memberships HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "memberships": {
        "join_token": "decafbad",
        "links": {
            "user": "10",
            "user_group": "11
        }
    }
}
```
A membership creation request must include a link to a user and to a
user_group, although currently the linked user must always be the current user.
The request must also include the secret join_token of the user_group as an attribute
of the membership (although this property is not persisted).


## Edit a Membership
```http
PUT /api/memberships/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "memberships": {
        "state": "inactive"
    }
}
```
A user can ordinary only change their membership state. A user with
user group edit permissions can change the membership's roles.


## Destroy a Membership
```http
DELETE /api/memberships/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
Destroying a membership only sets the state to inactive. A user may
destroy their own memberships and a user with edit permission in a
user group may destroy membership for that group.

