# Goodcity Anonymize
Creates an anonymised SQL dump of the specified goodcity database

## Requirements

### Install dependencies

`bundle install`

### Set up cloudinary api keys

The script connects to cloudinary to replace Goodcity images with test images
The reason for that is that sharing the ID between multiple environments might result in an accidental deletion of the image

```bash
export CLOUDINARY_CLOUD_NAME=cloud_name
export CLOUDINARY_API_KEY=api_key
export CLOUDINARY_API_SECRET=api_secret
```

## Running the script

`ruby anonymize.rb --db-source=<a local goodcity database>`

This will output a `goodcity_anonymized.dump` file

## Importing the dump into a staging environment

`psql goodcity_staging_environment < goodcity_anonymized.dump > /dev/null`
