# API Reference

Complete API reference for the CopperMoon `s3` package.

## Module

### `s3.bucket(config)`

Create a new S3 bucket client.

| Parameter | Type | Description |
|-----------|------|-------------|
| `config` | table | Bucket configuration |

**Config fields:**

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | Yes | -- | Bucket name |
| `region` | string | No | `"us-east-1"` | AWS region identifier |
| `endpoint` | string | No | -- | Custom endpoint URL (for MinIO, B2, R2, etc.) |
| `access_key` | string | Yes | -- | Access key ID |
| `secret_key` | string | Yes | -- | Secret access key |
| `path_style` | boolean | No | `false` | Use path-style addressing (required for MinIO) |
| `timeout` | number | No | -- | Request timeout in seconds |

**Returns:** Bucket client instance

```lua
-- AWS S3
local bucket = s3.bucket({
    name = "my-bucket",
    region = "eu-west-1",
    access_key = "AKIA...",
    secret_key = "wJal...",
})

-- MinIO (path-style + custom endpoint)
local bucket = s3.bucket({
    name = "data",
    endpoint = "http://localhost:9000",
    access_key = "minioadmin",
    secret_key = "minioadmin",
    path_style = true,
    timeout = 30,
})
```

### `s3.version`

Module version string.

```lua
print(s3.version)  -- "0.1.0"
```

## Object Operations

### `bucket:put(key, data, content_type?)`

Upload data to the bucket.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key (path in the bucket) |
| `data` | string | Data to upload |
| `content_type` | string | MIME type (default: `"application/octet-stream"`) |

**Returns:** nothing

**Raises:** error on upload failure

```lua
bucket:put("file.txt", "Hello!")
bucket:put("page.html", "<h1>Hi</h1>", "text/html")
bucket:put("data.json", json.encode(data), "application/json")
```

### `bucket:put_with_metadata(key, data, content_type, metadata)`

Upload data with custom metadata headers. Metadata keys are automatically prefixed with `x-amz-meta-`.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `data` | string | Data to upload |
| `content_type` | string | MIME type (default: `"application/octet-stream"`) |
| `metadata` | table | Key-value pairs of custom metadata |

**Returns:** nothing

**Raises:** error on upload failure

```lua
bucket:put_with_metadata("report.pdf", pdf_data, "application/pdf", {
    author = "admin",
    version = "2",
})
-- Stored as x-amz-meta-author: admin, x-amz-meta-version: 2
```

### `bucket:get(key)`

Download an object as a string.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |

**Returns:** string (object contents)

**Raises:** error if object not found

```lua
local content = bucket:get("file.txt")
print(content)
```

### `bucket:get_bytes(key)`

Download an object as binary data. Alias for `get`, returns a binary-safe string.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |

**Returns:** string (binary-safe)

**Raises:** error if object not found

```lua
local data = bucket:get_bytes("image.png")
fs.write_bytes("local-image.png", data)
```

### `bucket:get_range(key, start, end_byte?)`

Download a byte range of an object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `start` | number | Start byte offset (0-based) |
| `end_byte` | number | End byte offset (inclusive). Omit for end of file |

**Returns:** string (binary-safe partial data)

**Raises:** error if object not found or range invalid

```lua
-- First 1 KB
local header = bucket:get_range("large.bin", 0, 1023)

-- From byte 5000 to end
local tail = bucket:get_range("large.bin", 5000)
```

### `bucket:delete(key)`

Delete an object from the bucket.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |

**Returns:** nothing

**Raises:** error on failure

```lua
bucket:delete("old-file.txt")
```

### `bucket:exists(key)`

Check if an object exists in the bucket.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |

**Returns:** boolean

```lua
if bucket:exists("config.json") then
    local config = json.decode(bucket:get("config.json"))
end
```

### `bucket:head(key)`

Get metadata for an object without downloading it.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |

**Returns:** table with metadata fields

