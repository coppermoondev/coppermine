# S3 Storage

The `s3` package provides a complete client for S3-compatible object storage services. It works with AWS S3, MinIO, Backblaze B2, DigitalOcean Spaces, Cloudflare R2, and any other S3-compatible provider.

## Installation

```bash
harbor install s3
```

## Quick Start

### Connect to a Bucket

```lua
local s3 = require("s3")

local bucket = s3.bucket({
    name = "my-bucket",
    region = "us-east-1",
    access_key = "AKIAIOSFODNN7EXAMPLE",
    secret_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
})
```

### Upload and Download

```lua
-- Upload text
bucket:put("hello.txt", "Hello, World!")

-- Upload with content type
bucket:put("page.html", "<h1>Hello</h1>", "text/html")

-- Download
local content = bucket:get("hello.txt")
print(content)  -- "Hello, World!"
```

### List and Delete

```lua
-- List all objects
local result = bucket:list()
for _, obj in ipairs(result.objects) do
    print(obj.key, obj.size)
end

-- List by prefix
local images = bucket:list("images/")

-- Delete an object
bucket:delete("hello.txt")
```

## Provider Configuration

### AWS S3

```lua
local bucket = s3.bucket({
    name = "my-bucket",
    region = "eu-west-1",
    access_key = "AKIA...",
    secret_key = "wJal...",
})
```

### MinIO

MinIO and other self-hosted S3-compatible services require path-style addressing and a custom endpoint:

```lua
local bucket = s3.bucket({
    name = "my-bucket",
    endpoint = "http://localhost:9000",
    access_key = "minioadmin",
    secret_key = "minioadmin",
    path_style = true,
})
```

### Backblaze B2

```lua
local bucket = s3.bucket({
    name = "my-b2-bucket",
    endpoint = "https://s3.us-west-004.backblazeb2.com",
    region = "us-west-004",
    access_key = "your-key-id",
    secret_key = "your-application-key",
})
```

### DigitalOcean Spaces

```lua
local bucket = s3.bucket({
    name = "my-space",
    endpoint = "https://nyc3.digitaloceanspaces.com",
    region = "nyc3",
    access_key = "your-spaces-key",
    secret_key = "your-spaces-secret",
})
```

### Cloudflare R2

```lua
local bucket = s3.bucket({
    name = "my-r2-bucket",
    endpoint = "https://ACCOUNT_ID.r2.cloudflarestorage.com",
    region = "auto",
    access_key = "your-r2-access-key",
    secret_key = "your-r2-secret-key",
    path_style = true,
})
```

## Object Operations

### Upload

```lua
-- Simple text upload
bucket:put("docs/readme.txt", "Hello!")

-- Specify content type
bucket:put("images/logo.png", png_data, "image/png")

-- Upload JSON
local data = json.encode({ version = "1.0", name = "app" })
bucket:put("config.json", data, "application/json")
```

### Upload with Custom Metadata

Attach custom key-value metadata to any object. Metadata keys are automatically prefixed with `x-amz-meta-`:

```lua
bucket:put_with_metadata("reports/q4.pdf", pdf_data, "application/pdf", {
    author = "finance-team",
    quarter = "Q4-2025",
    confidential = "true",
})
```

### Download

```lua
-- Download as string
local text = bucket:get("docs/readme.txt")

-- Download binary data
local data = bucket:get_bytes("images/logo.png")
```

### Partial Download (Byte Range)

Download only a portion of an object -- useful for resumable downloads or reading specific parts of large files:

```lua
-- First 1024 bytes
local header = bucket:get_range("large-file.bin", 0, 1023)

-- From offset 1000 to end of file
local rest = bucket:get_range("large-file.bin", 1000)
```

### Check Existence

```lua
if bucket:exists("config.json") then
    local config = json.decode(bucket:get("config.json"))
end
```

### Get Metadata

```lua
local meta = bucket:head("images/logo.png")
print(meta.content_type)    -- "image/png"
print(meta.content_length)  -- 12345
print(meta.last_modified)   -- "2025-01-15T10:30:00Z"
print(meta.etag)            -- "\"abc123...\""
print(meta.status)          -- 200
```

### Copy Objects

```lua
-- Copy within the same bucket
bucket:copy("original.txt", "backup/original.txt")
```

### Delete Objects

```lua
bucket:delete("temp/scratch.txt")
```

## Object Tagging

Tags are key-value pairs attached to objects for classification, lifecycle management, and cost allocation:

```lua
-- Set tags on an object
bucket:put_tags("reports/q4.pdf", {
    department = "finance",
    year = "2025",
    status = "final",
})

-- Read tags
local tags = bucket:get_tags("reports/q4.pdf")
print(tags.department)  -- "finance"
print(tags.year)        -- "2025"

-- Remove all tags
bucket:delete_tags("reports/q4.pdf")
```

## Multipart Upload

For large files (typically > 100 MB), use multipart uploads to upload in chunks. This enables resumable uploads and better performance:

