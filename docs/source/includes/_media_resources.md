# Media Resources
```json
{
    "media": [
        {
            "id": "177939",
            "href": "/projects/1936/attached_images/177939",
            "src": "https://panoptes-uploads-staging.zooniverse.org/project_attached_image/goofy_test.png",
            "content_type": "image/png",
            "media_type": "project_attached_image",
            "external_link": false,
            "created_at": "2021-10-07T17:57:37.886Z",
            "metadata": {
                "size": 11352,
                "filename": "goofy_test.png"
            },
            "updated_at": "2021-10-07T17:57:37.886Z",
            "links": {
                "linked": {
                    "href": "/projects/1936",
                    "id": "1936",
                    "type": "projects"
                }
            }
        }
    ],
    "meta": {
        "media": {
            "page": 1,
            "page_size": 20,
            "count": 1,
            "include": [],
            "page_count": 1,
            "previous_page": null,
            "next_page": null,
            "first_href": "/media?id=177939",
            "previous_href": null,
            "next_href": null,
            "last_href": "/media?id=177939"
        }
    }
}
```

A media record is a polymorphic resource that can be associated with different types of Panoptes resources.   A media record has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
type | string | media type of the media record (See the <b>Media Types</b> column in the table within the [<b>Panoptes Resources to Media Resource Types</b>](#panoptes-resources-to-media-resource-types) )
linked_id | string | id of the Panoptes resource that the media record is associated to
linked_type | string | type of Panoptes resource the media record is associated to  (See the <b>Panoptes Resource</b> column entries in the table within the [<b>Panoptes Resources to Media Resource Types</b>](#panoptes-resources-to-media-resource-types) )
content_type | string | mime type of the media record (See [<b>Supported Mime Types of Panoptes Media Records</b>](#supported-mime-types-of-panoptes-media-records))
src | string | path link to the media record
path_opts | hash |
private | boolean |
external_link | boolean |
metadata | hash |
created_at | datetime | read-only
updated_at | datetime | read-only

*id*, *created_at*, and *updated_at* are assigned by
the API.

 ## Supported Mime Types of Panoptes Media Records

Supported mimetypes currently are:

+ image/jpeg
+ image/png
+ image/gif
+ image/svg+xml
+ audio/mpeg
+ audio/mp3
+ audio/mp4
+ audio/x-m4a
+ text/plain
+ text/csv
+ video/mp4
+ application/pdf
+ application/json



## Panoptes Resources to Media Resource Types

Within Panoptes, Media is a polymorphic resource that can be associated with different types of Panoptes resources.

Panoptes resources that can have an associated media resource are the following:

Panoptes Resource | Media Types <i>(Panoptes Resource to Media Type Relation)</i>
----------------- | ----------
Subjects <sup>*</sup> | <li>attached_images <i>(one to many)</i></li>
Users | <li>avatar <i>(one to one)</i></li><li>profile_header <i>(one to one) </i></li>
Organizations | <li>avatar <i>(one to one) </i></li><li>background <i>(one to one)</i></li><li>attached_images <i>(one to many)</i></li>
Projects  <sup>**</sup> | <li>avatar <i>(one to one)</i></li><li>background <i>(one to one)</i></li><li>attached_images <i>(one to many)</i></li>
Workflows  <sup>***</sup> | <li>attached_images <i>(one to many)</i></li>
Tutorials | <li>attached_images <i>(one to many)</i></li>
Field Guides | <li>attached_images <i>(one to many) </i></li>

<sup>* Subjects have a media type of `subject_locations` that are created and queried from the API in a different fashion to a typical media resource pattern. </sup> <br>

<sup>** Projects have a media type of   `classifications_export`, `subjects_export`, `workflows_export`, `workflows_contents_export` that do not fall into typical media resource pattern. </sup> <br>

<sup>*** Workflows also have a media type of `classifications_export` that do not fall into typical media resource pattern. </sup> <br>


## List Media Records

For the following examples, we will be using Subject as the example Panoptes Resource and `attached_images` as the example media type, but note that the same pattern follows for any of the listed Panoptes Resources and listed Media Types list on the [<b>Panoptes Resources to Media Resource Types table</b>](#panoptes-resources-to-media-resource-types).

```http
GET /api/:panoptes_resource/:panoptes_resource_id/:media_type HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

```http
# (Eg. where panoptes_resource = subject,
# panoptes_resource_id = 123,
# media_type = attached_images)

GET /api/subjects/123/attached_images HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20