| Field | Type | Description |
|-------|------|-------------|
| `status` | number | HTTP status code |
| `content_type` | string | MIME type (if available) |
| `content_length` | number | Size in bytes (if available) |
| `last_modified` | string | Last modification timestamp (if available) |
| `etag` | string | Entity tag (if available) |

**Raises:** error if object not found

```lua
local meta = bucket:head("document.pdf")
print(meta.status)          -- 200
print(meta.content_type)    -- "application/pdf"
print(meta.content_length)  -- 102400
print(meta.etag)            -- "\"abc123def456\""
```

### `bucket:list(prefix?, delimiter?)`

List objects in the bucket.

| Parameter | Type | Description |
|-----------|------|-------------|
| `prefix` | string | Filter by key prefix (default: `""`) |
| `delimiter` | string | Group by delimiter for directory-like listing (default: `""`) |

**Returns:** table with two arrays

| Field | Type | Description |
|-------|------|-------------|
| `objects` | array | List of object entries |
| `prefixes` | array | List of common prefix strings |

**Object entry fields:**

| Field | Type | Description |
|-------|------|-------------|
| `key` | string | Object key |
| `size` | number | Object size in bytes |
| `last_modified` | string | Last modification timestamp |
| `etag` | string | Entity tag (if available) |
| `storage_class` | string | Storage class (if available) |

```lua
-- List all objects
local result = bucket:list()

-- List by prefix
local result = bucket:list("logs/2025/")

-- Directory-style listing
local result = bucket:list("", "/")
for _, obj in ipairs(result.objects) do
    print("File:", obj.key, obj.size)
end
for _, prefix in ipairs(result.prefixes) do
    print("Dir:", prefix)
end
```

### `bucket:copy(src_key, dest_key)`

Copy an object within the same bucket.

| Parameter | Type | Description |
|-----------|------|-------------|
| `src_key` | string | Source object key |
| `dest_key` | string | Destination object key |

**Returns:** nothing

**Raises:** error on failure

```lua
bucket:copy("data/current.json", "backups/data-2025-01.json")
```

## Object Tagging

### `bucket:put_tags(key, tags)`

Set tags on an object. Replaces any existing tags.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `tags` | table | Key-value pairs of tags |

**Returns:** nothing

**Raises:** error if object not found

```lua
bucket:put_tags("report.pdf", {
    department = "finance",
    year = "2025",
    status = "final",
})
```

### `bucket:get_tags(key)`

Get all tags from an object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |

**Returns:** table (key-value pairs of tags)

**Raises:** error if object not found

```lua
local tags = bucket:get_tags("report.pdf")
print(tags.department)  -- "finance"
print(tags.year)        -- "2025"
```

### `bucket:delete_tags(key)`

Delete all tags from an object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |

**Returns:** nothing

**Raises:** error if object not found

```lua
bucket:delete_tags("report.pdf")
```

## Multipart Upload

### `bucket:multipart_start(key, content_type?)`

Start a multipart upload session. Returns an upload ID used for subsequent part uploads.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key for the final assembled object |
| `content_type` | string | MIME type (default: `"application/octet-stream"`) |

**Returns:** string (upload ID)

**Raises:** error on failure

```lua
local upload_id = bucket:multipart_start("large-file.dat")
local upload_id = bucket:multipart_start("backup.tar.gz", "application/gzip")
```

### `bucket:multipart_upload(key, upload_id, part_number, data)`

Upload a single part/chunk. Parts must be at least 5 MB (except the last part).

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key (same as `multipart_start`) |
| `upload_id` | string | Upload ID from `multipart_start` |
| `part_number` | number | Part number (1-based, sequential) |
| `data` | string | Part data |

**Returns:** table with part info

| Field | Type | Description |
|-------|------|-------------|
| `etag` | string | Part's ETag (needed for completion) |
| `part_number` | number | The part number |

**Raises:** error on upload failure

```lua
local part = bucket:multipart_upload("file.dat", upload_id, 1, chunk_data)
-- part.etag = "\"abc123...\""
-- part.part_number = 1
```

