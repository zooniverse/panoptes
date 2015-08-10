# Zooniverse Classification API V2

The Zooniverse Classification API (version 2) is a [JSON-API]() compliant API.

<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-generate-toc again -->
**Table of Contents**

- [Global](#global)
    - [Content-Types](#content-types)
- [Authorization](#authorization)
    - [Authorization Code](#authorization-code)
    - [Client-Credentials](#client-credentials)
    - [Resource Owner Credentials](#resource-owner-credentials)
    - [Implicit Grant](#implicit-grant)
- [API](#api)
    - [JSON-API](#json-api)
    - [Clients](#clients)
    - [Resources](#resources)
        - [Users (/users)](#users-users)
            - [Attributes](#attributes)
            - [Links](#links)
        - [User Groups (/user_groups)](#user-groups-usergroups)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Projects (/projects)](#projects-projects)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Workflows (/workflows)](#workflows-workflows)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Subject Sets (/subject_sets)](#subject-sets-subjectsets)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Classifications (/classifications)](#classifications-classifications)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Subjects (/subjects)](#subjects-subjects)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Subject Queues (/subject_queues)](#subject-queues-subjectqueues)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Collections (/collections)](#collections-collections)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Preferences (/preferences)](#preferences-preferences)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Roles (/roles)](#roles-roles)
            - [Attributes](#attributes)
            - [Links](#links)
        - [Media (/media)](#media-media)
            - [Attributes](#attributes)
            - [Links](#links)
    - [Error Conditions](#error-conditions)

<!-- markdown-toc end -->

## Global

### Content-Types

All requests MUST include an `Accept` header with the value `application/vnd.api+json`.

All requests with a body MUST include a `Content-Type` header with either the value `application/vnd.api+json` or `application/json`. The value provided will affect how the request is processed.

## Authorization

Zooniverse uses [OAuth2]() to allow individuals to authorize applications to access the Zooniverse Classification API on their behalf.

### Authorization Code 

### Client-Credentials

### Resource Owner Credentials

### Implicit Grant

## API

### JSON-API

JSON-API provides a standardized way to interact with an API over HTTP. JSON-API responses look generally like:

```json
{
    "links": {
        "self": "https://www.zooniverse.org/api/users",
        "next": "https://www.zooniverse.org/api/users?page[number]=2",
        "first": "https://www.zooniverse.org/api/users?page[number]=1",
        "previous": null,
        "last": "https://www.zooniverse.org/api/users?page[number]=13"
    },
    "data": [
        {
            "type": "users",
            "id": "1",
            "attributes": {
                "login": "zooniverse"
            },
            "relationships": {
                "editable_projects": {
                    "links": {
                        "self": "https://www.zooniverse.org/api/users/1/relationships/editable_projects",
                        "related": "https://www.zooniverse.org/api/users/1/editable_projects"
                    },
                    "data": [
                        {
                            "type": "projects",
                            "id": "10"
                        }
                    ]
                }
            },
            "links": {
                "self": "https://www.zooniverse.org/api/users/1"
            }
        }
    ],
    "included": [
        {
            "type": "project",
            "id": "10",
            "attributes": {
                "display_name": "Galaxy Zoo"
            },
            "links": {
                "self": "https://www.zooniverse.org/api/projects/10"
            }
        }
    ]
    "meta": {
        filterable: ["login"],
        sortable: ["login"]
    }
}
```

JSON API responses contain four top-level sections

+ `"links"` - describe pagination information for a resource if available as well as the `self` link to the retrieved resource
+ `"data"` - an array of resources returned from the URL, data resource have further important sub-properties
  + `"type"`- a string descriptor of the resource type.
  + `"id"` - a unique identifier for a resource will either be a stringified natural number or a [UUIDv4]() identifier.
  + `"attributes"` - the actual resource element.
  + `"relationships"` - details links the client can follow to retrieve and manipulate related resources. The `"data"` attribute describes any related resources included in this response
  + `"links"` - further links to the resource including the `"self"` link.
+ `"included"` - related resources included with the response through the `?included=` query param.
+ `"meta"` - catchall location for non-standard information. The Zooniverse Classification API uses this to indicate:
  + `"filterable"` - resource attributes a resource collection can be filtered by
  + `"sortable"` - resource attribtues a resource collection can be sorted by 

### Clients

Clients for JSON-API written in a variety of languages can be found [here]().

### Resources

#### Users (/users)

Users use a natural number as an `id`.

A User record can only be modified by a token belonging to the user themself. 

##### Attributes

| Attribute | Type | View Scope | Edit Scope | Description |
|-----------|------|------------|------------|-------------|
| login     | String | Publicly Accessible | user | The user's permanent name |
| display_name | String | Publicly Accessible | user.edit-details | A freeform name for the user |
| credited_name | String | user | user | The name the user will be credited as in publications |
| email | String | user | user | User email address |
| global_email_communication | Boolean | user | user | Flag to indicate if a user wants to receive Zooniverse emails |
| project_email_communication | Boolean | user | user | Flag to indicate if a user wants to be automatically subscribed to emails from projects they classify on |
| beta_email_communication | Boolean | user | user | Flag to indicate if a user wants to be notified about beta tests |
| max_subjects | Number |subject.create | N/A | Total number of subjects a user can upload |
| uploaded_subject_count | Number | subject.create | N/A | Total number of a subjects a user has uploaded |
| admin | Boolean | user | N/A | Whether the use can take administrative actions |
| private_profile | Boolean | Publically Accessible | user | Flag to hide profile information like classification counts |
| created_at | Time | Publicly Accessible | user | Creation Timestamp |
| updated_at | Time  | Publicly Accessible | user | Last updated Timestamp |

##### Links

| Link | Type | Description |
|------|------|-------------|
| Owned Projects | projects | Projects where the User has an 'owner' role |
| Editable Projects | projects | Projects where the User has an 'owner' or 'collaborator' role or belongs to a group with either role |
| Viewable Projects | projects | Projects where the User has a role or belongs to a group with a role that allows for viewing the project |
| Owned Collections | collections | Collections where the User has an 'owner' role |
| Editable Collections | collections | Collections where the User has an 'owner' or 'collaborator' role or belongs to a group with either role |
| Viewable Collections | collections | Collections where the User has a role or belongs to a group with a role that allows for viewing the collection |
| Invited User Groups | user_groups | User Groups that have invited the User to join them |
| User Groups | user_groups | User Groups that the user is an active member of |
| Recents | subjects | Subjects the user has classified |
| Project Roles | roles | Roles a user has been assigned inside a project |
| Project Preferences | preferences | A user's settings for a project |
| Collection Roles | roles | Roles a user has been assigned inside a collection |
| Collection Preferences | preferences | A user's settings for a collection |

#### User Groups (/user_groups)

User Groups use a natural number as their `id`.

##### Attributes

| Attribute | Type | View Scope | Edit Scope | Description |
|-----------|------|------------|------------|-------------|
| name | String | Publicly Accessible / user_group for private groups | user_group | Permanent Name for the user group |
| display_name | String | Publicly Accessible / user_group for private groups | user_group | Free-form name for the user group |
| classification_count | Number | Publicly Accessible / user_group for private groups | N/A | Count of Classifications made while members were *classifying in the group* |
| private | Boolean | user_group | user_group | Flag for whether details about the group are accessible to non-members |
| created_at | Time | Publicly Accessible / user_group for private groups | user_group | Creation Timestamp |
| updated_at | Time  | Publicly Accessible / user_group for private groups | user_group | Last updated Timestamp |

##### Links

| Link | Type | Description |
|------|------|-------------|
| Owned Projects | projects | Projects where the User Group has an 'owner' role |
| Editable Projects | projects | Projects where the User Group has an 'owner' or 'collaborator' role or belongs to a group with either role |
| Viewable Projects | projects | Projects where the User Group has a role or belongs to a group with a role that allows for viewing the project |
| Owned Collections | collections | Collections where the User Group has an 'owner' role |
| Editable Collections | collections | Collections where the User Group has an 'owner' or 'collaborator' role or belongs to a group with either role |
| Viewable Collections | collections | Collections where the User Group has a role or belongs to a group with a role that allows for viewing the collection |
| Invited Users | user_groups | Users that have been invited to join the User Group |
| Users | user_groups | Users who are active members of the user group |
| Recents | subjects | Subjects the user group has classified |
| Project Roles | roles | Roles a user has been assigned inside a project |
| Collection Roles | roles | Roles a user has been assigned inside a collection |

#### Projects (/projects)

Projects use a natural number as their `id`.

##### Attributes
| Attribute | Type | View Scope | Edit Scope | Description |
|-----------|------|------------|------------|-------------|

##### Links
| Link | Type | Description |
|------|------|-------------|

#### Workflows (/workflows)

##### Attributes

##### Links

#### Subject Sets (/subject_sets)

##### Attributes

##### Links

#### Classifications (/classifications)

##### Attributes

##### Links

#### Subjects (/subjects)

##### Attributes

##### Links

#### Subject Queues (/subject_queues)

##### Attributes

##### Links

#### Collections (/collections)

##### Attributes

##### Links

#### Preferences (/preferences)

##### Attributes

##### Links

#### Roles (/roles)

##### Attributes

##### Links

#### Media (/media)

##### Attributes

##### Links

### Error Conditions

Errors will be returned in the JSON-API error format:

```json
{
    "errors": [
        {"detail": "An explanation of the error"}
    ]
}
```

The HTTP Status Code returned with the response will indicate the general reason the error occurred and whether or not it is recoverable by the the client. See [List of HTTP Client Errors](https://en.wikipedia.org/wiki/List_of_HTTP_status_codes#4xx_Client_Error) for a general overview.
