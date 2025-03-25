# SubjectSetImports

## Feature Description

This resource is useful when a researcher has a large batch to add. The upload process goes as follows:

1. A researcher uploads image files into a web accessible location (e.g. s3 bucket, azure blob store, etc).
2. She also creates a manifest file (format described below) and uploads the manifest to a web accessible location.
   + The manifest file describes ['subjects'](https://help.zooniverse.org/getting-started/glossary/), which is the Zooniverse term for something that is to be classified.
   + A subject is made up of:
     + a unique external ID (used to track the subject from your organization)
     + one or more URLs that host media files e.g. image, video, audio.
     + metadata described as key-value pairs.
3. The researcher will then send the manifest payload to the Zooniverse API programatically
    + [Python example of how to send a manifest](https://github.com/zooniverse/panoptes-python-notebook/blob/master/examples/subject_set_import_vera_rubin.ipynb)
    + The repsonse to this manifest upload will be a `SubjectSetImport` API resource.
4. This calls the Zooniverse API which enqueues a background job on the Zooniverse servers.
    + In the background, the Zooniverse's systems process the downloaded manifest file, creating subjects in the specified subject set.
5. The `SubjectSetImport` resource API end point response can be polled for information on the progress and state of an import (see python example above or 'Retrieve a single import' below).

## Zooniverse API Feature Description

### Creating a new subject set import

```http
POST /api/subject_set_imports HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "subject_set_imports": {
       "source_url": "https://path.to/some/manifest.csv",
       "links": {
           "subject_set": "1"
       }
    }
}
```

Returns a SubjectSetImport resource with an ID. This resource can be polled in order to get the status of the import.

### Retrieve a single import

```http
GET /api/subject_set_imports/1 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

+ Parameters
  + id (required, integer) ... integer id of the resource to retrieve

## Manifest CSV format

```csv
external_id,location:1,location:2,metadata:size,metadata:cuteness
1,https://placekitten.com/200/300.jpg,https://placekitten.com/200/100.jpg,small,cute
2,https://placekitten.com/400/900.jpg,https://placekitten.com/500/100.jpg,large,cute
```

The manifest.csv file is contains one row per subject. See the example to the right. It is expected to have
the following columns:

+ `external_id` - Zooniverse uses this to deduplicate/upsert existing subjects, so that
  it's possible to reimport a manifest into a subject set.
+ `location:` - One or more columns that begin with `location:` (including the colon), followed by any
  sequence of characters. The values of cells in this column are URLs pointing
  to the uploaded image files in the S3 bucket. Multiple "location:" columns are
  supported (obviously the value after the colon needs to be unique, but is
  otherwise ignored). Supported mimetypes currently are:
  + image/jpeg
  + image/png
  + image/gif
  + image/svg+xml
  + audio/mpeg
  + audio/mp3
  + audio/mp4
  + audio/x-m4a
  + video/* (Depends on browser support)
  + text/plain

+ `metadata:` - Zero or more columns that begin with `metadata:` (including the colon), followed by
  the key of the specific metadata in this column.
