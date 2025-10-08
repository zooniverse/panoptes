# Media Resources
```json
{}
```

## Panoptes Resources to Media Resource Types

Within Panoptes, Media is a polymorphic resource that can be associated with different types of Panoptes resources.

Panoptes resources that can have an associated media resource are the following:

Panoptes Resource | Media Type
----------------- | ----------
Subjects <sup>*</sup> | <li>attached_images</li>
Users | <li>avatar</li><li>profile_header</li>
Organizations | <li>avatar</li><li>background</li><li>attached_images</li>
Projects  <sup>**</sup> | <li>avatar</li><li>background</li><li>attached_images</li>
Workflows  <sup>***</sup> | <li>attached_images</li>
Tutorials | <li>attached_images</li>
Field Guides | <li>attached_images</li>

<sup>* Subjects have a media type of subject_locations that are created and queried from the API in a different fashion and therefore do not fall into this pattern. </sup>
<sup>** Projects have a media type of subject_locations that do not fall into this pattern. </sup>


