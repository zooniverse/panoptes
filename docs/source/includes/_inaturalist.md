# iNaturalist Importing

This endpoint interacts with the Panoptes' iNaturalist functionality. Currently, this includes a single route that allows the importing of iNaturalist Observations as Zooniverse Subjects.

## Import iNaturalist Observations

```http
POST /api/inaturalist/import HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
  "taxon_id": "36202",
  "subject_set_id": "134916",
  "updated_since": "2026-03-15"
}
```

Begins an import of iNaturalist Observations as Zooniverse Subjects.
Response is an empty 200 if Panoptes begins the import successfully.
Requires owner or collaborator access to the subject set's linked project.

When the import job is finished, the user that made the request will get an email reporting the job's status how many subjects were imported, and if there were any failures.

### Parameters

+ taxon_id (required, integer) ... the iNat taxon ID of a particular species
+ subject_set_id (required, integer) ... the Zoo subject set id subjects should be imported into. Updated observations will upsert their respective subjects.
+ updated_since (optional, string) ... a date range limiter on the iNat Observations query. **Warning**: defaults to nil and will import ALL Observations by default. This will likely be **a lot** (hundreds of thousands) and take a long time. Test with a recent date before importing a full taxon.