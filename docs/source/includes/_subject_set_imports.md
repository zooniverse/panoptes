# SubjectSetImports

## Feature Description

This resource is useful when a researcher has a large batch to add. The upload process goes as follows:

1. A researcher uploads image files into a web accessible location (e.g. s3 bucket, azure blob store, etc).
2. She also creates a manifest file (format described below) and uploads the manifest to a web accessible location.
   + The manifest file describes ['subjects'](https://help.zooniverse.org/getting-started/glossary/), which is the Zooniverse term for something that is to be classified.
   + A subject is made up of:
     + a unique UUID
     + one or more URLs that host media files e.g. image, video, audio.
     + metadata described as key-value pairs.
3. In the Zooniverse project builder, the researcher navigates to the subject set to which they would like to have the subjects added.
4. The researcher then clicks "Import manifest" and enters the URL to the manifest (from by step 2 above).
5. This calls the Zooniverse API which enqueues a background job on the Zooniverse servers.
    + In the background, the Zooniverse's systems process the downloaded manifest file, creating subjects in the specified subject set.

### Additional features beyond the MVP

When the science platform opens a new browser tab/window to send the researcher to the project builder, it can pass along the manifest URL for the small sample of <100 subjects as URL query parameters.

The Zooniverse project builder will then make the Import button more prominent and prefill the URL.

After approval, when the researcher needs to get a full set of data into their Zooniverse project, at the end the supertask can call the Zooniverse API to trigger the import rather than requesting the researcher to go back to the project builder and click a button.

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
uuid,location:1,location:2,metadata:size,metadata:cuteness
1,https://placekitten.com/200/300.jpg,https://placekitten.com/200/100.jpg,small,cute
2,https://placekitten.com/400/900.jpg,https://placekitten.com/500/100.jpg,large,cute
```

The manifest.csv file is contains one row per subject. See the example to the right. It is expected to have
the following columns:

+ `uuid` - Zooniverse uses this to deduplicate/upsert existing subjects, so that
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
