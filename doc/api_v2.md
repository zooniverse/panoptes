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

All requests with a body MUST include a `Content-Type` header with either the value `application/vnd.api+json` or `application/json`. The value provided will not affect how the request is processed.

## Authorization

Zooniverse uses [OAuth2]() to allow individuals to authorize applications to access the Zooniverse Classification API on their behalf.

The Zooniverse provides three levels of access to the Classification API:

+ First-Party - Skips authorization pages, allows all scopes, and the use of the Resource Owner Credential Grant.
+ Secure - An application that can keep its secret, allows use of all grants, except the Resource Owner Credential Grant.
+ Insecure - An application that cannot keep its secret (ie a Browser or Mobile Application). Can only use the Implicit Grant. Cannot use the user scope.

Applications can be registered at [https://zooniverse.org/oauth/applications](https://zooniverse.org/oauth/applications).

### Authorization Code

Grant type used by Secure applications. It is a multi-step process:

1. Direct the user to a `https://zooniverse.org/oauth/authorization?app_id=&redirect_uri=&scope=&secret=&request_type=code`
1. The user will be asked to login, then authorize the application.
1. The Zooniverse Classification API will redirect to `{redirect_uri}?code=`
1. The application sends a `POST` request to `https://zooniverse.org/oauth/tokens` with a json body:
```json
{
    "grant_type": "access_code",
    "client_id": "app id",
    "client_secret": "app secret",
    "scopes": "user,project"
}

```
1. The Zooniverse Classificaiton API will reply with a JSON document:
```json
{
    "token_type": "bearer",
    "access_token": "askdjfqwer234909cvjzfg8u;kjfnasd;kfkjasdf",
    "scopes": "user,project"
}
```

More info in the [official spec](https://tools.ietf.org/html/rfc6749#section-4.1).

#### Implementations

+ [Omniauth Zooniverse](https://github.com/zooniverse/omniauth-zooniverse)

### Client-Credentials

This grant type can be used by secure applications to exchange their credentials directly for a token belonging to the application owner.

An application can make a `POST` request to `https://zooniverse.org/oauth/tokens` with a JSON body:

```json
{
    "grant_type": "authorization_code",
    "client_id": "app id",
    "client_secret": "app_secret",
    "scopes": "user,project"
}
```

Substituting the app's id and secret, as well as the desired scopes.

The response will also be a JSON document:

```json
{
    "token_type": "bearer",
    "access_token": "askdjfqwer234909cvjzfg8u;kjfnasd;kfkjasdf",
    "scopes": "user,project"
}
```

More info in the [official spec](https://tools.ietf.org/html/rfc6749#section-4.4).

### Resource Owner Credentials

This grant type can only be used by First Party applications to exchange user credentials directly for a token. Non-approved applications MUST NOT ask users for their passwords. 

An application can make a `POST` request to `https://zooniverse.org/oauth/tokens` with a JSON body:

```json
{
    "grant_type": "password",
    "client_id": "app id",
    "client_secret": "app_secret",
    "username": "login or email",
    "password": "user password",
    "scopes": "user,project"
}
```

Substituting the app's id and secret, the username and password, and the desired scopes.

The response will also be a JSON document:

```json
{
    "token_type": "bearer",
    "access_token": "askdjfqwer234909cvjzfg8u;kjfnasd;kfkjasdf",
    "scopes": "user,project"
}
```

More info in the [official spec](https://tools.ietf.org/html/rfc6749#section-4.3).

### Implicit Grant

This grant type should be used by Insecure applications since it does not require an application to be able to store its application secret. It is also a multi-step process:

1. Direct the user to a `https://zooniverse.org/oauth/authorization?app_id=&redirect_uri=&scope=&secret=&request_type=token`
1. The user will be asked to login, then authorize the application.
1. The Zooniverse Classification API will redirect to `{redirect_uri}?access_token=&scope=&token_type=bearer`

More info in the [official spec](https://tools.ietf.org/html/rfc6749#section-4.2).

#### Implementations

+ [API Access with jQuery](https://gist.github.com/edpaget/5518e717a021cbc09be9)

## Scopes

The Zooniverse Classification API uses OAuth scopes to allow users to restrict the permissions they give to third-party applications accessing the API on their behalf. The available scopes are:

+ `user` - View private details about a user and edit their account - First Party Only
+ `user_group` - View private details about a group and edit the group - First Party Only
+ `project.view`- View private projects and their related workflows and subjects - Any App
+ `project.edit` - Edit details about projects and workflows - First Party/Secure Only
+ `translation` - Can create and edit translations of projects - Any App
+ `collection.view`- view private collections - Any App
+ `collection.edit`- Edit collections, and and remove subjects from them - Any App
+ `subject` - Create new subjects on a behalf of a user and add/remove them from collections - First Party/Secure Only
+ `media` - Upload media on behalf of a user - Any App

In the API docs below `public` is used to denote that 'public' resources (projects, etc) can be accessed without needing any particular scope on the token.

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
    ],
    "meta": {
        "filterable": ["login"],
        "sortable": ["login"]
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

Clients for JSON-API written in a variety of languages can be found [here](http://jsonapi.org/implementations/).

#### Examples

+ [Using the Zooniverse Classification API with Python](python_client.md)
+ [Using the Zooniverse Classification API with Javascript](javascript_client.md)
+ [Using the Zooniverse Classification API with Ruby](ruby_client.md)

### Resources

#### Users (/users)

Users use a natural number as an `id`.

A User record can only be modified by a token belonging to the user themself. 

##### Attributes

| Attribute | Type | View Scope | Edit Scope | Description |
|-----------|------|------------|------------|-------------|
| login     | String | public | user | The user's permanent name |
| display_name | String | public | user | A freeform name for the user |
| credited_name | String | user | user | The name the user will be credited as in publications |
| email | String | user | user | User email address |
| global_email_communication | Boolean | user | user | Flag to indicate if a user wants to receive Zooniverse emails |
| project_email_communication | Boolean | user | user | Flag to indicate if a user wants to be automatically subscribed to emails from projects they classify on |
| beta_email_communication | Boolean | user | user | Flag to indicate if a user wants to be notified about beta tests |
| max_subjects | Number |subject.create | N/A | Total number of subjects a user can upload |
| uploaded_subject_count | Number | subject.create | N/A | Total number of a subjects a user has uploaded |
| admin | Boolean | user | N/A | Whether the use can take administrative actions |
| private_profile | Boolean | publically Accessible | user | Flag to hide profile information like classification counts |
| created_at | Time | public | user | Creation Timestamp |
| updated_at | Time  | public | user | Last updated Timestamp |

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
| name | String | public / user_group | user_group | Permanent Name for the user group |
| display_name | String | public / user_group | user_group | Free-form name for the user group |
| classification_count | Number | public / user_group | N/A | Count of Classifications made while members were *classifying in the group* |
| private | Boolean | public / user_group | user_group | Flag for whether details about the group are accessible to non-members |
| created_at | Time | public / user_group | user_group | Creation Timestamp |
| updated_at | Time  | public / user_group | user_group | Last updated Timestamp |

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
| display_name | String | public / project.view  | project.edit / translation | Freeform-name for a project. Project slug is generated from it |
| title | String | public / project.view | project.edit / translation | Translated version of a project's display_name |
| description | String | public / project.view | project.edit / translation | Brief explanation of a project. Translatable. |
| introduction | String | public / project.view | project.edit / translation | Longer summary of a project's goals. Rendered as Markdown. Translatable. |
| workflow_description | String | public / project.view | project.edit / translation | Explanation of a project's workflows. Rendered as Markdown. Translatable. |
| urls | Array[Object<url: String, label: String>] | public / project.view | project.edit / translation | List of URLs with labels that a project page should link to. Labels are translatable |
| available_languages | Array[String] | public / project.view | N/A | List of locale codes a project is available in |
| primary_language | String | public / project.view | project.edit | Language a project was originally created in |
| tags | Array[String] | public / project.view | project.edit | List of categories a project belongs to |
| classifications_count | Number | public / project.view | N/A | Number of classifications completed for this project |
| classifiers_count | Number | public / project.view | N/A | Number of logged-in users who have classified on the project |
| subjects_count | Number | public / project.view | N/A | Count of the total number of subjects associated with this project |
| retired_subjects_count | Number | public / project.view | N/A | Count of subjects that have been retired |
| live | Boolean | public / project.view | project.edit | Flag that controls whether classifications will count for retirement, and also locks editing of workflows |
| private | Boolean | public / project | project.view | Flag that the project is only accessible to users with the correct roles |
| launch_approved | Boolean | public / project.view | N/A | Flag that the project has been approved to launch |
| launch_requested | Boolean | public / project.view | project.edit | Flag that requests the project be reviewed for launch |
| beta_approved | Boolean | public / project.view | N/A | Flag that the project has been approved for beta testing |
| beta_requested | Boolean | public / project.view | project.edit | Flag that requests the project be reviewed for beta testing |
| redirect | String | public / project.view | N/A | URL to redirct from the zooniverse.org projects page |
| configuration | Object<String,Any> | public / project.view | project.edit | Free-form Object for project specific configuration options |
| slug | String | public / project.view | N/A | URL slugs for accessing the project |
| created_at | Time | public / project.view | project.edit | Creation Timestamp |
| updated_at | Time  | public / project.view | project.edit | Last updated Timestamp |

##### Links

| Link | Type | Description |
|------|------|-------------|
| Active Workflows | workflows | Workflows that the project is allow classifications on |
| Inactive Workflows | workflows | Workflows marked as inactive or that have finished classifying all associated subjects |
| Subject Sets | subject_sets | All subject sets associated with the project |
| Owner | user/user_group | The Project's Owner |
| Editors | user/user_group | Users and user groups with the 'collaborator' or 'owner' roles |
| Translators | user/user_group | Users and user groups with the 'collaborator', 'owner', or 'translator' roles |
| Viewers | user/user_group | Users and user groups with any role within the project |
| Roles | roles | All roles associated with the project |
| Pages | pages | Markdown pages associated with the project |
| Avatar | media | Image to represent the project |
| Background | media | Background image for the project's page |
| Attached Images | media | Uploaded images that can be used on the project's page |
| Classifications Export | media | CSV export of all the classifications for a project |
| Subjects Export | media | CSV export of all the subjects associated with a project |
| Aggregations Export | media | Tarball of aggregated classification data |

#### Workflows (/workflows)

Projects use a natural number as their `id`.

##### Tasks

The `tasks` attribute of a workflow has is a JSON Object that describes the classification task for a worklow.

Each task has a type string of "single" or "multiple" choice, or "drawing". (More task types to come, e.g. Serengeti-style filter and Sunspotter's comparison.)

"multiple" and "drawing" tasks have a next string, linking to the next task in the workflow. If this string is empty, the workflow ends. In "single" tasks, each answer has a next string, allowing branching based on the user's decisions.

"single" and "multiple" tasks have a question string, which the user must answer. Answers to the question are in an answers array. Each answer has a label string displayed to the user.

"single" and "multiple" tasks may define a boolean required, which when true will force the user to provide an answer before moving on to the next task.

"drawing" tasks have an instruction string telling the user how to complete the task.

"drawing" tasks have a tools array.

Each tool has a label shown to the user.

Each tool has a string type. Options include:

    point

    ellipse

    circle

    line

    rectangle

    polygon

Each tool has a string color, which is applied to the marks made by the tool. Any format valid as CSS can be used.

##### Selection Strategy

Three parameters: `grouped`, `prioritized`, and `pairwise `configure how the Zooniverse Classification API chooses subjects for classification. They are all false by default, which will give a random selection of subjects from all subject_sets that are part of a workflow. `grouped` enables selecting subjects from a specific subject set. `prioritized` ensures that users will see subjects in a predetermined order. `pairwise` will select two subjects at a time for classification.

##### Attributes
| Attribute | Type | View Scope | Edit Scope | Description |
|-----------|------|------------|------------|-------------|
| display_name | String | public / project | project.edit | Name of the Workflow |
| tasks | Object | public / project | project.edit | Description of the classification task for this workflow | 
| prioritized | Boolean | public / project | project.edit | Subject Selection Flag |
| grouped | Boolean | public / project | project.edit |Subject Selection Flag |
| pairwise | Boolean | public / project | project.edit | Subject Selection Flag |
| active | Boolean | public / project | project.edit | Flag indicating whether the workflow is available to classify on |
| retirement | Object | public / project | project.edit | Object describing conditions that will cause a subject to be retired |
| version | String | public / project | project.edit | Current version number of the workflow. | 
| classifications_count | Number | public / project | project.edit | Total classifications completed for this workflow |
| subjects_count | Number | public / project | project.edit | Total number of subjects associated with the workflow |
| retired_set_member_subjects_count | Number | public / project | project.edit | count of retired subjects for this workflow |
| primary_language | String | public / project | project.edit | Language the workflow was originally created in |
| content_language | String | public / project | project.edit | Current language of the workflow |
| created_at | Time | public / project | project.edit | Timestamp of creation |
| updated_at | Time | public / project | project.edit | Timestamp of last update |

##### Links

| Link | Type | Description |
|------|------|-------------|
| Project | projects | Parent project of the workflow

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
