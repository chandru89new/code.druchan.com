---
title: Code test
date: 2023-05-18
slug: code
ignore: true
---

```js
const md2FormattedData = (string) => {
  const r = matter(string);
  return {
    frontMatter: {
      ...r.data,
      tags: r.data.tags?.split(",") ?? [],
      ignore: r.data.ignore ? true : false,
    },
    content: md2FormattedDataService.render(r.content),
    raw: string,
  };
};
```

Haskell/Purescript:

```haskell
createFolderIfNotPresent :: String -> ExceptT Error Aff Unit
createFolderIfNotPresent folderName =
  ExceptT
    $ do
        res <- try $ readdir folderName
        case res of
          Right _ -> pure $ Right unit
          Left _ -> try $ mkdir folderName
```
