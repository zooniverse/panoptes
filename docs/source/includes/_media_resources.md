# Media Resources
```json
{}
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
path_opts | {} |
private | boolean |
external_link | boolean |
metadata | hash |
created_at | datetime | read-only
updated_at | datetime | read-only

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

Panoptes Resource | Media Types
----------------- | ----------
Subjects <sup>*</sup> | <li>attached_images</li>
Users | <li>avatar</li><li>profile_header</li>
Organizations | <li>avatar</li><li>background</li><li>attached_images</li>
Projects  <sup>**</sup> | <li>avatar</li><li>background</li><li>attached_images</li>
Workflows  <sup>***</sup> | <li>attached_images</li>
Tutorials | <li>attached_images</li>
Field Guides | <li>attached_images</li>

<sup>* Subjects have a media type of `subject_locations` that are created and queried from the API in a different fashion to a typical media resource pattern. </sup> <br>

<sup>** Projects have a media type of   `classifications_export`, `subjects_export`, `workflows_export`, `workflows_contents_export` that do not fall into typical media resource pattern. </sup> <br>

<sup>*** Workflows also have a media type of `classifications_export` that do not fall into typical media resource pattern. </sup> <br>





