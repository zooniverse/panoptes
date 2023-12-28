# SetMemberSubjects
```json
{
    "links": {
        "set_member_subjects.subject": {
            "href": "/subjects/{set_member_subjects.subject}",
            "type": "subjects"
        },
        "set_member_subjects.subject_set": {
            "href": "/subject_sets/{set_member_subjects.subject_set}",
            "type": "subject_sets"
        }
    },
    "meta": {
        "set_member_subjects": {
            "page": 1,
            "page_size": 2,
            "count": 28,
            "include": [],
            "page_count": 14,
            "previous_page": 14,
            "next_page": 2,
            "first_href": "/set_member_subjects?page_size=2",
            "previous_href": "/set_member_subjects?page=14page_size=2",
            "next_href": "/set_member_subjects?page=2&page_size=2",
            "last_href": "/set_member_subjects?page=14&page_size=2"
        }
    },
    "set_member_subjects": [{
        "id": "1023",
        "created_at": "2014-03-20T00:15:47Z",
        "updated_at": "2013-09-30T10:20:32Z",
        "state": "active",
        "priority": 101231.1231,
        "links": {
            "subject": "1231",
            "subject_set": "101"
        }
    },{
        "id": "1024",
        "created_at": "2014-03-20T00:15:47Z",
        "updated_at": "2013-09-30T10:20:32Z",
        "state": "retired",
        "priority": 1231.1231,
        "links": {
            "subject": "1232",
            "subject_set": "101"
        }
    }]
}
```

A Set Member Subject resource contains the state of a subject that is
included in a resource.

It has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
state | string |
priority | float |
created_at | datetime | read-only
updated_at | datetime | read-only

*id*, *created_at*, and *updated_at* are set by the API server.


## List all SetMemberSubjects
```http
GET /api/set_member_subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + subject_id (optional, integer) ... id of subject to see set_member_subjects for
  + subject_set_id (optional, integer) ... id of subject_set to see set_member_subjects for
  + include (optional, string) ... comma separated list of linked resources to load

Response will contain a meta attribute hash containing paging information.

SetMemberSubjects are returned as an array under *set_member_subjects*.


## Retrieve a Single SetMemberSubject
```http
GET /api/set_member_subjects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
+ Parameters
    + id (required, integer) ... integer identifier for the resource
    + include (optional, string) ... comma separated list of linked resources to load

## Create a SetMemberSubject
```http
POST /api/set_member_subjects HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "set_member_subjects: {
        "links": {
            "subject": "12031",
            "subject_set": "10"
        }
    }
}
```

A SetMemberSubject may be created by a user that can see the Subject
they wish to link to and can edit the project the SubjectSet belongs
to.

A SetMemberSubject requires links be provided to a Subject and a
SubjectSet. Optionally, the create request may include a state and a
priority. The state will be 'active' by default and the priority will
be null by default.


### Edit a SetMemberSubject
```http
PUT /api/set_member_subjects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "set_member_subjects: {
        "state": "inactive"
    }
}
```

A user with edit permissions for the project a SetMemberSubject's
SubjectSet belongs to may edit the *state* and *priority* attributes.


## Destroy a SetMemberSubject
```http
DELETE /api/set_member_subjects/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```
A user with edit permissions for the project a SetMemberSubject's
Subject belongs to may destroy a SetMemberSubject resource. This
removes the linked Subject form the linked SubjectSet