```lua
-- 1. Start the upload
local upload_id = bucket:multipart_start("backups/database.sql.gz", "application/gzip")

-- 2. Upload parts (minimum 5 MB per part, except the last)
local parts = {}
local part_number = 1

-- Read and upload in chunks
while true do
    local chunk = read_next_chunk()  -- your chunking logic
    if not chunk then break end

    local part = bucket:multipart_upload(
        "backups/database.sql.gz",
        upload_id,
        part_number,
        chunk
    )
    table.insert(parts, part)
    part_number = part_number + 1
end

-- 3. Complete — assembles all parts into the final object
bucket:multipart_complete("backups/database.sql.gz", upload_id, parts)
```

If something goes wrong, abort the upload to clean up server-side parts:

```lua
bucket:multipart_abort("backups/database.sql.gz", upload_id)
```

## Listing Objects

### List All

```lua
local result = bucket:list()
for _, obj in ipairs(result.objects) do
    print(obj.key, obj.size, obj.last_modified)
end
```

### List by Prefix

```lua
-- List all files in images/
local result = bucket:list("images/")
for _, obj in ipairs(result.objects) do
    print(obj.key)
end
```

### Directory-Style Listing

Use a delimiter to group objects by "directory":

```lua
local result = bucket:list("", "/")

-- Top-level files
for _, obj in ipairs(result.objects) do
    print("File:", obj.key)
end

-- "Directories" (common prefixes)
for _, prefix in ipairs(result.prefixes) do
    print("Dir:", prefix)  -- e.g. "images/", "docs/"
end
```

## Presigned URLs

Generate temporary URLs that allow anyone to download, upload, or delete without credentials:

### Download URL

```lua
-- Default: 1 hour expiry
local url = bucket:presign_get("reports/monthly.pdf")
print(url)

-- Custom expiry (seconds)
local url = bucket:presign_get("reports/monthly.pdf", 300)  -- 5 minutes
```

### Upload URL

```lua
local url = bucket:presign_put("uploads/user-file.dat")
-- Share the URL — the holder can PUT directly to S3
```

### Delete URL

```lua
local url = bucket:presign_delete("temp/expired.dat", 600)
-- Share the URL — the holder can DELETE the object
```

## Bucket Management

### Create a Bucket

```lua
local bucket = s3.bucket({
    name = "new-bucket",
    region = "us-east-1",
    access_key = "...",
    secret_key = "...",
})

bucket:create_bucket()
```

### Check Bucket Existence

```lua
if bucket:bucket_exists() then
    print("Bucket exists!")
end
```

### Get Bucket Location

```lua
local region = bucket:location()
print(region)  -- "us-east-1"
```

### Get Bucket URL

```lua
print(bucket:url())  -- "https://my-bucket.s3.amazonaws.com"
```

### Delete a Bucket

```lua
-- Bucket must be empty first
bucket:delete_bucket()
```

### Get Bucket Name

```lua
print(bucket:name())  -- "my-bucket"
```

## Error Handling

All operations raise Lua errors on failure. Use `pcall` for graceful handling:

```lua
local ok, err = pcall(function()
    local data = bucket:get("nonexistent-key")
end)
if not ok then
    print("S3 error:", err)
end
```

Common error scenarios:

- **Invalid credentials** -- wrong access key or secret key
- **Bucket not found** -- the bucket doesn't exist
- **Access denied** -- insufficient permissions
- **Key not found** -- downloading a non-existent object
- **Network error** -- endpoint unreachable

## Complete Example

```lua
local s3 = require("s3")
local json = require("json")

-- Connect to MinIO
local bucket = s3.bucket({
    name = "my-app",
    endpoint = "http://localhost:9000",
    access_key = "minioadmin",
    secret_key = "minioadmin",
    path_style = true,
    timeout = 30,
})

-- Upload application config with metadata
local config = {
    version = "1.0.0",
    features = { "auth", "logging", "metrics" },
}
bucket:put("config.json", json.encode(config), "application/json")

-- Tag the config
bucket:put_tags("config.json", {
    env = "production",
    app = "my-app",
})

-- Upload user avatar
local avatar = fs.read_bytes("uploads/avatar.png")
bucket:put("avatars/user-123.png", avatar:toString(), "image/png")

-- List all avatars
local result = bucket:list("avatars/")
print("Avatars:", #result.objects)

-- Generate a temporary download link
local url = bucket:presign_get("avatars/user-123.png", 3600)
print("Download URL:", url)

-- Download partial content (first 100 bytes)
local preview = bucket:get_range("avatars/user-123.png", 0, 99)

-- Clean up
bucket:delete_tags("config.json")
bucket:delete("config.json")
```

## Limitations

The following S3 features are **not available** (not supported by the underlying library):

- **Object ACL/Permissions** -- no per-object access control lists
- **Bucket policies** -- no IAM-style bucket policies
- **Batch delete** -- no multi-object delete in one call
- **Object versioning** -- no version management
- **Server-side encryption** -- no SSE configuration
- **Object lock** -- no retention/legal hold

For these features, use the AWS CLI or provider-specific tools.

## Next Steps

- [API Reference](/docs/s3/api) -- Complete function reference
- [Buffer](/docs/buffer/overview) -- Binary data manipulation
- [File System](/docs/fs/overview) -- Local file operations
