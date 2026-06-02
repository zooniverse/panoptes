# Translations

A Translation stores translated strings for another Panoptes resource.

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
translated_id | integer | read-only id of the translated resource, for example the project id returned in `links.project`
translated_type | string | read-only type of the translated resource, for example `Project`
language | string |
strings | object |
string_versions | object |
created_at | datetime | read-only
updated_at | datetime | read-only

Translations can include a link to the translated resource and, where
applicable, a `published_version`.

## List Translations

```http
GET /api/translations?translated_type=project&translated_id=456&language=en HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Example request:

Example response:

```json
{
  "translations": [
    {
      "id": "1234",
      "translated_id": 456,
      "translated_type": "Project",
      "language": "en",
      "strings": {
        "title": "Example Project",
        "url_labels": null,
        "description": "An example translated description.",
        "display_name": "Example Project",
        "introduction": "An example translated introduction.",
        "researcher_quote": null,
        "workflow_description": null
      },
      "string_versions": {
        "title": "example title version",
        "url_labels": "example url_labels version",
        "description": "example description version",
        "display_name": "example display_name version",
        "introduction": "example introduction version",
        "researcher_quote": "example researcher_quote version",
        "workflow_description": "example workflow_description version"
      },
      "href": "/translations/1234",
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:00:00.000Z",
      "links": {
        "published_version": null,
        "project": "456"
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
  },
  "meta": {
    "translations": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/translations?language=en&translated_id=456",
      "previous_href": null,
      "next_href": null,
      "last_href": "/translations?language=en&translated_id=456"
    }
  }
}
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve, default is 1
  + page_size (optional, integer) ... number of items to include on a page, default is 20
  + sort (optional, string) ... field to sort by
  + language (optional, string) ... filter translations by language
  + translated_type (optional, string) ... filter by the translated resource type, for example `project`
  + translated_id (optional, integer) ... filter by the translated resource id, for example the project id
  + include (optional, string) ... comma separated list of linked resources to include in the response

## Retrieve a single Translation

```http
GET /api/translations/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the translation to retrieve
  + include (optional, string) ... comma separated list of linked resources to include in the response

## Create a Translation

```http
POST /api/translations?translated_type=project&translated_id=456 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "translations": {
    "language": "xx",
    "strings": {},
    "string_versions": {}
  }
}
```
Translations may only be created for non-primary languages.

Example request:



Example response:

```json
{
  "translations": [
    {
      "id": "1235",
      "translated_id": 456,
      "translated_type": "Project",
      "language": "xx",
      "strings": {},
      "string_versions": {},
      "href": "/translations/1235",
      "created_at": "2026-01-01T12:10:00.000Z",
      "updated_at": "2026-01-01T12:10:00.000Z",
      "links": {
        "published_version": null,
        "project": "456"
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
  },
  "meta": {
    "translations": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/translations",
      "previous_href": null,
      "next_href": null,
      "last_href": "/translations"
    }
  }
}
```

## Edit a single Translation

```http
PUT /api/translations/1234?translated_type=project&translated_id=456 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "translations": {
    "strings": {
      "title": "Example Translated Title",
      "url_labels": "",
      "description": "",
      "display_name": "Example Translated Display Name",
      "introduction": "",
      "researcher_quote": "",
      "workflow_description": ""
    },
    "string_versions": {
      "title": "example title version",
      "display_name": "example display_name version"
    }
  }
}
```

Translations may only be updated for non-primary languages.

Example request:



Example response:

```json
{
  "translations": [
    {
      "id": "1234",
      "translated_id": 456,
      "translated_type": "Project",
      "language": "xx",
      "strings": {
        "title": "Example Translated Title",
        "url_labels": "",
        "description": "",
        "display_name": "Example Translated Display Name",
        "introduction": "",
        "researcher_quote": "",
        "workflow_description": ""
      },
      "string_versions": {
        "title": "example title version",
        "display_name": "example display_name version"
      },
      "href": "/translations/1234",
      "created_at": "2026-01-01T12:00:00.000Z",
      "updated_at": "2026-01-01T12:05:00.000Z",
      "links": {
        "published_version": null,
        "project": "456"
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
  },
  "meta": {
    "translations": {
      "page": 1,
      "page_size": 20,
      "count": 1,
      "include": [],
      "page_count": 1,
      "previous_page": null,
      "next_page": null,
      "first_href": "/translations",
      "previous_href": null,
      "next_href": null,
      "last_href": "/translations"
    }
  }
}
```