### `bucket:multipart_complete(key, upload_id, parts)`

Finalize a multipart upload. Assembles all uploaded parts into the final object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `upload_id` | string | Upload ID from `multipart_start` |
| `parts` | table | Array of part info tables from `multipart_upload` |

**Returns:** nothing

**Raises:** error on failure

```lua
bucket:multipart_complete("file.dat", upload_id, parts)
```

### `bucket:multipart_abort(key, upload_id)`

Cancel an ongoing multipart upload and discard all uploaded parts.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `upload_id` | string | Upload ID from `multipart_start` |

**Returns:** nothing

**Raises:** error on failure

```lua
bucket:multipart_abort("file.dat", upload_id)
```

### Multipart Upload Example

```lua
local CHUNK_SIZE = 10 * 1024 * 1024  -- 10 MB

local upload_id = bucket:multipart_start("large-file.bin")
local parts = {}
local part_number = 1

-- Upload in chunks
for i = 0, file_size - 1, CHUNK_SIZE do
    local chunk = get_chunk(i, CHUNK_SIZE)
    local part = bucket:multipart_upload(
        "large-file.bin", upload_id, part_number, chunk
    )
    table.insert(parts, part)
    part_number = part_number + 1
end

-- Finalize
bucket:multipart_complete("large-file.bin", upload_id, parts)
```

## Presigned URLs

### `bucket:presign_get(key, expiry?)`

Generate a presigned URL for downloading an object. The URL can be shared with anyone -- no credentials needed.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `expiry` | number | URL expiration in seconds (default: `3600`) |

**Returns:** string (presigned URL)

```lua
local url = bucket:presign_get("reports/q4.pdf")
print(url)  -- https://bucket.s3.amazonaws.com/reports/q4.pdf?X-Amz-...

-- Short-lived URL (5 minutes)
local url = bucket:presign_get("secret.dat", 300)
```

### `bucket:presign_put(key, expiry?)`

Generate a presigned URL for uploading an object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `expiry` | number | URL expiration in seconds (default: `3600`) |

**Returns:** string (presigned URL)

```lua
local url = bucket:presign_put("uploads/user-file.dat")
-- Share this URL — the holder can PUT directly to S3
```

### `bucket:presign_delete(key, expiry?)`

Generate a presigned URL for deleting an object.

| Parameter | Type | Description |
|-----------|------|-------------|
| `key` | string | Object key |
| `expiry` | number | URL expiration in seconds (default: `3600`) |

**Returns:** string (presigned URL)

```lua
local url = bucket:presign_delete("temp/expired.dat", 600)
-- Share this URL — the holder can DELETE the object
```

## Bucket Management

### `bucket:create_bucket()`

Create the bucket on the server. Uses the name and region from the bucket configuration.

**Returns:** nothing

**Raises:** error if bucket already exists or permission denied

```lua
local bucket = s3.bucket({
    name = "new-bucket",
    region = "us-east-1",
    access_key = "...",
    secret_key = "...",
})
bucket:create_bucket()
```

### `bucket:delete_bucket()`

Delete the bucket from the server. The bucket must be empty.

**Returns:** nothing

**Raises:** error if bucket is not empty or permission denied

```lua
bucket:delete_bucket()
```

### `bucket:bucket_exists()`

Check if the bucket exists on the server.

**Returns:** boolean

```lua
if bucket:bucket_exists() then
    print("Bucket is ready")
end
```

### `bucket:location()`

Get the bucket's region/location as reported by the server.

**Returns:** string (region name)

**Raises:** error on failure

```lua
local region = bucket:location()
print(region)  -- "us-east-1"
```

### `bucket:name()`

Get the name of the bucket.

**Returns:** string

```lua
print(bucket:name())  -- "my-bucket"
```

### `bucket:url()`

Get the full URL of the bucket.

**Returns:** string

```lua
print(bucket:url())  -- "https://my-bucket.s3.amazonaws.com"
```
