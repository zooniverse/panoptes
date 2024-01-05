# UserGroups
```json
{
        "links": {
        "user_groups.projects": {
            "href": "/projects?owner={user_groups.owner_name}",
            "type": "projects"
        },
        "user_groups.classifications": {
            "href": "/classifications?user_group_id={user_groups.id}",
            "type": "classifications"
        },
        "user_groups.collections": {
            "href": "/collections?owner={user_groups.owner_name}"
            "type": "collections"
        },
        "user_groups.users": {
            "href": "/users?user_group_id={user_groups.id}",
            "type": "users"
        },
        "user_groups.memberships": {
            "href": "/memberships?user_group_id={user_groups.id}",
            "type": "memberships"
        }
    },
    "meta": {
        "user_groups": {
            "page": 1,
            "page_size": 2,
            "count": 28,
            "include": [],
            "page_count": 14,
            "previous_page": 14,
            "next_page": 2,
            "first_href": "/user_groups?page_size=2",
            "previous_href": "/user_groups?page=14page_size=2",
            "next_href": "/user_groups?page=2&page_size=2",
            "last_href": "/user_groups?page=14&page_size=2"
        }
    },
    "user_groups": [{
        "id": "42",
        "name": "a_cool_group",
        "display_name": "A Cool Group",
        "owner_name": "a_cool_group",
        "created_at": "2014-08-11T10:11:34Z",
        "updated_at": "2014-12-11T00:11:34Z",
        "classifications_count": "1002340",
        "activated_state": "active",
        "stats_visibility": "private_agg_only",
        "links": {
            "memberships": ["101", "102"],
            "users": ["10001", "9102"],
            "projects": ["10"],
            "collections": ["11"]
        }
    },{
        "id": "44",
        "name": "a_cool_gang",
        "display_name": "A Cool Gang",
        "owner_name": "a_cool_gang",
        "created_at": "2014-09-10T10:41:54Z",
        "updated_at": "2014-11-11T01:21:33Z",
        "classifications_count": "2341",
        "activated_state": "active",
        "stats_visibility": "public_show_all",
        "links": {
            "memberships": ["101", "102"],
            "users": ["10001", "9102"],
            "projects": ["10"],
            "collections": ["11"]
        }
    }]
}
```

A user group represents a collection of users that share ownership of
projects, collections, and classifications. Individual users within
the group can be given different levels of permissions to act on
group owned resources.

A User Group has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
classifications_count | integer |
activated_state | string |
name | string |
display_name | string |
stats_visibility | string |
created_at | datetime | read-only
updated_at | datetime | read-only


*id*, *created_at*, *updated_at*, and *classifications_count* are all
 set by the API.

## Stats Visibility Levels
We have added Stats Visibility Levels for new stats features on User Groups. The `stats_visibility` is an enum type on the `user_group` model on Panoptes.

**Currently there are 5 Levels of Visibility.**

**Stats Visibility Levels (Matching number with its corresponding numeric in Panoptes):**

0) `private_agg_only` (DEFAULT) : Only members of a user group can view aggregate stats. Individual stats are ONLY viewable by ADMINS of the user group. <br/>
1)  `private_show_agg_and_ind`: Only members of a user group can view aggregate stats. Individual stats is viewable by BOTH members and admins of the user group. <br/>
2) `public_agg_only`: Anyone can view aggregate stats of the user group. Only ADMINS of the user group can view individual stats. <br/>
3) `public_agg_show_ind_if_member`: Anyone can view aggregate stats of the user group. Both members and admins of the user group can view individual stats. <br/>
4) `public_show_all`: Anyone can view aggregate stats of the user group and can view individual stats of the user group. Authentication/Authorization to view user_group stats is NOT needed.


## List all User Groups
```http
GET /api/user_groups HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... index of the page to retrieve 1 by default
  + page_size (optional, integer) ... number of items per page 20 by default
  + sort (optional, string) ... field to sort by, id by default
  + user_id (optional, integer) ... filter list to groups a user is part of
  + include (optional, string) ... comma separated list of linked resources to include in the response

Response has a meta attribute hash containing paging
information.

User Groups are returned as an array under *user_groups*.

## Retrieve a single User Group
```http
GET /api/user_groups/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
    + id (required, integer) ... integer, id of the user group
    + include (optional, string) ... comma separated list of linked resources to include in the response

## Create a User Group
```http
POST /api/user_groups HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "user_groups": {
        "display_name": "A Super Grouper!",
        "links": {
            "users": ["10", "22"]
        }
    }
}
```

A user can create new group by just giving it a name (how it appears
in a @mention and url) or display name (how it shown to other users).

In the case where only a display name is provided, the name will be
set to the underscored, downcased, and url escaped version of the
display name. When only a name is provided, display_name will be set
to the same string as name.

Optionally links to other users who will be given
memberships with the 'invited' state.


## Edit a single User Group
```http
PUT /api/user_groups/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "user_groups": {
        "display_name": "A Uncool Group",
        "links": {
            "projects": [],
            "collections": []
        }
    }
}
```

A user with edit permissions on a user group may edit the group's
name, display_name, or links to projects, collections and
users. Projects and Collections may only be removed. Removing a
link to a project or collection will destroy the project or
collection, removing a link to a user will set their
membership state to inactive.

Adding a user creates a membership link with an 'invited'
state. Membership and Classification links cannot be modified.

**This is NOT the recommended way to modify links.**

## Destroy a User Group
```http
DELETE /api/user_groups/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

A user may destroy a group if they have the requisite permissions. A
destroyed group and linked projects, collections, and memberships will
be placed in an 'inactive' state.


## Add user links
```http
POST /user_groups/123/links/users HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "users": ["123", "23"]
}
```

Only links to users may be added. Creates a membership for a user. The membership will be immediately
added, but a user won't show up in the group's links until they set
their membership to 'active'.
Only links to users may be added.

## Remove links
```http
DELETE /user_groups/123/links/users/1,2,3 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... id of the group to be edited.
  + link_type (required, string) ... name of the link to modify
  + link_ids (required, string) ... comma separated list of ids to remove

Allows links to users, projects, or collections to be removed. Removed
projects and collections are deleted. Removed users have their
membership set to 'inactive'.
