# Translations

```json
{
    "translations": [
        {
            "id": "5576",
            "translated_id": 2456,
            "translated_type": "Project",
            "language": "en",
            "strings": {
                "title": "Wildcam Gorgonzola",
                "description": "Quite cheezy",
                "display_name": "Wildcam Gorgonzola",
                "introduction": "This project aims to find out dietary issues with animals. By cheese.",
                "researcher_quote": "",
                "workflow_description": ""
            },
            "string_versions": {
                "title": 33006,
                "description": 33006,
                "display_name": 33006,
                "introduction": 33006,
                "researcher_quote": 33006,
                "workflow_description": 33006
            },
            "href": "/translations/5576",
            "created_at": "2018-08-03T11:12:01.788Z",
            "updated_at": "2019-02-22T11:39:19.531Z",
            "links": {
                "published_version": null,
                "project": "2456"
            }
        },
        {
            "id": "5578",
            "translated_id": 2456,
            "translated_type": "Project",
            "language": "nl",
            "strings": {
                "title": "Wildcam Gorgonzola",
                "description": "Beetje kazig",
                "display_name": "Wildcam Gorgonzola",
                "introduction": "Dit project is op zoek naar dieetproblemen bij dieren. Met kaas.",
                "researcher_quote": "",
                "workflow_description": ""
            },
            "string_versions": {
                "title": 33006,
                "description": 33006,
                "display_name": 33006,
                "introduction": 33006,
                "researcher_quote": 33006,
                "workflow_description": 33006
            },
            "href": "/translations/5578",
            "created_at": "2018-08-03T11:15:31.353Z",
            "updated_at": "2019-02-22T11:39:19.599Z",
            "links": {
                "published_version": null,
                "project": "2456"
            }
        }
    ],
    "links": {
        "translations.published_version": {
            "href": "/translation_versions/{translations.published_version}",
            "type": "published_versions"
        },
        "translations.project": {
            "href": "/projects/{translations.project}",
            "type": "projects"
        },
        "translations.project_page": {
            "href": "/project_pages/{translations.project_page}",
            "type": "project_pages"
        },
        "translations.organization": {
            "href": "/organizations/{translations.organization}",
            "type": "organizations"
        },
        "translations.organization_page": {
            "href": "/organization_pages/{translations.organization_page}",
            "type": "organization_pages"
        },
        "translations.field_guide": {
            "href": "/field_guides/{translations.field_guide}",
            "type": "field_guides"
        },
        "translations.tutorial": {
            "href": "/tutorials/{translations.tutorial}",
            "type": "tutorials"
        },
        "translations.workflow": {
            "href": "/workflows/{translations.workflow}",
            "type": "workflows"
        }
    }
}

```

foo
## `strings` and `string_versions`

Whenever a collaborator changes translatable resources, Panoptes will copy over
those strings into the "primary" translation resource. This is the translation
resource that has its language set to the language of the translatable resource
(which it will typically inherit from the Project it belongs to, where
applicable). This primary translation resource is not editable via the API.

Upon copying data into the primary translation resource, Panoptes calculates a
version number for the translated resource. This version number will be
applicable to the strings that were changed. For instance, if a project
translation is initially this:

<div class="center-column"></div>
```json
{
  "strings": {"title": "Hello", "description": "This needs to be written"},
  "string_versions": {"title": 1, "description": 1}
}
```

And the project owner updates the description (via the [Projects](#projects)
API) but not the title, once Panoptes finishes updating the translation (which
happens asynchronously), the translation resource will look like this:

<div class="center-column"></div>
```json
{
  "strings": {"title": "Hello", "description": "This is now a real description"},
  "string_versions": {"title": 1, "description": 2}
}
```

Any translation editing UI should use this to provide the following features:

1. If for instance the string version of `description` on a secondary
   translation is set to `1`, while the primary translation has a version number
   of `2` or higher for this field, in the UI this field should be marked as
   outdated to let translators know that the project owner has updated the
   description and they need to recheck and update the translation for this
   field.
0. When a translator updates a field, the UI should send along the number for
   that field's string version of the primary translation, as shown to the
   translator. That is to say, if a translator then updates the `description`
   field of the secondary translation, when the editing UI calls the Panoptes
   API to save the updated translation, it should send along the value `2` for
   the `string_versions["description"]`. It should only update the values for
   strings that were actually touched, so as no to reset the outdatedness
   information for fields that weren't updated yet.


## List translations

## Get a single translation

## Create a translation

## Update a translation

## Publish the latest translation

```http
POST /api/translations/123/publish HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

This API will mark the latest version of this translation as the published version.
The published version is intended to be shown to volunteers on the website,
allowing a translator to make changes to a translation without interrupting the
normal classification flow. The project owner or collaborators can then review
and publish the changes to the translation as made by translators when they choose.

## Delete a translation

