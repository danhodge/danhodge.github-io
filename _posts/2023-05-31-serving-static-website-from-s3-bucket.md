---
layout: post
title:  "Serving a Static Website from an S3 Bucket"
date: 2023-05-31 22:46:23 -0400 
categories: tools
tags: aws s3
---

I often use S3 to serve static files.
The only thing that you need to do differently to make a file publically available on S3 is set its `acl` to `public-read` when you store it on S3.
The file doesn't need to be in a special publically accessible bucket or grouped with other publically accessible files.
Here's some code that demonstrates this using the AWS SDK for Ruby (v3).

```ruby
require 'aws-sdk-s3'
client = Aws::S3::Client.new

client.put_object(
  acl: "public-read",
  bucket: bucket_name,
  key: key,
  body: data
)
```

I recently setup an S3 bucket to serve a static website (a Create React App) and discovered that the process was much more complicated.
There are three additional steps that you have to take after creating your bucket to set it up to serve a static website.

* You need to add a website subresource to tell S3 that the bucket is being used for hosting a static site and provide information about the index and error documents.
* You also need to tell S3 that the bucket is open to the public.
This is not enough to make the contents of the bucket publically accessible, however.
* You also need to add a policy on the bucket to allow everyone to read all of the files in it.

Finally, you'll need to make sure that you set the `Content-Type` of all of the files that you upload to the bucket correctly.
When you upload the files directly via the AWS management console, it seems to do a good job either detecting the `Content-Type` of the uploaded files or setting it based on the file extension.
When you upload the files via the S3 API, it doesn't seem to do any `Content-Type` detection or inference, so you'll need to do that yourself.

Here's some code that demonstrates all of these steps using the AWS SDK for Ruby (v3).

```ruby
require 'aws-sdk-s3'

client = Aws::S3::Client.new

#  adds the website subresource & sets error & index document to index.html
client.put_bucket_website(
  bucket: bucket_name,
  website_configuration: {
    error_document: {
      key: "index.html", 
    },
    index_document: {
      suffix: "index.html", 
    } 
  }
)
# makes the S3 bucket publically accessible
client.put_public_access_block(
  bucket: bucket_name,
  public_access_block_configuration: {
    block_public_acls: false,
    block_public_policy: false,
    ignore_public_acls: false,
    restrict_public_buckets: false
  }
)
# defines a policy that allows everyone to read the contents of this bucket
client.put_bucket_policy(
  bucket: bucket_name,
  policy: {
    "Version" => "2012-10-17",
    "Statement" => [
      {
        "Sid" => "PublicReadGetObject",
        "Effect" => "Allow",
        "Principal" => "*",
        "Action" => "s3:GetObject",
        "Resource": "arn:aws:s3:::#{bucket_name}/*"
      }
    ]
  }.to_json
)
```

Here's a naive approach for uploading files to the bucket with the proper `Content-Type` setting.

```ruby
require 'aws-sdk-s3'

client = Aws::S3::Client.new

files.each do |key, path|
  args = {
    bucket: bucket_name, 
    key: key, 
    body: File.read(path)
  }
  args[:content_type] = "text/html" if path.end_with?(".html")
  args[:content_type] = "application/json" if path.end_with?(".json")
  args[:content_type] = "text/css" if path.end_with?(".css")
  args[:content_type] = "application/javascript" if path.end_with?(".js")
  args[:content_type] = "text/plain" if path.end_with?(".txt")
  args[:content_type] = "image/png" if path.end_with?(".png")
  args[:content_type] = "image/x-icon" if path.end_with?(".ico")
      
  client.put_object(**args)
end
```