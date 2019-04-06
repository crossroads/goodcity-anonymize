# Goodcity Anonymize
Creates an anonymised SQL dump of the specified goodcity database

## Requirements

### Install dependencies

`bundle install`

### Set up hash secret

In order to have anonymize inventory numbers and have them match in both StockIt and GoodCity, we store a secret key in the environment

```bash
export ANONYMIZE_SECRET=my_secret_key
```

### Set up cloudinary api keys

The script connects to cloudinary to replace Goodcity images with test images
The reason for that is that sharing the ID between multiple environments might result in an accidental deletion of the image

The script will randomly select an image from the 'test' folder

```bash
export CLOUDINARY_CLOUD_NAME=cloud_name
export CLOUDINARY_API_KEY=api_key
export CLOUDINARY_API_SECRET=api_secret
```

## Running the script

`ruby anonymize_goodcity.rb --db-source=<a local goodcity database>`

This will output a `goodcity_anonymized.dump` file

The same thing can be done for StockIt by running the `anonymize_stockit.rb` script

## Importing the dump into a staging environment

`psql goodcity_staging_environment < goodcity_anonymized.dump > /dev/null`
