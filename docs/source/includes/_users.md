# Users

```json
{
    "users": [{
        "id": 1,
        "created_at": "2014-03-20T00:15:47Z",
        "updated_at": "2013-09-30T10:20:32Z",
        "credited_name": "Dr. Stuart Lynn",
        "login": "stuart",
        "display_name": "Stuart",
        "owner_name": "stuart",
        "email": "stuart@zoooniverse.org",
        "zooniverse_id": "123432",
        "classifications_count": "104",
        "languages": ["en-gb", "es-mx"]
    }],
    "links": {
        "users.projects": {
            "href": "/projects?owner={users.owner_name}",
            "type": "projects"
        },
        "users.user_groups": {
            "href": "/user_groups?user_id={users.id}",
            "type": "user_groups"
        },
        "users.subjects": {
            "href": "/subjects?user_id={users.id}",
            "type": "subjects"
        },
        "users.collections": {
            "href": "/collections?owner={users.owner_name}",
            "type": "collections"
        }
    }
}
```

A User is representation of the identity and contributions of a volunteer.

Attribute | Type | Description
--------- | ---- | -----------
id | Integer |
created_at | string |
updated_at | string |
credited_name | string | Publicly available name with which a volunteer will be credited on papers, posters, etc
login | string |
display_name | string |
email | string | The email of the user
zooniverse_id | string
classifications_count | integer | Number of classifications this user has made site-wide
languages | Array(String) | Array of language identifier string, in order from most to least preferred. Used to determine which language to show translated projects in.

`id`, `zooniverse_id`, `created_at`, `updated_at`, and `classification_count`
 are created and updated by the Panoptes API.

 `credited_name` is the publicly available name with which a volunteer will be
 credited on papers, posters, etc. When serialized, if an `@` character is
 found, the user's login will be returned instead for privacy reasons.

The `email` attribute is only available if the requesting user is an
administrator or the user resource being requested is that of the requesting
user.

### Links

- projects
- user_groups
- subjects
- collections

## List Users [/users{?page,page_size,sort,include}]

```http
GET /api/users HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
### Parameters

+ page (optional, integer) ... index of the collection page, 1 is default
+ page_size (optional, integer) ... number of items on a page. 20 is default
+ sort (optional, string) ... fields to sort collection by. id is default
+ include (optional, string) ... comma separated list of linked resources to include

## Retrieve a single user

```http
GET /api/users/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Parameter | Type | Default | Description
--------- | ---- | ------- | -----------
id | integer | | ID of the User as an integer key

## Edit a single User [PUT]

```http
PUT /api/users/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "users": {
        "credited_name": "Dr. Stuart Lynn, DDS"
    }
}
```

The currently logged in User may edit their record by sending a
partial representation of the resource including their changes. A User
cannot edit linked resources.

## Destroy a single User [DELETE]

```http
DELETE /users/123 HTTP/1.1
```
The current logged in User may delete themself. This does not fully
remove the user resource; instead, it deactivates their projects
and removes personally identifying information including the
*credited_name* and *email* address.

+ Response 204

