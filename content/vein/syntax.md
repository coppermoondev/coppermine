# Vein Syntax

Vein uses a clean, Lua-inspired syntax for templating. This guide covers all the template tags and their usage.

## Output Tags

### Escaped Output `{{ }}`

Outputs the expression value with HTML escaping (safe from XSS):

```html
<p>Hello, {{ username }}!</p>
<p>Your score: {{ user.score | number }}</p>
```

### Raw Output `{! !}`

Outputs without escaping (use only for trusted content):

```html
{! htmlContent !}
{! markdown | markdown !}
```

## Code Tags `{% %}`

Execute Lua code:

```html
{% local items = {"apple", "banana", "cherry"} %}

{% for i, item in ipairs(items) do %}
  <li>{{ i }}. {{ item }}</li>
{% end %}
```

### Control Structures

**If/Else:**
```html
{% if user.isAdmin then %}
  <span class="badge">Admin</span>
{% elseif user.isMod then %}
  <span class="badge">Moderator</span>
{% else %}
  <span class="badge">User</span>
{% end %}
```

**For Loops:**
```html
{% for item in items do %}
  <div>{{ item.name }}</div>
{% end %}

{% for i = 1, 10 do %}
  <span>{{ i }}</span>
{% end %}
```

**While Loops:**
```html
{% local i = 1 %}
{% while i <= 5 do %}
  <p>Line {{ i }}</p>
  {% i = i + 1 %}
{% end %}
```

## Comments `{# #}`

Comments are not rendered:

```html
{# This is a comment #}
{#
   Multi-line
   comment
#}
```

## Include `{@ @}`

Include another template:

```html
{@ include "partials/header" @}
{@ include "components/card" @}
```

## Partial `{> >}`

Render a partial with data:

```html
{> partial "user-card" { user = currentUser } >}
{> "sidebar" { active = "home" } >}
```

## Filters

Filters transform output using the pipe `|` syntax:

```html
{{ name | upper }}
{{ text | truncate(100) }}
{{ price | currency("$") }}
{{ items | join(", ") }}

{# Chain multiple filters #}
{{ description | striptags | truncate(200) | escape }}
```

### Built-in Filters

**String Filters:**
- `upper` - Uppercase
- `lower` - Lowercase
- `capitalize` - Capitalize first letter
- `title` - Title Case Each Word
- `trim` - Remove whitespace
- `truncate(n)` - Truncate to n characters
- `striptags` - Remove HTML tags
- `nl2br` - Convert newlines to `<br>`
- `slug` - URL-friendly slug

**Number Filters:**
- `number(decimals)` - Format number
- `currency(symbol)` - Format as currency
- `percent(decimals)` - Format as percentage
- `bytes` - Format file size

**Array Filters:**
- `first` - First element
- `last` - Last element
- `join(sep)` - Join with separator
- `length` - Array length
- `sort` - Sort array
- `reverse` - Reverse array

**Date Filters:**
- `date(format)` - Format date
- `datetime` - Format as datetime
- `timeago` - Relative time

**Utility Filters:**
- `default(value)` - Default if nil
- `json` - JSON encode
- `escape` / `e` - HTML escape
- `url` - URL encode

## Layouts and Blocks

### Extending Layouts

```html
{% extends "layouts/base" %}

{% block content %}
  <h1>My Page</h1>
  <p>Page content here...</p>
{% endblock %}
```

### Layout Template

```html
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}My Site{% endblock %}</title>
</head>
<body>
  {% block content %}{% endblock %}
</body>
</html>
```

## Components

### Using Components

```html
{% component "card" { title = "Hello", class = "primary" } %}
  <p>Card content goes here</p>
{% endcomponent %}
```

### Component Template

```html
{# components/card.vein #}
<div class="card {{ class }}">
  <h3>{{ title }}</h3>
  <div class="card-body">
    {! slot !}
  </div>
</div>
```

## Slots

Define default content that can be overridden:

```html
{% slot header %}
  <h1>Default Header</h1>
{% endslot %}

{% slot footer %}
  <p>Default Footer</p>
{% endslot %}
```
