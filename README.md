> [!NOTE]
> You need access to the Jai compiler in order to use this program.

# Blog Builder

This is a simple ~400 line program that assembles different html snippets together to build a blog.

## Folder structure:
The program expects an `in` folder and will create an `out` folder where the final blog will be placed. 
In general, every file and folder in `in` will be copied to the `out` folder. However, there are some special folders and files inside `in` that the program will look for.

### Root Folder
In the root folder you can create files that you want to be at the root of your website, like a homepage for example. These files will be processed with the templates described below.

### Template Folder
In the `templates` folder you will find a `head.html`, `header.html` and `footer.html` file.
When running the program all files in the `root` folder will be copied into the `out` folder and head, header and footer will be applied to all of them.

### Variable file
In `vars.txt` you can define variables like this (one variable on every new line):
```
VARIAVLE_NAME=value
```

Now anytime you put `%VARIABLE_NAME%` in any html file it will be replaced with the value defined.

### Lists Folder
To make a new list, make a new folder in the `list` folder and create a `list.html` file.
At the beginning of the `list.html` file you must define two variables: `LIST_VAR` and `LIST_TITLE`:
```
LIST_VAR=MARVEL_MOVIE
LIST_TITLE=My top 5 Marvel Movies
```

With `LIST_VAR` the whole list will be copy-pasted when calling `%MARVEL_MOVIES%`.
You must give a `LIST_TITLE` variable definition.

The actual content of the file is separated by `+++` and acts as a template for each list item.
With `%ITEM_CONTENT%` you can say where the content of each item will be placed.

Every html file that sits in the list folder will be included as an item in the final list. 
On the top of every item file you must define:
```
ITEM_TITLE=The Avengers
ITEM_DATE=01/01/2000
```

The `ITEM_TITLE` will be the item title.
The `ITEM_DATE` is optional and when present, items with a more recent date will appear first in the list.

You can also define additional variables that can be called from `list.html`.

Besides the `list.html` file you can create a `links.html` file. This template file will be used to compile a list of links for every item in a list.
You will have to define a `LINKS_VAR` variable that works like the `LIST_VAR` variable. To get the link of an item use `%ITEM_LINK%`.

## Examples
The `in` folder already contains an example blog with a list of the top 5 Marvel movies. 
If you don't like Marvel movies check out [neinkob.net](https://neinkob.net).

## How to run Blog Builder
You need access to the Jai beta in order to use this program since it has to be compiled first.

Run `jai blog_builder.jai` and then run `./blog_builder`.