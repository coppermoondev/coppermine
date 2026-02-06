# Layouts

Vein supports template inheritance, allowing you to define a base layout and override specific sections in child templates. This keeps your HTML structure DRY and consistent.

## How It Works

1. A **layout** template defines the page skeleton and declares named **blocks**
2. A **child** template **extends** the layout and overrides specific blocks
3. Blocks not overridden in the child keep their default content from the layout

## Defining a Layout

A layout is a regular `.vein` file that uses `{% block %}` to define replaceable sections:

```html
{# views/layouts/base.vein #}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}My Site{% endblock %}</title>
    {% block head %}
        <link rel="stylesheet" href="/public/css/style.css">
    {% endblock %}
</head>
<body>
    <header>
        {% block header %}
            <nav>
                <a href="/">Home</a>
                <a href="/about">About</a>
            </nav>
        {% endblock %}
    </header>

    <main>
        {% block content %}
            {# Default content - overridden by child templates #}
        {% endblock %}
    </main>

    <footer>
        {% block footer %}
            <p>&copy; 2025 My Site</p>
        {% endblock %}
    </footer>

    {% block scripts %}
        <script src="/public/js/app.js"></script>
    {% endblock %}
</body>
</html>
```

This layout defines five blocks: `title`, `head`, `header`, `content`, `footer`, and `scripts`. Each has default content that child templates can replace.

## Extending a Layout

Use `{% extends %}` at the top of a child template, then override blocks as needed:

```html
{# views/pages/home.vein #}
{% extends "layouts/base" %}

{% block title %}Home - My Site{% endblock %}

{% block content %}
    <h1>Welcome</h1>
    <p>This is the home page.</p>

    {% if featured then %}
        <section>
            <h2>Featured</h2>
            {% for item in featured do %}
                <div>{{ item.title }}</div>
            {% end %}
        </section>
    {% end %}
{% endblock %}
```

Only the `title` and `content` blocks are overridden. The `header`, `footer`, `head`, and `scripts` blocks keep their defaults from the layout.

## Multiple Layouts

You can have different layouts for different sections of your site:

```html
{# views/layouts/admin.vein #}
<!DOCTYPE html>
<html>
<head>
    <title>Admin - {% block title %}Dashboard{% endblock %}</title>
</head>
<body>
    <div class="sidebar">
        {% block sidebar %}
            <a href="/admin">Dashboard</a>
            <a href="/admin/users">Users</a>
            <a href="/admin/posts">Posts</a>
        {% endblock %}
    </div>

    <div class="main">
        {% block content %}{% endblock %}
    </div>
</body>
</html>
```

```html
{# views/pages/admin/users.vein #}
{% extends "layouts/admin" %}

{% block title %}Users{% endblock %}

{% block content %}
    <h1>User Management</h1>
    <table>
        {% for user in users do %}
            <tr>
                <td>{{ user.name }}</td>
                <td>{{ user.email }}</td>
            </tr>
        {% end %}
    </table>
{% endblock %}
```

## Slots

Slots provide an alternative block syntax using `{! !}` delimiters. They are equivalent to blocks but use a different notation:

### In the layout:

```html
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
</head>
<body>
    <main>
        {! content !}
    </main>
</body>
</html>
```

### In the child:

```html
{% extends "layouts/base" %}

{! content !}
    <h1>{{ title }}</h1>
    <p>Page content here.</p>
{! end !}
```

## Practical Example

Here is how CopperBlog uses layouts:

### Base layout

```html
{# views/layouts/base.vein #}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>{{ title }} - {{ site.name }}</title>
</head>
<body class="bg-gray-900 text-white">
    <nav>
        <a href="/">{{ site.name }}</a>
        <a href="/blog">Blog</a>
        <a href="/about">About</a>
    </nav>

    <main>
        {! content !}
    </main>

    <footer>
        <p>&copy; {{ site.name }}</p>
    </footer>
</body>
</html>
```

### Blog listing page

```html
{# views/pages/blog.vein #}
{% extends "layouts/base" %}

{! content !}
    <h1>Blog</h1>

    {% for post in posts do %}
        <article>
            <h2><a href="/post/{{ post.slug }}">{{ post.title }}</a></h2>
            <p>{{ post.excerpt | truncate(200) }}</p>
            <span>{{ post.published_at | timeago }}</span>

            {% if post.tags then %}
                {% for tag in post.tags do %}
                    <a href="/tag/{{ tag.slug }}">{{ tag.name }}</a>
                {% end %}
            {% end %}
        </article>
    {% end %}
{! end !}
```

### Single post page

```html
{# views/pages/post.vein #}
{% extends "layouts/base" %}

{! content !}
    <article>
        <h1>{{ post.title }}</h1>
        <p>By {{ post.author.display_name }} &middot; {{ post.published_at | date }}</p>

        <div>
            {! post.content !}
        </div>
    </article>

    {% if comments then %}
        <section>
            <h2>Comments ({{ comments | length }})</h2>
            {% for comment in comments do %}
                <div>
                    <strong>{{ comment.author_name }}</strong>
                    <span>{{ comment.created_at | timeago }}</span>
                    <p>{{ comment.content }}</p>
                </div>
            {% end %}
        </section>
    {% end %}
{! end !}
```

## Tips

- Keep layouts focused on structure. Avoid putting business logic in them.
- Use global template variables (`engine:global()`) for data shared across all pages (site name, navigation, etc.).
- Name your blocks descriptively: `content`, `sidebar`, `scripts`, `meta` are common choices.
- You can have as many blocks as needed. Unused blocks simply keep their defaults.
