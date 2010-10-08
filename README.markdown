### CoffeeApp -- coffee-script wrapper for CouchApp

### Installing

Prerequisites: CoffeeScript requires Node.js (<http://nodejs.org/>), Npm (http://npmjs.org/)

Get CoffeeApp:

    git clone git://github.com/andrzejsliwa/coffeeapp.git

Build Jake:

    cd coffeeapp && make && sudo make install

### Installing with [npm](http://npmjs.org/)

    npm install coffeeapp

Or, get the code, and `npm link` in the code root.

### Basic usage

    coffeeapp [couchapp options] | [wrapped options]

### Example usage


without compilation errors:

    $ coffeeapp push

    CoffeeApp (v0.0.5) - simple coffee-script wrapper for CouchApp (http://couchapp.org)
    http://github.com/andrzejsliwa/coffeeapp

    Wrapping 'push' of couchapp
    preparing .releases/20101008202459 release...
     * processing filters/filter.coffee...

    done.
    2010-10-08 20:25:04 [INFO] Visit your CouchApp here:
    http://127.0.0.1:5984/tutorial/_design/hello/index.html

with errors, all generated files have in content '...' which should be replaced by real code - this helps to keep clean project ;) :

    $ coffeeapp push

    CoffeeApp (v0.0.5) - simple coffee-script wrapper for CouchApp (http://couchapp.org)
    http://github.com/andrzejsliwa/coffeeapp

    Wrapping 'push' of couchapp
    preparing .releases/20101008202459 release...
     * processing filters/filter.coffee...

     * processing views/coffewview/reduce.coffee...
    Compilation Error: Parse error on line 1: Unexpected '.'


using coffee generators

    $ coffeeapp cgenerate view myview

    CoffeeApp (v0.0.5) - simple coffee-script wrapper for CouchApp (http://couchapp.org)
    http://github.com/andrzejsliwa/coffeeapp

    Running CoffeeApp 'view' generator...
     * creating myview/map.coffee...
     * creating myview/reduce.coffee...
    done.

using help command:

    $ coffeeapp help

    ...
    CouchApp Help here ...
    ...

    Wrapping 'help' of couchapp

    CoffeeApp (v0.0.5) - simple coffee-script wrapper for CouchApp (http://couchapp.org)
    http://github.com/andrzejsliwa/coffeeapp

    help             show this message
    cgenerate        [ view | list | show | filter ] generate coffee-script versions of files (instead of standard 'generate')


### Description

CoffeeApp is a simple wrapper for couchapp command. CoffeeApp override normal push behavoir, by adding '.releases' directory
which contain deployment snapshots (timestamped). While files are copied to release snapshot... coffee-script files (.coffee)
are converted on the fly to java-script (.js) files.

'.releases' directory should be added to .gitignore or .hgignore or whatever you have using to prevent versioning.



### Author

Andrzej Sliwa, andrzej.sliwa@i-tool.eu
