# Components

Components are reusable template pieces that accept data and render content. They help you avoid duplicating markup across templates.

## Defining a Component

A component is a `.vein` file that receives props and can accept slot content:

```html
{# views/components/card.vein #}
<div class="card">
    <div class="card-header">
        <h3>{{ title }}</h3>
    </div>
    <div class="card-body">
        {! slot !}
    </div>
</div>
```

The `{{ slot }}` or `{! slot !}` tag is where child content gets inserted.

## Using Components

Use the `{% component %}` tag to render a component, passing props as a table:

```html
{% component "card" { title = "Latest News" } %}
    <p>Here is some card content.</p>
    <a href="/news">Read more</a>
{% endcomponent %}
```

This renders:

```html
<div class="card">
    <div class="card-header">
        <h3>Latest News</h3>
    </div>
    <div class="card-body">
        <p>Here is some card content.</p>
        <a href="/news">Read more</a>
    </div>
</div>
```

## Components Without Slots

Components don't need to accept slot content. They can be self-contained:

```html
{# views/components/avatar.vein #}
<img src="{{ url }}" alt="{{ name }}" class="avatar avatar-{{ size | default("md") }}">
```

```html
{% component "avatar" { url = user.avatar_url, name = user.name, size = "lg" } %}
{% endcomponent %}
```

## Registering Components in Code

You can register components programmatically on the engine:

```lua
local engine = vein.new({
    views = "./views",
    components = "./views/components",
})

-- Register from a string
engine:component("badge", [[
    <span class="badge badge-{{ color | default("blue") }}">{{ text }}</span>
]])

-- Register from a file path
engine:component("alert", "components/alert.vein")
```

## Component Directory

Set a components directory so Vein can find component files automatically:

```lua
local engine = vein.new({
    components = "./views/components",
})
```

With this configuration, `{% component "card" %}` looks for `./views/components/card.vein`.

## Includes

For simple cases where you just need to insert another template without props, use the include tag:

```html
{@ include "partials/header" @}

<main>
    <p>Page content</p>
</main>

{@ include "partials/footer" @}
```

Includes share the parent template's context. All variables available in the parent are also available in the included template.

## Partials

Partials are similar to includes but let you pass a specific data context:

```html
{> partial "user-card" { user = currentUser } >}

{% for post in posts do %}
    {> partial "post-summary" { post = post, showAuthor = true } >}
{% end %}
```

The partial only receives the data you explicitly pass to it.

## Include vs Partial vs Component

| Feature | Include | Partial | Component |
|---------|---------|---------|-----------|
| Syntax | `{@ include "name" @}` | `{> partial "name" { data } >}` | `{% component "name" { props } %}` |
| Context | Inherits parent context | Receives explicit data | Receives explicit props |
| Slot content | No | No | Yes |
| Use case | Static shared sections | Data-driven fragments | Reusable UI elements |

**Use includes** for headers, footers, and navigation that share the page context.

**Use partials** when you want to render a template fragment with specific data.

**Use components** when you need reusable UI pieces that accept both props and child content.

## Practical Examples

### Alert Component

```html
{# views/components/alert.vein #}
<div class="alert alert-{{ type | default("info") }}" role="alert">
    {% if dismissible then %}
        <button class="close">&times;</button>
    {% end %}
    {! slot !}
</div>
```

```html
{% component "alert" { type = "warning", dismissible = true } %}
    <strong>Warning!</strong> Your session expires in 5 minutes.
{% endcomponent %}
```

### Navigation with Includes

```html
{# views/partials/nav.vein #}
<nav>
    <a href="/" class="{% if active == 'home' then %}active{% end %}">Home</a>
    <a href="/blog" class="{% if active == 'blog' then %}active{% end %}">Blog</a>
    <a href="/about" class="{% if active == 'about' then %}active{% end %}">About</a>
</nav>
```

```html
{# views/pages/home.vein #}
{% extends "layouts/base" %}

{% block content %}
    {@ include "partials/nav" @}
    <h1>Welcome</h1>
{% endblock %}
```

### Post Card Partial

```html
{# views/partials/post-card.vein #}
<article class="post-card">
    {% if post.cover_image then %}
        <img src="{{ post.cover_image }}" alt="{{ post.title }}">
    {% end %}
    <h3><a href="/post/{{ post.slug }}">{{ post.title }}</a></h3>
    <p>{{ post.excerpt | truncate(120) }}</p>
    <div>
        <span>{{ post.author.display_name }}</span>
        <span>{{ post.published_at | timeago }}</span>
    </div>
</article>
```

```html
{% for post in posts do %}
    {> partial "partials/post-card" { post = post } >}
{% end %}
```
