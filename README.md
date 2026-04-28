# BlogBuilder

This is a simple ~400 line program that puts different html snippets together to build a blog.

## Folder structure:
The program expects an `in` folder and will create an `out` folder where the final blog will be placed. 
In general every folder in `in` will be copied to the `out` folder. However, there are some special folders and files inside `in` that the program will look for:

### Root Folder
In the root folder you can create any files that you want to be at the root of your website, like a homepage for example. Together
with the template folder it forms the core of your blog.

### Template Folder
In the `templates` folder you will find a `head.html`, `header.html` and `footer.html` file.
When running the program any file in the `root` folder will be put in the `out` folder and head, header and footer will be applied to any of them.

### Variable file
In `vars.txt` file you can define variables like this (one variable on every new line):
```
VARIAVLE_NAME=value

```

Any time you put `%VARIABLE_NAME%` now in any html file it will be replaced with the value defined.

### Lists Folder
In the `list` folder you can define ...lists. To make a new list, make a new folder there and create a `list.html` file.
At the beginning of the list file you have to define two variables: `LIST_VAR` and `LIST_TITLE`:
```
LIST_VAR=MARVEL_MOVIES
LIST_TITLE=My top 5 Marvel Movies
```

With `LIST_VAR` the whole list will be copy-pasted into a html file when writing `%MARVEL_MOVIES%`.
`LIST_TITLE` will define the heading of the list.

The content actual content of the file is separated by `+++` and acts as a template for each list item.
With `%ITEM_CONTENT%` you can say where the content of each item will be placed.

Every html file that sits in the list folder will be included as a item in the final list. 
On the top of every item file you have to define:
```
ITEM_TITLE=The Avengers
ITEM_DATE=01/01/2000
```

The `ITEM_TITLE` will be the item title.
The `ITEM_DATE` is optional and when present items with an more recent date will appear first in the list.

You can also define additional variables that can be called from `list.html`.

In addition to the `list.html` file you can also create a `links.html` file. This template file will be used to compile a list of links for every item in a list.
You will have to define a `LINKS_VAR` variable that works like the `LIST_VAR` variable.

## How to run BlogBulder
You need to have access to the jai beta in order to use this program since it has to be compiled first. 
Run `jai blog_builder.jai` and then run `./blog_builder`.# blog_builder
