# code.druchan.com

Repo to store blog posts and the script that generates the static site/blog.

## Contents

- Requirements
- Setup
- Workflow
  - Writing posts
  - Building the site
  - Cache
  - Testing locally
  - Uploading/deploying to server
- Editing/updating generator script
  - Main.purs
  - Watching for changes
  - Templates and Styling

## Requirements

- Node (any latest >= 18)
- Yarn (typically enabled by npm, but you could also do `corepack enable`)
- Firebase (for testing locally + deploying to server because this project uses
  Google Firebase for hosting)

(Firebase is optional. You can still build the project and serve it anyway you
like.)

## Setup

```bash
~ yarn install
```

This will install everything required.

## Workflow

### Writing posts

- Write posts in `contents/` directory.
- Filename is `<slug>.md` where `<slug>` is the URL-friendly version of the
  title.
- The first few lines of the file are the metadata. The format is:

```markdown
---
title: "Title of the post in quotes"
date: YYYY-MM-DD
slug: a-url-friendly-slug
ignore: true # optional. if true, the post will not be included in the final build
---

blog post content here
```

### Building the site

```bash
~ yarn build
```

or

```bash
~ yarn clean-build # to do a fresh install. deletes the `cache` file and the `public` directory and recreates everything.
```

This will build the site and output in `./public` directory.

### Cache

To support faster builds, the script caches the `stat` results of all markdown
files in the `./contents` folder. Everytime you run `yarn build` or in
`yarn watch` mode, the script will check if a file has been touched/modified and
only those files's post pages will get re-built.

If you want to force a cache-invalidation, just remove the cache file:

```bash
~ rm cache
```

A clean-build (`yarn clean-build`) will also remove the cache before building
the pages.

### Testing locally

```bash
~ firebase serve
```

Alternatively, you could use any other method too. Eg, using `http-server`:

```bash
~ npx http-server public
```

Note: you would have to configure the server to serve the `html` file for a
given route as the routes do not include the extension. Eg:
`http://localhost:5000/books` should render `http://localhost:5000/books.html`.
`firebase serve` does this automatically for you.

### Uploading/deploying to server

```bash
~ firebase login # if not already logged in
~ firebase deploy
```

## Editing/updating generator script

### Main.purs

The whole building logic is in `src/Main.purs`.

### Watching for changes

```bash
~ yarn watch
```

The watch options are in "nodemonConfig" in the `packages.json` file. By the
config, the script will watch for changes in `src/`, `contents/` and
`templates/` directories.

### Templates and Styling

The templates, in the `templates/` directory, are for the home page
(`index.html`) and the blog post page (`post.html`). A `404.html` page is for
the page-not-found. It's not a template.

All styles are in the `templates/style.css` file.
